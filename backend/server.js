require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { GoogleGenAI } = require('@google/genai');
const axios = require('axios');

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
const HADITH_API_KEY = process.env.HADITH_API_KEY;

// Pseudo-MCP Tool: Fetch Tafsir
async function getTafsir(verseKey) {
  try {
    // 169 is Tafsir Ibn Kathir (English). We will ask Gemini to explain in Indonesian.
    const response = await axios.get(`https://api.quran.com/api/v4/tafsirs/169/by_ayah/${verseKey}`);
    return response.data.tafsir.text;
  } catch (error) {
    console.error('Error fetching tafsir:', error);
    return null;
  }
}

// Pseudo-MCP Tool: Fetch Verse details
async function getVerseDetails(verseKey) {
  try {
    const response = await axios.get(`https://api.quran.com/api/v4/verses/by_key/${verseKey}?language=id&words=false&translations=33&fields=text_uthmani`);
    return response.data.verse;
  } catch (error) {
    console.error('Error fetching verse details:', error);
    return null;
  }
}

// Pseudo-MCP Tool: Search Hadith (using HadithAPI.com MVP approach)
// Since this is just an MVP, we'll do a simple search or return a mock if it's too complex.
// Actually, HadithAPI requires specific endpoints. Let's skip direct API call here if not strictly asked in explain,
// or just provide a dummy tool implementation for now.

app.post('/api/ai/explain', async (req, res) => {
  const { verseKey } = req.body; // e.g. "1:1"
  if (!verseKey) return res.status(400).json({ error: 'verseKey is required' });

  try {
    const verse = await getVerseDetails(verseKey);
    const tafsir = await getTafsir(verseKey);
    
    if (!verse || !tafsir) {
      return res.status(500).json({ error: 'Failed to fetch Quran context data.' });
    }

    const verseText = verse.text_uthmani;
    const translation = verse.translations[0].text;

    const prompt = `
Anda adalah asisten AI yang ahli dalam studi Al-Qur'an.
Tugas Anda adalah menjelaskan ayat berikut dalam bahasa Indonesia yang mudah dipahami, NAMUN harus sangat berpegang pada teks Tafsir Ibnu Katsir yang diberikan.

Ayat: ${verseKey}
Teks Arab: ${verseText}
Terjemahan: ${translation}

Tafsir Ibnu Katsir (Referensi Utama):
${tafsir}

Berikan penjelasan terstruktur yang merangkum poin-poin penting dari tafsir tersebut. Pastikan Anda mencantumkan bahwa sumber penjelasan ini adalah Tafsir Ibnu Katsir. Jangan menambahkan opini pribadi yang bertentangan dengan tafsir.
`;

    const response = await ai.models.generateContent({
        model: 'gemini-3.5-flash-lite',
        contents: prompt,
    });

    res.json({ 
      explanation: response.text,
      source: "Tafsir Ibnu Katsir (via mcp.quran.ai pseudo-client)",
      verseKey
    });

  } catch (error) {
    console.error('AI Error:', error);
    res.status(500).json({ error: 'Failed to generate AI explanation' });
  }
});

app.post('/api/ai/chat', async (req, res) => {
  const { verseKey, question, history } = req.body;
  // history is array of { role: 'user' | 'model', text: string }

  try {
    const tafsir = await getTafsir(verseKey);
    const systemInstruction = `Anda adalah asisten AI studi Al-Qur'an. Anda sedang mendiskusikan ayat ${verseKey}. 
    Konteks tafsir Ibnu Katsir untuk ayat ini: ${tafsir}
    Jawab pertanyaan pengguna dalam bahasa Indonesia berdasarkan tafsir tersebut. Selalu rujuk ke sumber.`;

    let contents = [
      { role: 'user', parts: [{ text: systemInstruction }] },
      { role: 'model', parts: [{ text: 'Baik, saya mengerti. Saya akan menjawab berdasarkan Tafsir Ibnu Katsir.' }] }
    ];

    if (history && history.length > 0) {
      history.forEach(msg => {
        contents.push({
          role: msg.role === 'ai' ? 'model' : 'user',
          parts: [{ text: msg.text }]
        });
      });
    }

    contents.push({ role: 'user', parts: [{ text: question }] });

    const response = await ai.models.generateContent({
        model: 'gemini-3.5-flash-lite',
        contents: contents,
    });

    res.json({
      answer: response.text
    });

  } catch (error) {
    console.error('Chat Error:', error);
    res.status(500).json({ error: 'Failed to chat with AI' });
  }
});

