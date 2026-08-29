import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/ai_api_service.dart';
import '../services/local_storage_service.dart';

class AiExplanationPanel extends StatefulWidget {
  final String verseKey;

  const AiExplanationPanel({super.key, required this.verseKey});

  @override
  State<AiExplanationPanel> createState() => _AiExplanationPanelState();
}

class _AiExplanationPanelState extends State<AiExplanationPanel> {
  final AiApiService _aiService = AiApiService();
  bool _isLoading = true;
  String? _explanation;
  String? _source;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchExplanation();
  }

  Future<void> _fetchExplanation() async {
    try {
      final data = await _aiService.explainVerse(widget.verseKey);
      setState(() {
        _explanation = data['explanation'];
        _source = data['source'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Penjelasan - Ayat ${widget.verseKey}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const Divider(),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                    : ListView(
                        children: [
                          const Text('Penjelasan Utama:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_explanation ?? '', style: const TextStyle(height: 1.5)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Sumber: $_source', style: const TextStyle(fontSize: 12, color: Colors.orange))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  if (_explanation != null) {
                                    await LocalStorageService().saveAiAnswer(widget.verseKey, _explanation!);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Penjelasan disimpan ke koleksi AI! ✅')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.bookmark_border, color: Colors.teal),
                                label: const Text('Simpan', style: TextStyle(color: Colors.teal)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.teal),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  if (_explanation != null) {
                                    final shareText = 'Penjelasan Al-Qur\'an Ayat ${widget.verseKey} (via AI & Tafsir Ibnu Katsir):\n\n$_explanation\n\n- Dibagikan dari Tadabbur Qur\'an';
                                    Share.share(shareText);
                                  }
                                },
                                icon: const Icon(Icons.share, color: Colors.teal),
                                label: const Text('Bagikan', style: TextStyle(color: Colors.teal)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.teal),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
