import 'dart:async';
import 'package:flutter/services.dart';


enum AlarmType { sound, vibrate, both }
enum AlarmSoundSource { systemRingtone, customFile }

class AlarmService {
  static final AlarmService _instance = AlarmService._();
  factory AlarmService() => _instance;
  AlarmService._();

  static const _channel = MethodChannel('ir.kurosh.timelogger/alarm');

  Timer? _autoStopTimer;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;
  static const Duration maxPlayDuration = Duration(seconds: 10);

  Future<void> playSystemRingtone() async {
    await _stopInternal();
    _isPlaying = true;

    try {
      await _channel.invokeMethod('playAlarm');
    } catch (e) {
      _isPlaying = false;
      return;
    }

    _startAutoStop();
  }

  Future<void> playCustomFile(String filePath) async {
    await _stopInternal();
    _isPlaying = true;

    try {
      await _channel.invokeMethod('playCustom', {'path': filePath});
    } catch (e) {
      _isPlaying = false;
      return;
    }

    _startAutoStop();
  }

  void _startAutoStop() {
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(maxPlayDuration, () {
      if (_isPlaying) stop();
    });
  }

  Future<void> _stopInternal() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _isPlaying = false;
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }

  Future<void> stop() async {
    await _stopInternal();
  }

  Future<void> dispose() async {
    await stop();
  }
}