app.post('/api/ai/global-chat', async (req, res) => {
  const { question, history } = req.body;
  // history is array of { role: 'user' | 'model', text: string }

  try {
    const systemInstruction = `Anda adalah asisten AI yang ahli dalam studi Al-Qur'an dan ilmu agama Islam. Anda bertugas menjawab pertanyaan umum pengguna dengan hikmah, ramah, dan berlandaskan sumber-sumber yang sahih (Al-Qur'an, Hadits, atau pandangan ulama terkemuka). Jika ada pertanyaan di luar topik keagamaan/Al-Qur'an, tolak dengan sopan.`;

    let contents = [
      { role: 'user', parts: [{ text: systemInstruction }] },
      { role: 'model', parts: [{ text: 'Baik, saya mengerti. Saya siap membantu menjawab pertanyaan Anda terkait Al-Qur\'an dan Islam.' }] }
    ];

    if (history && history.length > 0) {
      history.forEach(msg => {
        contents.push({
          role: msg.role === 'ai' ? 'model' : 'user',
          parts: [{ text: msg.text }]
        });
      });
    }

    contents.push({ role: 'user', parts: [{ text: question }] });

    const response = await ai.models.generateContent({
        model: 'gemini-3.5-flash-lite',
        contents: contents,
    });

    res.json({
      answer: response.text
    });

  } catch (error) {
    console.error('Global Chat Error:', error);
    res.status(500).json({ error: 'Failed to chat with AI globally' });
  }
});

