class Verse {
  final int id;
  final int verseNumber;
  final String verseKey;
  final String textUthmani;
  final String translation;
  final String? audioUrl;
  final List<Word> words;

  Verse({
    required this.id,
    required this.verseNumber,
    required this.verseKey,
    required this.textUthmani,
    required this.translation,
    required this.words,
    this.audioUrl,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    String translationText = '';
    if (json['translations'] != null && json['translations'].isNotEmpty) {
      translationText = json['translations'][0]['text'];
      // Remove html tags like <sup>1</sup>
      translationText = translationText.replaceAll(RegExp(r'<[^>]*>'), '');
    }

    String? audio;
    if (json['audio'] != null && json['audio']['url'] != null) {
      audio = 'https://verses.quran.com/${json['audio']['url']}';
    }

    List<Word> wordsList = [];
    if (json['words'] != null) {
      wordsList = (json['words'] as List)
          .map((wordJson) => Word.fromJson(wordJson))
          .toList();
    }

    return Verse(
      id: json['id'],
      verseNumber: json['verse_number'],
      verseKey: json['verse_key'],
      textUthmani: json['text_uthmani'] ?? '',
      translation: translationText,
      audioUrl: audio,
      words: wordsList,
    );
  }
}

class Word {
  final int id;
  final int position;
  final String text;
  final String translation;
  final String transliteration;
  final String charTypeName; // 'word' or 'end'

  Word({
    required this.id,
    required this.position,
    required this.text,
    required this.translation,
    required this.transliteration,
    required this.charTypeName,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      position: json['position'],
      text: json['text_uthmani'] ?? json['text'] ?? '',
      translation: json['translation']?['text'] ?? '',
      transliteration: json['transliteration']?['text'] ?? '',
      charTypeName: json['char_type_name'] ?? 'word',
    );
  }
}
