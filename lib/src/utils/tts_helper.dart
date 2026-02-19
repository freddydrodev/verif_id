import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// Simple singleton TTS helper preconfigured for French female voice.
/// Consumers can toggle on/off TTS by not calling it.
class TtsHelper {
  TtsHelper._internal() {
    _tts = FlutterTts();
    _initCompleter = Completer<void>();
    _init();
  }

  static final TtsHelper instance = TtsHelper._internal();
  late final FlutterTts _tts;
  late final Completer<void> _initCompleter;

  Future<void> _init() async {
    try {
      await _tts.setLanguage('fr-FR');
      // prefer female voice; voices vary by platform
      final voices = await _tts.getVoices;
      final female = voices?.firstWhere((v) {
        final name = (v as Map).toString().toLowerCase();
        return name.contains('female') ||
            name.contains('femme') ||
            name.contains('female');
      }, orElse: () => null);
      if (female != null && female is Map && female['name'] != null) {
        await _tts.setVoice({'name': female['name']});
      }
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initCompleter.complete();
    } catch (_) {
      // complete even on error so speak doesn't hang
      _initCompleter.complete();
    }
  }

  Future<void> speakFrFemale(String text) async {
    try {
      await _initCompleter.future;
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
