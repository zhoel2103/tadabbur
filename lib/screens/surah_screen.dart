import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/surah.dart';
import '../models/verse.dart';
import '../services/quran_api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/ai_explanation_panel.dart';
import '../widgets/journal_panel.dart';
import '../widgets/collection_bottom_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

class SurahScreen extends StatefulWidget {
  final Surah surah;
  final int? targetVerseNumber;

  const SurahScreen({super.key, required this.surah, this.targetVerseNumber});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  final QuranApiService _apiService = QuranApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final LocalStorageService _storageService = LocalStorageService();
  
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _targetVerseKey = GlobalKey();

  final List<Verse> _verses = [];
  int _minPageLoaded = 1;
  int _maxPageLoaded = 1;
  bool _isLoading = false;
  bool _isLoadingPrev = false;
  bool _hasMore = true;
  String? _error;
  bool _hasScrolledToTarget = false;
  
  int? _currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    if (widget.targetVerseNumber != null) {
      final targetPage = ((widget.targetVerseNumber! - 1) ~/ 20) + 1;
      _minPageLoaded = targetPage;
      _maxPageLoaded = targetPage;
    }

    _fetchVerses();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500 &&
        !_isLoading &&
        _hasMore) {
      _fetchNextVerses();
    }
  }

  Future<void> _fetchVerses() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newVerses = await _apiService.getVerses(widget.surah.id, page: _maxPageLoaded, perPage: 20);
      if (!mounted) return;
      
      setState(() {
        if (newVerses.isEmpty) {
          _hasMore = false;
        } else {
          _verses.addAll(newVerses);
          if (newVerses.length < 20) {
            _hasMore = false;
          }
        }
        _isLoading = false;
      });

      // Auto scroll to target verse if requested
      if (widget.targetVerseNumber != null && !_hasScrolledToTarget) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToTargetVerse();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNextVerses() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _maxPageLoaded + 1;
      final newVerses = await _apiService.getVerses(widget.surah.id, page: nextPage, perPage: 20);
      if (!mounted) return;
      
      setState(() {
        if (newVerses.isEmpty) {
          _hasMore = false;
        } else {
          _maxPageLoaded = nextPage;
          _verses.addAll(newVerses);
          if (newVerses.length < 20) {
            _hasMore = false;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPreviousVerses() async {
    if (_isLoadingPrev || _minPageLoaded <= 1) return;
    setState(() {
      _isLoadingPrev = true;
    });

    try {
      final prevPage = _minPageLoaded - 1;
      final prevVerses = await _apiService.getVerses(widget.surah.id, page: prevPage, perPage: 20);
      if (!mounted) return;
      
      setState(() {
        if (prevVerses.isNotEmpty) {
          _minPageLoaded = prevPage;
          _verses.insertAll(0, prevVerses);
        }
        _isLoadingPrev = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPrev = false;
      });
    }
  }

  void _scrollToTargetVerse() {
    if (_hasScrolledToTarget) return;
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_targetVerseKey.currentContext != null) {
        _hasScrolledToTarget = true;
        Scrollable.ensureVisible(
          _targetVerseKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.08, // Positions at the top with comfortable padding
        );
      } else {
        // Fallback offset scroll
        final targetIndex = _verses.indexWhere((v) => v.verseNumber == widget.targetVerseNumber);
        if (targetIndex != -1) {
          _hasScrolledToTarget = true;
          final offset = (targetIndex * 260.0).clamp(0.0, _scrollController.position.maxScrollExtent);
          _scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }

  Future<void> _playAudio(String? url, int index) async {
    if (url == null) return;
    
    try {
      if (_currentlyPlayingIndex == index && _audioPlayer.playing) {
        await _audioPlayer.pause();
        setState(() {
          _currentlyPlayingIndex = null;
        });
      } else {
        await _audioPlayer.setUrl(url);
        await _audioPlayer.play();
        setState(() {
          _currentlyPlayingIndex = index;
        });
        
        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              if (_currentlyPlayingIndex == index) {
                _currentlyPlayingIndex = null;
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surah.nameSimple),
        backgroundColor: Colors.teal,
      ),
      body: _verses.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _verses.isEmpty && _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchVerses,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _verses.isEmpty
                  ? const Center(child: Text('No Verses found.'))
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _verses.length + (_minPageLoaded > 1 ? 1 : 0) + (_isLoading ? 1 : 0),
                      separatorBuilder: (context, index) => const Divider(height: 32),
                      itemBuilder: (context, index) {
                        // Top item for loading previous verses if jumped to mid-surah
                        if (_minPageLoaded > 1 && index == 0) {
                          return Center(
                            child: _isLoadingPrev
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(color: Colors.teal),
                                  )
                                : TextButton.icon(
                                    onPressed: _fetchPreviousVerses,
                                    icon: const Icon(Icons.arrow_upward, color: Colors.teal),
                                    label: Text(
                                      'Muat Ayat Sebelumnya (Hal. ${_minPageLoaded - 1})',
                                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                          );
                        }

                        final verseIndex = _minPageLoaded > 1 ? index - 1 : index;

                        if (verseIndex >= _verses.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: Colors.teal),
                            ),
                          );
                        }
                        
                        final verse = _verses[verseIndex];
                        final isPlaying = _currentlyPlayingIndex == verseIndex;
                        final isTargetVerse = widget.targetVerseNumber != null && verse.verseNumber == widget.targetVerseNumber;

              return Container(
                key: isTargetVerse ? _targetVerseKey : null,
                padding: isTargetVerse ? const EdgeInsets.all(12) : EdgeInsets.zero,
                decoration: isTargetVerse
                    ? BoxDecoration(
                        color: Colors.amber.shade50.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade600, width: 2),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isTargetVerse ? Colors.amber.shade800 : Colors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                verse.verseKey,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isTargetVerse ? Colors.white : Colors.teal,
                                ),
                              ),
                            ),
                            if (isTargetVerse) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade400),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.my_location, color: Colors.amber.shade900, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Ayat Dicari',
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                        children: [
                          if (verse.audioUrl != null)
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                color: Colors.teal,
                                size: 32,
                              ),
                              onPressed: () => _playAudio(verse.audioUrl, verseIndex),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: Colors.teal),
                            tooltip: 'Jurnal',
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => JournalPanel(verseKey: verse.verseKey),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_border, color: Colors.teal),
                            tooltip: 'Simpan ke Koleksi',
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => CollectionBottomSheet(verseKey: verse.verseKey),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Menampilkan teks per-kata untuk fitur terjemahan tooltip
                  Wrap(
                    alignment: WrapAlignment.start,
                    textDirection: TextDirection.rtl,
                    spacing: 8,
                    runSpacing: 12,
                    children: verse.words.map((word) {
                      if (word.charTypeName == 'end') {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            word.text,
                            style: GoogleFonts.amiri(fontSize: 28, color: Colors.teal),
                          ),
                        );
                      }
                      
                      return Tooltip(
                        message: word.translation,
                        triggerMode: TooltipTriggerMode.tap,
                        preferBelow: false,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
                        child: Column(
                          children: [
                            Text(
                              word.text,
                              style: GoogleFonts.amiri(
                                fontSize: 28,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    verse.translation,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AiExplanationPanel(verseKey: verse.verseKey),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, color: Colors.teal),
                      label: const Text('Tafsir Ibn-Katsir', style: TextStyle(color: Colors.teal)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.teal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    );
  }
}
