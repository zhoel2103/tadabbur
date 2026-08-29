import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_api_service.dart';
import '../services/quran_api_service.dart';
import '../screens/surah_screen.dart';
import '../utils/web_audio_helper.dart' as web_audio;

class VoiceSearchDialog extends StatefulWidget {
  const VoiceSearchDialog({super.key});

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog> with SingleTickerProviderStateMixin {
  final AiApiService _aiService = AiApiService();
  final QuranApiService _quranService = QuranApiService();
  final TextEditingController _queryController = TextEditingController();

  bool _isListening = false;
  bool _isLoading = false;
  Map<String, dynamic>? _searchResult;
  String? _errorMessage;
  String _listeningStatus = 'Pilih metode input suara atau ketik lafal ayat';

  final List<String> _quickSuggestions = [
    'Alhamdulillahi rabbil \'alamin',
    'Inna a\'thoynakal kautsar',
    'Qul huwallahu ahad',
    'Allahu laa ilaaha illa huwal hayyul qayyum',
    'Qul a\'udzu birobbinnaas',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _stopListening();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Silakan lafalkan atau ketik potongan ayat terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResult = null;
    });

    try {
      final result = await _aiService.voiceSearch(queryText: query);
      setState(() {
        _searchResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memproses pencarian ayat: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _performAudioSearch(String base64Data, String mimeType) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResult = null;
    });

    try {
      final result = await _aiService.voiceSearch(
        audioBase64: base64Data,
        mimeType: mimeType,
      );
      setState(() {
        _searchResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal menganalisis audio rekaman: $e';
        _isLoading = false;
      });
    }
  }

