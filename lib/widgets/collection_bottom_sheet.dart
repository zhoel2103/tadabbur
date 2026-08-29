import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class CollectionBottomSheet extends StatefulWidget {
  final String verseKey;

  const CollectionBottomSheet({super.key, required this.verseKey});

  @override
  State<CollectionBottomSheet> createState() => _CollectionBottomSheetState();
}

class _CollectionBottomSheetState extends State<CollectionBottomSheet> {
  final LocalStorageService _storageService = LocalStorageService();
  final TextEditingController _newCollectionController = TextEditingController();
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

  Future<void> _addToCollection(String collectionName) async {
    await _storageService.addVerseToCollection(collectionName, widget.verseKey);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ayat ditambahkan ke koleksi "$collectionName"')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _createNewCollection() async {
    final name = _newCollectionController.text.trim();
    if (name.isNotEmpty) {
      await _storageService.createCollection(name);
      await _loadCollections();
      _newCollectionController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Simpan ke Koleksi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCollectionController,
                  decoration: InputDecoration(
                    hintText: 'Koleksi baru...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _createNewCollection,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                child: const Text('Buat'),
              ),
            ],
          ),
          const Divider(height: 32),
          if (_collections.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Belum ada koleksi')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _collections.length,
              itemBuilder: (context, index) {
                final collection = _collections[index];
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.teal),
                  title: Text(collection),
                  onTap: () => _addToCollection(collection),
                );
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
