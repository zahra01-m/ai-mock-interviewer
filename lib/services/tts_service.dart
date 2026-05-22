import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _initialized = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // ✅ FIX 1: awaitSpeakCompletion — yeh Android par zaroori hai
    // Bina iske speak() immediately return kar deta tha — TTS chal hi nahi rahi thi
    await _tts.awaitSpeakCompletion(true);

    // ✅ FIX 2: Android TTS engine explicitly set karo
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);   // thoda slow — interview ke liye better
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);

    // ✅ FIX 3: Handlers properly set karo
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
    });
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    // Pehle roko agar pehle se bol raha hai
    if (_isSpeaking) await stop();

    _isSpeaking = true;

    // ✅ FIX 4: Completer use karo taake properly await ho sake
    final completer = Completer<void>();

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (!completer.isCompleted) completer.complete();
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      if (!completer.isCompleted) completer.complete();
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
      if (!completer.isCompleted) completer.complete();
    });

    await _tts.speak(text);

    // Android par yeh completer ke complete hone ka wait karta hai
    await completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        _isSpeaking = false;
      },
    );
  }

  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  void dispose() {
    _isSpeaking = false;
    _tts.stop();
  }
}