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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tafsir - Ayat ${widget.verseKey}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          Divider(color: theme.dividerColor),
          
          // Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primary))
                : _error != null
                    ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                    : ListView(
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            _explanation ?? '',
                            style: TextStyle(
                              height: 1.6,
                              fontSize: 15,
                              color: onSurface.withValues(alpha: 0.95),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_source != null)
                            Text(
                              'Sumber: $_source',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: onSurface.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  if (_explanation != null) {
                                    await LocalStorageService().saveAiAnswer(widget.verseKey, _explanation!);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Penjelasan disimpan ke koleksi ! ✅')),
                                      );
                                    }
                                  }
                                },
                                icon: Icon(Icons.bookmark_add, color: primary),
                                label: Text('Simpan', style: TextStyle(color: primary)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  if (_explanation != null) {
                                    final shareText = 'Penjelasan Al-Qur\'an Ayat ${widget.verseKey} (via Tafsir Ibnu Katsir):\n\n$_explanation\n\n- Dibagikan dari Tadabbur Qur\'an';
                                    Share.share(shareText);
                                  }
                                },
                                icon: Icon(Icons.share, color: primary),
                                label: Text('Bagikan', style: TextStyle(color: primary)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: primary),
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
