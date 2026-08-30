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

  Future<void> deleteCollection(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final collections = await getCollections();
    collections.remove(name);
    await prefs.setStringList('collections_list', collections);
    await prefs.remove('collection_$name');
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

  Future<void> removeVerseFromCollection(String collectionName, String verseKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'collection_$collectionName';
    final List<String> verses = prefs.getStringList(key) ?? [];
    verses.remove(verseKey);
    await prefs.setStringList(key, verses);
  }

  Future<List<String>> getVersesInCollection(String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('collection_$collectionName') ?? [];
  }

  // AI SAVED ANSWERS
  Future<void> saveAiAnswer(String topic, String explanation, {String? question}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> answers = prefs.getStringList('saved_ai_answers_v2') ?? [];
    
    final cleanQuestion = (question ?? topic).trim();

    bool exists = false;
    for (var a in answers) {
      if (a.contains(explanation)) exists = true;
    }
    
    if (!exists) {
      final Map<String, dynamic> data = {
        'verseKey': topic,
        'question': cleanQuestion,
        'explanation': explanation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      answers.add(json.encode(data));
      await prefs.setStringList('saved_ai_answers_v2', answers);
    }
  }

  Future<void> deleteAiAnswer(String questionOrTopic, String explanation) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> answers = prefs.getStringList('saved_ai_answers_v2') ?? [];
    
    answers.removeWhere((item) {
      try {
        final data = json.decode(item);
        final exp = data['explanation'] as String?;
        final q = (data['question'] ?? data['verseKey']) as String?;
        return exp == explanation || (q == questionOrTopic && exp == explanation);
      } catch (_) {
        return false;
      }
    });

    await prefs.setStringList('saved_ai_answers_v2', answers);
  }
  
  Future<Map<String, List<String>>> getSavedAiAnswersGrouped() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> answers = prefs.getStringList('saved_ai_answers_v2') ?? [];
    
    Map<String, List<String>> grouped = {};
    for (String str in answers) {
      try {
        final data = json.decode(str);
        // Use question if available, otherwise fall back to verseKey
        String groupKey = (data['question'] as String?)?.trim() ?? (data['verseKey'] as String?)?.trim() ?? 'Tanya Jawab AI';
        
        // Normalize 'Global Chat' to 'Tanya Jawab AI' if from legacy records
        if (groupKey == 'Global Chat') {
          groupKey = 'Tanya Jawab AI';
        }

        final explanation = data['explanation'] as String;
        
        if (!grouped.containsKey(groupKey)) {
          grouped[groupKey] = [];
        }
        grouped[groupKey]!.add(explanation);
      } catch (e) {
        // ignore parsing errors from old formats if any
      }
    }
    return grouped;
  }
}
