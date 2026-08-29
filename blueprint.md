# Blueprint: Aplikasi Studi Qur'an Berbasis AI (Replika Tazkiya)

> Referensi: tazkiya.chat — aplikasi studi Al-Qur'an ayat per ayat dengan penjelasan AI yang bersumber dari Tafsir Ibn Katsir, Hadits, dan terjemahan, dilengkapi audio, analisis kata, dan pencarian suara cerdas. Tersedia di web, iOS, dan Android.

---

## 1. Konsep Produk

Aplikasi pendamping studi Al-Qur'an yang menggabungkan:
- Pembacaan Al-Qur'an ayat demi ayat (114 surah lengkap)
- Penjelasan/tafsir berbasis AI yang **selalu mencantumkan sumber rujukan** (bukan jawaban AI tanpa dasar)
- Tanya-jawab interaktif seputar ayat (mirip chat) dengan jawaban yang dikutip dari kitab tafsir/hadits
- Pencarian suara (Voice Search) untuk mendeteksi ayat dari suara potongan ayat atau lafal yang dibacakan
- Ruang refleksi/jurnal pribadi per ayat

Diferensiasi dari app Qur'an biasa: fokus ke **pemahaman, refleksi & pencarian cerdas berbasis AI**.

---

## 2. Target Pengguna

- Muslim yang ingin memahami makna ayat, bukan sekadar membaca
- Pengguna yang ingin bertanya bebas tentang suatu ayat dan mendapat jawaban yang bisa dipertanggungjawabkan sumbernya
- Pengguna yang ingin mencari ayat secara cepat hanya dengan melafalkan potongan suaranya (Voice Search)

---

## 3. Fitur Inti

### 3.1 Baca Ayat per Ayat
- Tampilan satu ayat fokus (bukan hanya mode mushaf penuh) — surah dipecah ayat per ayat untuk studi mendalam
- Teks Arab + transliterasi (opsional) + terjemahan
- Navigasi: lanjut/kembali antar ayat, lompat ke surah:ayat tertentu, daftar 114 surah

### 3.2 Audio Recitation
- Player audio per ayat dengan highlight kata berjalan (sinkron)
- Pilihan qari (minimal 1–2 di MVP, bisa ditambah)
- Mode putar berkelanjutan (auto-next ayat)

