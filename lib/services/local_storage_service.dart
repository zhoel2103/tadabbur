import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  // JOURNAL METHODS
  Future<void> saveJournal(String verseKey, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('journal_$verseKey', text);
  }

  Future<String?> getJournal(String verseKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('journal_$verseKey');
  }

  // COLLECTIONS (BOOKMARKS) METHODS
  Future<List<String>> getCollections() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('collections_list') ?? ['Favorit']; // Default collection
  }

  Future<void> createCollection(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final collections = await getCollections();
    if (!collections.contains(name)) {
      collections.add(name);
      await prefs.setStringList('collections_list', collections);
    }
  }

  Future<void> addVerseToCollection(String collectionName, String verseKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'collection_$collectionName';
    final List<String> verses = prefs.getStringList(key) ?? [];
    if (!verses.contains(verseKey)) {
      verses.add(verseKey);
      await prefs.setStringList(key, verses);
    }
  }

  Future<List<String>> getVersesInCollection(String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('collection_$collectionName') ?? [];
  }

  // AI SAVED ANSWERS
  Future<void> saveAiAnswer(String verseKey, String explanation) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> answers = prefs.getStringList('saved_ai_answers_v2') ?? [];
    
    bool exists = false;
    for (var a in answers) {
      if (a.contains(explanation)) exists = true;
    }
    
    if (!exists) {
      final Map<String, dynamic> data = {
        'verseKey': verseKey,
        'explanation': explanation,
      };
      answers.add(json.encode(data));
      await prefs.setStringList('saved_ai_answers_v2', answers);
    }
  }
  
  Future<Map<String, List<String>>> getSavedAiAnswersGrouped() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> answers = prefs.getStringList('saved_ai_answers_v2') ?? [];
    
    Map<String, List<String>> grouped = {};
    for (String str in answers) {
      try {
        final data = json.decode(str);
        final verseKey = data['verseKey'] as String;
        final explanation = data['explanation'] as String;
        
        if (!grouped.containsKey(verseKey)) {
          grouped[verseKey] = [];
        }
        grouped[verseKey]!.add(explanation);
      } catch (e) {
        // ignore parsing errors from old formats if any
      }
    }
    return grouped;
  }
}
