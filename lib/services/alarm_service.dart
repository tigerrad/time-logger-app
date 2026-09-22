import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Future<bool> requestAudioPermission() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.audio.isGranted) return true;
    final result = await Permission.audio.request();
    return result.isGranted;
  }

  Future<void> playSystemRingtone() async {
    await _stopInternal();
    _isPlaying = true;

    try {
      await _channel.invokeMethod('playAlarm');
    } catch (e) {
      print('Alarm error: $e');
      _isPlaying = false;
      return;
    }

    _startAutoStop();
  }

  Future<void> playCustomFile(String filePath) async {
    final ok = await requestAudioPermission();
    if (!ok) return;

    await _stopInternal();
    _isPlaying = true;

    try {
      await _channel.invokeMethod('playCustom', {'path': filePath});
    } catch (e) {
      print('Custom error: $e');
      _isPlaying = false;
      return;
    }

    _startAutoStop();
  }

  void _startAutoStop() {
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(maxPlayDuration, () {
      if (_isPlaying) {
        stop();
      }
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