### 3.3 Penjelasan AI Bersumber (AI Explanation, via MCP Server mcp.quran.ai)
- Tombol "Jelaskan ayat ini" → AI memanggil **MCP Server mcp.quran.ai** (dioperasikan oleh quran.foundation) untuk mengambil teks ayat, terjemahan, dan tafsir yang terverifikasi, lalu menyusun penjelasan berdasarkan data tsb
- MCP server ini menyediakan tafsir dari 15+ ulama (termasuk Ibnu Katsir, at-Tabari, al-Qurtubi, as-Sa'di), 50+ terjemahan di 30+ bahasa, teks Arab multi-qira'at, pencarian full-text, dan data morfologi kata — semuanya bersumber dari korpus Quran.com yang terverifikasi
- Karena AI mengambil data lewat tool call terstruktur (bukan dari memori/training data), risiko AI mengarang atau salah kutip ayat/tafsir jauh berkurang — setiap penjelasan bisa dilacak balik ke sumber tafsir aslinya
- Setiap penjelasan AI menampilkan atribusi sumber (nama tafsir/ulama) agar bisa diverifikasi pengguna
- Mode tanya-jawab bebas: pengguna mengetik pertanyaan spesifik tentang ayat yang sedang dibuka → AI memanggil tool pencarian/tafsir dari MCP server sesuai kebutuhan pertanyaan, lalu menjawab dalam konteks ayat tsb + sumber
- Untuk hadits terkait ayat: AI memanggil sumber hadits terpisah (lihat §7) karena mcp.quran.ai belum mencakup hadits — di MVP lewat REST API, di tahap produksi lewat MCP hadits self-hosted agar pola tool-call-nya konsisten dengan mcp.quran.ai

### 3.4 Analisis Kata (Word Analysis)
- Tap per kata Arab → muncul: arti kata, akar kata (root), kelas kata, dan (opsional) kemunculan kata yang sama di ayat lain

### 3.5 Pencarian Suara (Voice Search Ayat)
- Deteksi ayat dari lantunan/suara pengguna atau rekaman audio mikrofon
- Pencarian fonetik/lafal teks cerdas (mis. "inna a'thoynakal kautsar")
- Menampilkan Surah, nomor ayat, teks Arab, terjemahan, dan tombol navigasi langsung ke Surah

### 3.6 Refleksi & Jurnal
- Ruang catatan pribadi per ayat ("apa makna ayat ini buat saya")
- Riwayat jurnal bisa dilihat kembali per ayat/tanggal
- (Opsional lanjutan) rich text, embed ayat/hadits ke dalam catatan

### 3.7 Bookmark & Koleksi
- Simpan ayat favorit
- Buat koleksi/kumpulan ayat bertema (mis. "Ayat tentang sabar")

### 3.8 Akun & Sinkronisasi (Keputusan final: mode tanpa login didukung)
- Mode tamu (tanpa login) aktif secara default — baca ayat, dengar audio, pencarian suara, dan "Tafsir Ibn-Katsir" bisa dipakai langsung tanpa akun
- Login (email/Google/Apple) bersifat opsional, dibutuhkan hanya untuk fitur yang menyimpan data personal: bookmark dan jurnal lintas perangkat

---

## 4. Struktur Layar (Screens)

1. **Onboarding** — perkenalan konsep, pilih bahasa & tujuan (opsional)
2. **Home / Dashboard** — kartu "Pencarian Suara Ayat", tanya asisten AI, akses cepat ke 114 surah
3. **Daftar Surah** — 114 surah dengan info jumlah ayat, tempat turun (Makkiyah/Madaniyah)
4. **Layar Baca Ayat** (halaman utama studi):
   - Teks Arab ayat aktif (besar, fokus)
   - Transliterasi + terjemahan
   - Tombol: Dengar Audio, Tafsir Ibn-Katsir, Refleksi/Jurnal, Bookmark, Bagikan
   - Navigasi ayat sebelumnya/berikutnya
5. **Panel Penjelasan AI** — bottom sheet/side panel berisi jawaban AI + kutipan sumber (tafsir/hadits) + tombol "tanya lebih lanjut"
6. **Dialog Pencarian Suara** — antarmuka mikrofon interaktif dan pencocokan ayat multimodal AI
7. **Analisis Kata** — popup saat tap kata: arti, akar kata, kemunculan lain
8. **Jurnal Saya** — daftar semua refleksi tersimpan, bisa difilter per surah/tanggal
9. **Bookmark & Koleksi**
10. **Pengaturan** — bahasa terjemahan, sumber tafsir default, qari default, tema (terang/gelap)
11. **Login/Profil**

---

## 5. Alur Pengguna Utama (User Flow)

```
Buka App
  → (opsional) Login/lanjut sebagai tamu
  → Home: Pencarian Suara atau pilih Surah
  → Pencarian Suara: lafalkan potongan ayat → AI temukan ayat → Buka di Surah
  → Layar Baca Ayat:
      → Dengar audio ayat
      → Tap "Jelaskan Ayat" → AI tampilkan penjelasan + sumber
      → Tanya pertanyaan spesifik → AI jawab + sumber
      → Tulis refleksi pribadi → simpan ke Jurnal
  → Lanjut ke ayat berikutnya / kembali ke daftar surah
```

---

## 6. Rancangan Data (Model Utama)

- **Surah**: id, nama_arab, nama_latin, arti, jumlah_ayat, tempat_turun
- **Ayat**: id, surah_id, nomor_ayat, teks_arab, transliterasi, terjemahan(bahasa), audio_url, kata[] (untuk word analysis)
- **TafsirEntry**: ayat_id, sumber (mis. "Ibnu Katsir"), teks_tafsir
- **HaditsRujukan**: ayat_id (opsional relasi), teks_hadits, perawi, sumber_kitab
- **AIExplanationLog**: user_id, ayat_id, pertanyaan, jawaban, sumber_dikutip[], timestamp
- **Jurnal**: user_id, ayat_id, isi_catatan, tanggal
- **Bookmark**: user_id, ayat_id, koleksi_id (opsional)
- **Koleksi**: user_id, nama, ayat_id[]
- **User**: id, nama, email, preferensi (bahasa, sumber tafsir default, qari default)

---

## 7. Sumber Data & Integrasi (Rekomendasi)

| Kebutuhan | Sumber yang disarankan |
|---|---|
| Teks Arab & terjemahan | **MCP Server mcp.quran.ai** (multi-qira'at, 50+ terjemahan) — atau Quran Foundation API (api.quran.com v4) / EQuran.id API sebagai alternatif untuk kebutuhan non-AI |
| Audio per-ayat + timestamp kata | Quran Foundation API (api.quran.com v4) |
| Tafsir (default: Ibnu Katsir) & penjelasan AI bersumber | **MCP Server mcp.quran.ai** — menyediakan tafsir dari 15+ ulama (Ibnu Katsir, at-Tabari, al-Qurtubi, as-Sa'di, dll.), diakses AI lewat tool call terstruktur sehingga jawaban selalu bisa dilacak ke sumber aslinya |
| Pencarian Suara (Voice Search) | Model Multimodal Gemini via endpoint backend `/api/ai/voice-search` |
| Tafsir tambahan (opsional, bahasa Indonesia) | quran-api-id (Kemenag, Quraish Shihab, Al-Jalalain) — sebagai pilihan tambahan di luar default, jika belum tersedia di mcp.quran.ai |
| Hadits | HadithAPI.com (MVP) / self-hosted **ovehbe/hadith-mcp** (Produksi) |
| Analisis kata & akar kata | Data morfologi tersedia di MCP Server mcp.quran.ai |

---

## 8. Tumpukan Teknologi (Saran)

- **Web**: Flutter Web / Next.js
- **Mobile**: Flutter (1 basis kode untuk iOS & Android)
- **Backend**: Node.js (Express) + Gemini API
- **AI**: Gemini API (`gemini-3.5-flash-lite`) untuk Penjelasan Tafsir, Global Chat, & Voice Search
- **Auth**: Firebase Auth / Supabase Auth

---

## 9. Model Monetisasi (Opsional, ikuti versi asli: gratis)

- MVP: 100% gratis, semua fitur inti terbuka

---

## 10. Roadmap Bertahap

**Fase 1 — MVP**
- Baca ayat per ayat + audio + terjemahan (114 surah)
- Bookmark & Jurnal dasar
- Pencarian Suara (Voice Search Ayat)

**Fase 2 — AI Core**
- Integrasi MCP Server mcp.quran.ai ke backend/AI layer
- Integrasi sumber hadits
- Penjelasan AI bersumber (tafsir Ibnu Katsir sebagai default)
- Tanya-jawab AI per ayat dengan atribusi sumber

**Fase 3 — Refleksi & Pendalaman**
- Analisis kata & akar kata
- Koleksi ayat bertema
- Sinkronisasi multi-perangkat penuh

---

## 11. Keputusan Final

| Item | Keputusan |
|---|---|
| Bahasa utama | Indonesia |
| Sumber tafsir default | Ibnu Katsir |
| Platform mobile | Flutter (cross-platform) |
| Fitur Pencarian | Pencarian Suara (Voice Search) berbasis AI |
| Akses | Mode tanpa login (guest) tersedia untuk fitur baca dasar & pencarian suara |

**Implikasi teknis:**
- Mode tanpa login: fitur baca ayat, audio, pencarian suara, dan "Tafsir Ibn-Katsir" harus bisa diakses tanpa akun. Fitur yang menyimpan data personal (bookmark, jurnal) tetap mewajibkan login agar data tersinkron.
- Flutter dipilih agar komponen UI (player audio, tampilan ayat per ayat) berpotensi digunakan ulang lintas proyek app Qur'an lain.