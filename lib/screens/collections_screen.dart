import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<String> _collections = [];

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final collections = await _storageService.getCollections();
    setState(() {
      _collections = collections;
    });
  }

  Future<void> _showVerses(String collectionName) async {
    final verses = await _storageService.getVersesInCollection(collectionName);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Koleksi: $collectionName'),
          content: SizedBox(
            width: double.maxFinite,
            child: verses.isEmpty
                ? const Text('Belum ada ayat di koleksi ini.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: verses.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.menu_book, color: Colors.teal),
                        title: Text('Ayat ${verses[index]}'),
                        // Ideally we'd fetch verse details and show them here or navigate to SurahScreen focused on this verse.
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showAiAnswers() async {
    final groupedAnswers = await _storageService.getSavedAiAnswersGrouped();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Penjelasan AI Tersimpan'),
          content: SizedBox(
            width: double.maxFinite,
            child: groupedAnswers.isEmpty
                ? const Text('Belum ada penjelasan AI yang disimpan.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: groupedAnswers.length,
                    itemBuilder: (context, index) {
                      final verseKey = groupedAnswers.keys.elementAt(index);
                      final explanations = groupedAnswers[verseKey]!;
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ExpansionTile(
                          title: Text('Ayat $verseKey', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          children: explanations.map((expl) => Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(expl, style: const TextStyle(height: 1.5)),
                          )).toList(),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koleksi Ayat'),
        backgroundColor: Colors.teal,
      ),
        body: ListView.builder(
              itemCount: _collections.length + 1,
              itemBuilder: (context, index) {
                if (index == _collections.length) {
                  return ListTile(
                    leading: const Icon(Icons.auto_awesome, color: Colors.purple),
                    title: const Text('Penjelasan AI Tersimpan', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showAiAnswers,
                  );
                }
                final collection = _collections[index];
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.amber),
                  title: Text(collection, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showVerses(collection),
                );
              },
            ),
    );
  }
}
