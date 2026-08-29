// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

void recordAudioViaFileInput(
  void Function(String base64Data, String mimeType) onData,
  void Function(String error) onError,
) {
  try {
    js.context.callMethod('recordAudioViaFileInput', [
      (String base64Data, String mimeType) {
        onData(base64Data, mimeType);
      },
      (String error) {
        onError(error);
      }
    ]);
  } catch (e) {
    onError(e.toString());
  }
}

void startQuranSpeechRecognition(
  String lang,
  void Function(String transcript) onTranscript,
  void Function(String error) onError,
  void Function() onEnd,
) {
  try {
    js.context.callMethod('startQuranSpeechRecognition', [
      lang,
      (String transcript) {
        onTranscript(transcript);
      },
      (String error) {
        onError(error);
      },
      () {
        onEnd();
      }
    ]);
  } catch (e) {
    onError(e.toString());
  }
}

void stopQuranSpeechRecognition() {
  try {
    js.context.callMethod('stopQuranSpeechRecognition');
  } catch (_) {}
}
