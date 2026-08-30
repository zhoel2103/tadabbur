import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/surah.dart';
import '../services/local_storage_service.dart';
import '../services/quran_api_service.dart';
import 'surah_screen.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> with SingleTickerProviderStateMixin {
  final LocalStorageService _storageService = LocalStorageService();
  final QuranApiService _apiService = QuranApiService();
  late TabController _tabController;

  List<String> _collections = [];
  Map<String, List<String>> _aiAnswers = {};
  Map<int, Surah> _surahsCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final collections = await _storageService.getCollections();
      final aiAnswers = await _storageService.getSavedAiAnswersGrouped();
      
      // Preload surah list for fast lookup
      final surahs = await _apiService.getSurahs();
      final Map<int, Surah> surahMap = {for (var s in surahs) s.id: s};

      if (mounted) {
        setState(() {
          _collections = collections;
          _aiAnswers = aiAnswers;
          _surahsCache = surahMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createNewCollectionDialog() async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Koleksi Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama koleksi (mis: Doa Harian, Favorit)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
            ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await _storageService.createCollection(name);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  _loadAllData();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _openVerse(String verseKey) async {
    try {
      final parts = verseKey.split(':');
      if (parts.length == 2) {
        final surahId = int.tryParse(parts[0]);
        final verseNum = int.tryParse(parts[1]);

        if (surahId != null && verseNum != null) {
          Surah? surah = _surahsCache[surahId];
          surah ??= await _apiService.getSurahById(surahId);

          if (surah != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SurahScreen(
                  surah: surah!,
                  targetVerseNumber: verseNum,
                ),
              ),
            );
            return;
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Format ayat tidak valid: $verseKey')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka ayat: $e')),
        );
      }
    }
  }

  Future<void> _showCollectionDetail(String collectionName) async {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    final verses = await _storageService.getVersesInCollection(collectionName);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder_special, color: primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          collectionName,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  '${verses.length} ayat tersimpan',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 13),
                ),
                Divider(height: 24, color: theme.dividerColor),
                Expanded(
                  child: verses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_outline, size: 48, color: onSurface.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada ayat di koleksi ini.',
                                style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tekan ikon bookmark saat membaca ayat untuk menyimpannya ke sini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: verses.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
                          itemBuilder: (context, index) {
                            final vKey = verses[index];
                            final parts = vKey.split(':');
                            String surahTitle = 'Ayat $vKey';
                            String arabicName = '';

                            if (parts.length == 2) {
                              final sId = int.tryParse(parts[0]);
                              if (sId != null && _surahsCache.containsKey(sId)) {
                                final s = _surahsCache[sId]!;
                                surahTitle = 'QS. ${s.nameSimple} : Ayat ${parts[1]}';
                                arabicName = s.nameArabic;
                              }
                            }

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.menu_book, color: primary, size: 20),
                              ),
                              title: Text(
                                surahTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: arabicName.isNotEmpty
                                  ? Text(arabicName, style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 13))
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.open_in_new, color: primary),
                                    tooltip: 'Buka Ayat',
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _openVerse(vKey);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: 'Hapus dari koleksi',
                                    onPressed: () async {
                                      await _storageService.removeVerseFromCollection(collectionName, vKey);
                                      verses.remove(vKey);
                                      setModalState(() {});
                                      _loadAllData();
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                _openVerse(vKey);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koleksi & Penjelasan'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.bookmarks_rounded),
              text: 'Koleksi Ayat',
            ),
            Tab(
              icon: Icon(Icons.psychology_rounded),
              text: 'Penjelasan AI',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: KOLEKSI AYAT
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Folder Koleksi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _createNewCollectionDialog,
                            icon: Icon(Icons.add, color: primary),
                            label: Text('Koleksi Baru', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_collections.isEmpty)
                        Card(
                          elevation: 0,
                          color: primary.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(Icons.folder_open, size: 48, color: primary.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                const Text('Belum ada folder koleksi.', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  'Buat folder baru untuk mengorganisir ayat-ayat favorit Anda.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._collections.map((col) {
                          final isDefault = col == 'Favorit';
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: theme.dividerColor),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.folder, color: Colors.amber.shade800, size: 24),
                              ),
                              title: Text(
                                col,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: const Text('Klik untuk melihat ayat tersimpan'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isDefault)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      tooltip: 'Hapus Folder',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text('Hapus koleksi "$col"?'),
                                            content: const Text('Semua ayat di dalam koleksi ini akan dihapus dari daftar.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                child: const Text('Hapus'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await _storageService.deleteCollection(col);
                                          _loadAllData();
                                        }
                                      },
                                    ),
                                  Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.4)),
                                ],
                              ),
                              onTap: () => _showCollectionDetail(col),
                            ),
                          );
                        }),
                    ],
                  ),
                ),

                // TAB 2: PENJELASAN AI
                RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: primary,
                  child: _aiAnswers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.psychology_alt, size: 56, color: primary.withValues(alpha: 0.4)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Belum ada Penjelasan AI yang disimpan',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Saat menggunakan Asisten AI atau membaca Tafsir Ayat, tekan ikon bookmark/simpan untuk menyimpannya di sini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _aiAnswers.length,
                          itemBuilder: (context, index) {
                            final questionKey = _aiAnswers.keys.elementAt(index);
                            final explanations = _aiAnswers[questionKey]!;

                            // Check if question has verse pattern like 'Ayat 2:255' or '1:2'
                            String? potentialVerseKey;
                            final match = RegExp(r'(\d+:\d+)').firstMatch(questionKey);
                            if (match != null) {
                              potentialVerseKey = match.group(1);
                            }

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: theme.dividerColor),
                              ),
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.auto_awesome, color: primary, size: 20),
                                ),
                                title: Text(
                                  questionKey,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: primary,
                                  ),
                                ),
                                subtitle: Text(
                                  '${explanations.length} penjelasan tersimpan',
                                  style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                                ),
                                children: [
                                  if (potentialVerseKey != null) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          onPressed: () => _openVerse(potentialVerseKey!),
                                          icon: Icon(Icons.menu_book, color: primary, size: 18),
                                          label: Text(
                                            'Buka Ayat $potentialVerseKey di Surah',
                                            style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Divider(height: 1, color: theme.dividerColor),
                                  ],
                                  ...explanations.map((expl) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            expl,
                                            style: TextStyle(
                                              height: 1.6,
                                              fontSize: 14.5,
                                              color: onSurface.withValues(alpha: 0.95),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.copy, size: 18, color: primary),
                                                tooltip: 'Salin Penjelasan',
                                                onPressed: () async {
                                                  await Clipboard.setData(ClipboardData(text: '$questionKey\n\n$expl'));
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Penjelasan disalin ke clipboard! 📋')),
                                                    );
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.share, size: 18, color: primary),
                                                tooltip: 'Bagikan',
                                                onPressed: () {
                                                  Share.share('$questionKey\n\n$expl\n\n- Dari Tadabbur Qur\'an');
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                tooltip: 'Hapus',
                                                onPressed: () async {
                                                  await _storageService.deleteAiAnswer(questionKey, expl);
                                                  _loadAllData();
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Penjelasan dihapus.')),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
