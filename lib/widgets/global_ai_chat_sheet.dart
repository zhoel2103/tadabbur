import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_api_service.dart';
import '../services/local_storage_service.dart';

class GlobalAiChatSheet extends StatefulWidget {
  const GlobalAiChatSheet({super.key});

  @override
  State<GlobalAiChatSheet> createState() => _GlobalAiChatSheetState();
}

class _GlobalAiChatSheetState extends State<GlobalAiChatSheet> {
  final AiApiService _aiService = AiApiService();
  final LocalStorageService _storageService = LocalStorageService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, String>> _chatHistory = [];
  bool _isChatting = false;

  final List<String> _quickSuggestions = [
    'Tadabbur tematik surah asy-syahr',
    'Tadabbur tematik surah al-Baqarah ayat 1-5',
    'Apa hikmah dari Kisah ashabul Kahfi',
    'Bagaimana konsep shalat khusyuk',
  ];

  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'text': text});
      _chatController.clear();
      _isChatting = true;
    });

    _scrollToBottom();

    try {
      final data = await _aiService.globalChat(text, _chatHistory);
      setState(() {
        _chatHistory.add({'role': 'ai', 'text': data['answer']});
        _isChatting = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _chatHistory.add({'role': 'ai', 'text': 'Maaf, terjadi kesalahan: $e'});
        _isChatting = false;
      });
      _scrollToBottom();
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
        });
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.teal),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
            ],
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

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
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: primary),
                  const SizedBox(width: 8),
                  Text(
                    'Asisten AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary),
                  ),
                ],
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
            child: _chatHistory.isEmpty
                ? SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Icon(Icons.auto_awesome, size: 44, color: primary.withValues(alpha: 0.6)),
                        const SizedBox(height: 12),
                        Text(
                          'Tanyakan apa saja seputar Al-Qur\'an atau Islam...',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: onSurface.withValues(alpha: 0.6), fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Saran Pertanyaan :',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _quickSuggestions.map((suggestion) {
                              return ActionChip(
                                avatar: Icon(Icons.psychology_alt, size: 16, color: primary),
                                label: Text(
                                  suggestion,
                                  style: TextStyle(fontSize: 12, color: primary),
                                ),
                                backgroundColor: primary.withValues(alpha: 0.08),
                                side: BorderSide(color: primary.withValues(alpha: 0.3), width: 0.8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onPressed: () {
                                  _chatController.text = suggestion;
                                  _sendChatMessage();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _chatHistory.length + (_isChatting ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _chatHistory.length && _isChatting) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(color: primary),
                          ),
                        );
                      }
                      
                      final msg = _chatHistory[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? primary.withValues(alpha: 0.15)
                                    : (isDark ? const Color(0xFF334155) : theme.dividerColor.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg['text']!,
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 14.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            if (!isUser)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.bookmark_border, size: 20, color: primary),
                                    tooltip: 'Simpan',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      try {
                                        await _storageService.saveAiAnswer('Global Chat', msg['text']!);
                                        _showMessage('Jawaban disimpan ke riwayat!');
                                      } catch (e) {
                                        _showMessage('Gagal menyimpan.');
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: Icon(Icons.share, size: 20, color: primary),
                                    tooltip: 'Bagikan',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      try {
                                        await Clipboard.setData(ClipboardData(text: msg['text']!));
                                        _showMessage('Teks disalin ke clipboard!');
                                      } catch (e) {
                                        _showMessage('Gagal menyalin (butuh akses HTTPS).');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // Input
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: TextStyle(color: onSurface),
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan Anda...',
                      hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.5)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isChatting ? null : _sendChatMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
