import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiApiService {
  static String get baseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.startsWith('https://') || origin.contains('onrender.com') || origin.contains('vercel.app')) {
        return '$origin/api/ai';
      }
    }
    return 'http://192.168.1.2:3000/api/ai';
  }

  Future<Map<String, dynamic>> explainVerse(String verseKey) async {
    final response = await http.post(
      Uri.parse('$baseUrl/explain'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'verseKey': verseKey}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get AI explanation: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> chat(String verseKey, String question, List<Map<String, String>> history) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'verseKey': verseKey,
        'question': question,
        'history': history,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send chat: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> globalChat(String question, List<Map<String, String>> history) async {
    final response = await http.post(
      Uri.parse('$baseUrl/global-chat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'question': question,
        'history': history,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send global chat: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> voiceSearch({
    String? queryText,
    String? audioBase64,
    String? mimeType,
  }) async {
    final Map<String, dynamic> requestBody = {};
    if (queryText != null && queryText.isNotEmpty) {
      requestBody['queryText'] = queryText;
    }
    if (audioBase64 != null && audioBase64.isNotEmpty) {
      requestBody['audioBase64'] = audioBase64;
      requestBody['mimeType'] = mimeType ?? 'audio/webm';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/voice-search'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to perform voice search: ${response.body}');
    }
  }
}