  void _recordViaNativeMic() {
    if (kIsWeb) {
      try {
        web_audio.recordAudioViaFileInput(
          (String base64Data, String mimeType) {
            _performAudioSearch(base64Data, mimeType);
          },
          (String error) {
            setState(() {
              _errorMessage = error;
            });
          },
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Gagal membuka perekam suara: $e';
        });
      }
    }
  }

  void _startSpeechRecognition() {
    setState(() {
      _isListening = true;
      _errorMessage = null;
      _searchResult = null;
      _listeningStatus = 'Mendengarkan suara Anda... Silakan lafalkan ayat';
    });

    if (kIsWeb) {
      try {
        web_audio.startQuranSpeechRecognition(
          'ar-SA',
          (String transcript) {
            if (mounted) {
              setState(() {
                _queryController.text = transcript;
                _listeningStatus = 'Terdeteksi: "$transcript"';
              });
            }
          },
          (String error) {
            if (mounted) {
              setState(() {
                _isListening = false;
                _listeningStatus = 'Izin mikrofon browser perlu disetujui';
                _errorMessage =
                    'Browser membatasi mikrofon pada koneksi HTTP lokal. Silakan gunakan tombol "Rekam Audio Mic", ketik lafal ayat, atau gunakan tombol mikrofon pada keyboard HP Anda.';
              });
            }
          },
          () {
            if (mounted && _isListening) {
              setState(() {
                _isListening = false;
              });
              if (_queryController.text.trim().isNotEmpty) {
                _performSearch(_queryController.text);
              }
            }
          },
        );
      } catch (e) {
        setState(() {
          _isListening = false;
          _errorMessage = 'Speech Recognition error: $e';
        });
      }
    }
  }

  void _stopListening() {
    if (kIsWeb) {
      web_audio.stopQuranSpeechRecognition();
    }
    setState(() {
      _isListening = false;
    });
    if (_queryController.text.trim().isNotEmpty) {
      _performSearch(_queryController.text);
    }
  }

  Future<void> _openSurahScreen(int surahNumber, int? verseNumber) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final surahs = await _quranService.getSurahs();
      final targetSurah = surahs.firstWhere(
        (s) => s.id == surahNumber,
        orElse: () => surahs.first,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close search dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurahScreen(
              surah: targetSurah,
              targetVerseNumber: verseNumber,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka surah: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.teal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Pencarian Suara Ayat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Lafalkan potongan ayat melalui rekaman audio mikrofon atau ketik kata kuncinya.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 24),

            // Search input field
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'Lafal ayat (mis: Qul huwallahu ahad / ar-Rahman)',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_queryController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _queryController.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.teal, size: 20),
                      tooltip: 'Cari',
                      onPressed: () => _performSearch(_queryController.text),
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _performSearch,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Quick suggestion chips
            if (!_isLoading && _searchResult == null) ...[
              const Text(
                'Atau coba contoh potongan ayat berikut:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _quickSuggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion, style: const TextStyle(fontSize: 11, color: Colors.teal)),
                    backgroundColor: Colors.teal.shade50,
                    side: BorderSide(color: Colors.teal.shade200, width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () {
                      _queryController.text = suggestion;
                      _performSearch(suggestion);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Action Voice Options (Record Audio & Speech Recognition)
            if (_searchResult == null) ...[
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Option 1: Native Microphone Voice Record (Direct Audio -> AI)
                        ElevatedButton.icon(
                          onPressed: _recordViaNativeMic,
                          icon: const Icon(Icons.mic, color: Colors.white),
                          label: const Text('Rekam Audio Mic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Option 2: Live Browser Speech-to-Text
                        OutlinedButton.icon(
                          onPressed: _isListening ? _stopListening : _startSpeechRecognition,
                          icon: Icon(
                            _isListening ? Icons.stop : Icons.graphic_eq,
                            color: _isListening ? Colors.red : Colors.teal,
                          ),
                          label: Text(
                            _isListening ? 'Selesai' : 'Dikte Suara',
                            style: TextStyle(color: _isListening ? Colors.red : Colors.teal, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _isListening ? Colors.red : Colors.teal, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _listeningStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isListening ? Colors.red.shade600 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Loading state
            if (_isLoading) ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: Colors.teal),
                    const SizedBox(height: 16),
                    Text(
                      'AI sedang menganalisis & mencocokkan ayat...',
                      style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Error state
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Result Display Card
            if (_searchResult != null) ...[
              if (_searchResult!['found'] == true) ...[
                Builder(
                  builder: (context) {
                    final List matches = _searchResult!['matches'] as List? ?? [
                      {
                        'surahNumber': _searchResult!['surahNumber'],
                        'surahName': _searchResult!['surahName'],
                        'verseNumber': _searchResult!['verseNumber'],
                        'verseKey': _searchResult!['verseKey'],
                        'arabicText': _searchResult!['arabicText'],
                        'translation': _searchResult!['translation'],
                        'confidence': _searchResult!['confidence'],
                        'explanation': _searchResult!['explanation'],
                      }
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.teal, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ditemukan ${matches.length} Ayat yang Cocok',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 14),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _searchResult = null;
                                    _queryController.clear();
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Cari Lagi', style: TextStyle(color: Colors.teal, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // List of Match Cards
                        ...matches.map((item) {
                          final match = item as Map<String, dynamic>;
                          final surahNum = match['surahNumber'];
                          final verseNum = match['verseNumber'];
                          final surahName = match['surahName'] ?? 'Surah';
                          final arabic = match['arabicText'];
                          final translation = match['translation'];
                          final explanation = match['explanation'];
                          final confidence = match['confidence'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.teal.shade300, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Badge & Confidence
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.teal,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'QS. $surahName [$surahNum] : $verseNum',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (confidence != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Text(
                                          'Akurasi: $confidence',
                                          style: TextStyle(color: Colors.green.shade800, fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Arabic Text
                                if (arabic != null)
                                  Text(
                                    arabic,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.amiri(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      height: 1.8,
                                      color: Colors.teal.shade900,
                                    ),
                                  ),
                                const SizedBox(height: 10),

                                // Translation
                                if (translation != null)
                                  Text(
                                    '"$translation"',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),

                                // Explanation Note
                                if (explanation != null)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      explanation,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                    ),
                                  ),
                                const SizedBox(height: 12),

                                // Action Button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (surahNum != null) {
                                      final sId = surahNum is int ? surahNum : int.parse(surahNum.toString());
                                      final vId = verseNum != null
                                          ? (verseNum is int ? verseNum : int.tryParse(verseNum.toString()))
                                          : null;
                                      _openSurahScreen(sId, vId);
                                    }
                                  },
                                  icon: const Icon(Icons.menu_book, color: Colors.white, size: 16),
                                  label: Text('Buka QS. $surahName : $verseNum',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, color: Colors.amber, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        _searchResult!['message'] ?? 'Ayat tidak ditemukan.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _searchResult = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Coba Kata Lain', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