// Voice Search endpoint: Identifies Quran verse from audio or recited voice text
app.post('/api/ai/voice-search', async (req, res) => {
  const { queryText, audioBase64, mimeType } = req.body;

  if (!queryText && !audioBase64) {
    return res.status(400).json({ error: 'queryText or audioBase64 is required' });
  }

  try {
    let contents = [];

    if (audioBase64) {
      let finalMime = mimeType || 'audio/webm';
      if (finalMime.includes('m4a') || finalMime.includes('mp4')) {
        finalMime = 'audio/mp4';
      } else if (finalMime.includes('wav')) {
        finalMime = 'audio/wav';
      } else if (finalMime.includes('mpeg') || finalMime.includes('mp3')) {
        finalMime = 'audio/mp3';
      } else if (finalMime.includes('3gp') || finalMime.includes('3gpp')) {
        finalMime = 'audio/3gpp';
      } else if (finalMime.includes('aac')) {
        finalMime = 'audio/aac';
      }

      contents = [
        {
          role: 'user',
          parts: [
            {
              text: `Anda adalah asisten AI ahli Al-Qur'an dan Qira'at (VerseMatcher Multi-layer).
Dengarkan rekaman audio pelafalan/bacaan potongan ayat Al-Qur'an berikut.
Tentukan dan temukan SEMUA ayat Al-Qur'an yang cocok dengan lafal/bacaan tersebut. Jika lafal tersebut berulang di beberapa ayat/surah (misal "Alif Lam Mim", "Ha Mim", atau frasa berulang lainnya), sebutkan SEMUA ayat yang cocok.
Kembalikan respons HANYA dalam format JSON valid (tanpa blok kode markdown \`\`\`json):
{
  "found": true,
  "totalMatches": 1,
  "matches": [
    {
      "surahNumber": 1,
      "surahName": "Al-Fatihah",
      "verseNumber": 2,
      "verseKey": "1:2",
      "arabicText": "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
      "translation": "Segala puji bagi Allah, Tuhan seluruh alam.",
      "confidence": "Tinggi",
      "explanation": "Potongan ayat yang dibacakan adalah Surah Al-Fatihah ayat ke-2."
    }
  ]
}
Jika bukan ayat Al-Qur'an atau tidak jelas, kembalikan:
{
  "found": false,
  "message": "Potongan ayat belum dapat dikenali dengan jelas. Silakan lafalkan kembali."
}`
            },
            {
              inlineData: {
                mimeType: finalMime,
                data: audioBase64
              }
            }
          ]
        }
      ];
    } else {
      contents = [
        {
          role: 'user',
          parts: [
            {
              text: `Anda adalah asisten AI ahli Al-Qur'an (VerseMatcher Multi-layer Matching).
Pengguna melafalkan/mencari potongan ayat Al-Qur'an berikut: "${queryText}".
Tugas Anda adalah mencari dan menemukan SEMUA ayat Al-Qur'an yang cocok atau memuat potongan lafal/teks tersebut (bisa berupa teks Arab, latin fonetik misal "Alif Lam Mim", atau terjemahan).
PENTING: Jika potongan ayat tersebut muncul di beberapa surah/ayat (misal "Alif Lam Mim", "Ha Mim", "Alif Lam Ra", "Fabiayyi ala-i rabbikuma tukadzdziban", dll.), cantumkan SEMUA ayat yang ada di Al-Qur'an dalam array matches!
Kembalikan respons HANYA dalam format JSON valid (tanpa blok kode markdown \`\`\`json):
{
  "found": true,
  "totalMatches": 2,
  "matches": [
    {
      "surahNumber": 2,
      "surahName": "Al-Baqarah",
      "verseNumber": 1,
      "verseKey": "2:1",
      "arabicText": "الم",
      "translation": "Alif Lam Mim.",
      "confidence": "Tinggi",
      "explanation": "Awal Surah Al-Baqarah."
    },
    {
      "surahNumber": 3,
      "surahName": "Ali 'Imran",
      "verseNumber": 1,
      "verseKey": "3:1",
      "arabicText": "الم",
      "translation": "Alif Lam Mim.",
      "confidence": "Tinggi",
      "explanation": "Awal Surah Ali 'Imran."
    }
  ]
}
Jika tidak ada ayat yang cocok sama sekali, kembalikan:
{
  "found": false,
  "message": "Tidak ditemukan ayat yang cocok dengan '${queryText}'. Silakan coba lafalkan kata lainnya."
}`
            }
          ]
        }
      ];
    }

    const response = await ai.models.generateContent({
      model: 'gemini-3.5-flash-lite',
      contents: contents,
    });

    let rawText = response.text || '';
    // Clean potential markdown wrap
    rawText = rawText.replace(/```json/gi, '').replace(/```/g, '').trim();

    try {
      let parsed = JSON.parse(rawText);
      // Normalize single match to matches array if needed
      if (parsed.found && !parsed.matches) {
        if (parsed.surahNumber) {
          parsed.matches = [{
            surahNumber: parsed.surahNumber,
            surahName: parsed.surahName,
            verseNumber: parsed.verseNumber,
            verseKey: parsed.verseKey,
            arabicText: parsed.arabicText,
            translation: parsed.translation,
            confidence: parsed.confidence || 'Tinggi',
            explanation: parsed.explanation
          }];
        } else {
          parsed.matches = [];
        }
      }
      if (parsed.matches && !parsed.totalMatches) {
        parsed.totalMatches = parsed.matches.length;
      }
      res.json(parsed);
    } catch (parseError) {
      console.warn('Failed to parse AI JSON, returning fallback structure:', rawText);
      res.json({
        found: true,
        rawText: rawText,
        message: rawText,
        matches: []
      });
    }

  } catch (error) {
    console.error('Voice Search Error:', error);
    res.status(500).json({ error: 'Failed to process voice search with AI' });
  }
});

const path = require('path');
const fs = require('fs');

const webBuildPath = path.join(__dirname, '../build/web');
const publicBuildPath = path.join(__dirname, 'public');

if (fs.existsSync(webBuildPath)) {
  app.use(express.static(webBuildPath));
  app.use((req, res, next) => {
    if (req.method === 'GET' && !req.path.startsWith('/api/')) {
      return res.sendFile(path.join(webBuildPath, 'index.html'));
    }
    next();
  });
} else if (fs.existsSync(publicBuildPath)) {
  app.use(express.static(publicBuildPath));
  app.use((req, res, next) => {
    if (req.method === 'GET' && !req.path.startsWith('/api/')) {
      return res.sendFile(path.join(publicBuildPath, 'index.html'));
    }
    next();
  });
}

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Backend server running on port ${PORT}`);
  });
}

module.exports = app;
