void recordAudioViaFileInput(
  void Function(String base64Data, String mimeType) onData,
  void Function(String error) onError,
) {}

void startQuranSpeechRecognition(
  String lang,
  void Function(String transcript) onTranscript,
  void Function(String error) onError,
  void Function() onEnd,
) {}

void stopQuranSpeechRecognition() {}
