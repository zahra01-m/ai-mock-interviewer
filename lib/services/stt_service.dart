import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  Future<bool> init() async {
    _isAvailable = await _stt.initialize(
      onError: (_) => _isListening = false,
    );
    return _isAvailable;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function() onStop,
  }) async {
    if (!_isAvailable) return;
    _isListening = true;
    await _stt.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          _isListening = false;
          onStop();
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _stt.stop();
  }

  void dispose() => _stt.cancel();
}