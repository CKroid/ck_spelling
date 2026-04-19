import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  TtsService._internal();

  FlutterTts get flutterTts => _flutterTts;

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      // Default initialization
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.75);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.awaitSpeakCompletion(true); // Crucial for sequencing
      _isInitialized = true;
    }
  }

  Future<void> speak(String text) async {
    await ensureInitialized();
    await _flutterTts.stop(); // Stop any current speech before starting new one
    await Future.delayed(const Duration(milliseconds: 50)); // Small gap for Web
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
