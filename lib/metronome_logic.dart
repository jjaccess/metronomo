import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class MetronomeLogic {
  final AudioPlayer _playerAccent = AudioPlayer();
  final AudioPlayer _playerNormal = AudioPlayer();
  Timer? _timer;

  int bpm = 120;
  bool isPlaying = false;
  int currentBeat = 0;

  // Nuevas variables de compás
  int beatsPerMeasure = 4; // Numerador (4, 6, 12)
  int noteValue = 4; // Denominador (4, 8)

  MetronomeLogic() {
    _initAudio();
  }

  void _initAudio() async {
    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );

    try {
      await _playerAccent.setSource(AssetSource('audio/click_normal.wav'));
      await _playerNormal.setSource(AssetSource('audio/click_normal.wav'));
      _playerAccent.setReleaseMode(ReleaseMode.stop);
      _playerNormal.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint("Error cargando audios: $e");
    }
  }

  void toggle(Function onTick) {
    isPlaying = !isPlaying;
    if (isPlaying) {
      _startLoop(onTick);
    } else {
      _timer?.cancel();
      currentBeat = 0;
      onTick(); // Para limpiar la UI al detener
    }
  }

  void _startLoop(Function onTick) {
    _timer?.cancel();
    currentBeat = 0;

    // Si es /8, el pulso es el doble de rápido (corchea)
    double multiplier = (noteValue == 8) ? 0.5 : 1.0;
    final int intervalMs = ((60000 / bpm) * multiplier).round();

    int nextTick = DateTime.now().millisecondsSinceEpoch;

    _timer = Timer.periodic(const Duration(milliseconds: 1), (t) {
      int now = DateTime.now().millisecondsSinceEpoch;

      if (now >= nextTick) {
        _playBeat();
        onTick(); // Notifica a la UI para animar

        currentBeat = (currentBeat + 1) % beatsPerMeasure;
        nextTick += intervalMs;
      }
    });
  }

  void _playBeat() {
    if (currentBeat == 0) {
      _playerAccent.seek(Duration.zero);
      _playerAccent.resume();
    } else {
      _playerNormal.seek(Duration.zero);
      _playerNormal.resume();
    }
  }

  void updateBpm(int newBpm, Function onTick) {
    bpm = newBpm;
    if (isPlaying) {
      _startLoop(onTick); // Reinicia el timer con la nueva velocidad
    }
  }

  void updateSignature(int beats, int value, Function onTick) {
    beatsPerMeasure = beats;
    noteValue = value;
    if (isPlaying) {
      _startLoop(onTick); // Reinicia el timer con la nueva métrica
    }
  }
}
