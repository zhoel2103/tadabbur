import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';
import '../models/verse.dart';

class QuranApiService {
  static const String baseUrl = 'https://api.quran.com/api/v4';

  // Fetch list of all surahs
  Future<List<Surah>> getSurahs() async {
    final response = await http.get(Uri.parse('$baseUrl/chapters?language=id'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> chapters = data['chapters'];
      return chapters.map((json) => Surah.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load surahs');
    }
  }

  // Fetch verses for a specific surah
  // translation 33 is Indonesian, audio 7 is Mishary Rashid Alafasy
  Future<List<Verse>> getVerses(int chapterId, {int page = 1, int perPage = 10}) async {
    final response = await http.get(Uri.parse(
        '$baseUrl/verses/by_chapter/$chapterId?language=id&words=true&word_fields=text_uthmani&translations=33&audio=7&fields=text_uthmani&page=$page&per_page=$perPage'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> verses = data['verses'];
      return verses.map((json) => Verse.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load verses');
    }
  }
}
