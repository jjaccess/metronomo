import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class MetronomeLogic {
  final AudioPlayer _playerAccent = AudioPlayer();
  final AudioPlayer _playerNormal = AudioPlayer();
  Timer? _timer;
  Timer? _tapTempoTimer;

  int bpm = 120;
  bool isPlaying = false;
  int currentBeat = 0;

  // Nuevas variables de compás
  int beatsPerMeasure = 4; // Numerador (4, 6, 12)
  int noteValue = 4; // Denominador (4, 8)

  // Variables para Tap Tempo
  final List<int> _tapTimes = []; // Timestamps de cada tap
  static const int _tapTimeoutMs = 3000; // Resetear si pasan 3s sin tap
  static const int _minTapsRequired = 2; // Mínimo 2 taps para calcular

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

  /// Registra un tap para cálculo de Tap Tempo
  void tapTempo(Function onBpmUpdated) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Si han pasado más de 3 segundos desde el último tap, resetear
    if (_tapTimes.isNotEmpty &&
        (now - _tapTimes.last) > _tapTimeoutMs) {
      _tapTimes.clear();
    }

    _tapTimes.add(now);

    // Esperar al menos 2 taps para calcular
    if (_tapTimes.length >= _minTapsRequired) {
      // Usar solo los últimos 4 taps para mayor precisión (3 intervalos)
      List<int> tapsToUse = _tapTimes.length > 4 
          ? _tapTimes.sublist(_tapTimes.length - 4) 
          : _tapTimes;

      // Calcular intervalos entre taps
      List<int> intervals = [];
      for (int i = 1; i < tapsToUse.length; i++) {
        intervals.add(tapsToUse[i] - tapsToUse[i - 1]);
      }

      // Promediar los intervalos
      int avgInterval = (intervals.reduce((a, b) => a + b) ~/ intervals.length);

      // Convertir intervalo (ms) a BPM: BPM = 60000 / intervalo_ms
      int newBpm = (60000 / avgInterval).round();

      // Limitar rango válido
      if (newBpm >= 40 && newBpm <= 240) {
        bpm = newBpm;
        // Si está tocando, reiniciar el loop con la nueva velocidad
        if (isPlaying) {
          _startLoop(onBpmUpdated);
        }
        // Actualizar UI siempre
        onBpmUpdated();
      }
    }

    // Resetear timer de timeout
    _tapTempoTimer?.cancel();
    _tapTempoTimer = Timer(const Duration(milliseconds: _tapTimeoutMs), () {
      _tapTimes.clear();
    });
  }

  /// Obtener la cantidad de taps registrados (para UI feedback)
  int getTapCount() => _tapTimes.length;
}
