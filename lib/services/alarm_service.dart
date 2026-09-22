import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:permission_handler/permission_handler.dart';

enum AlarmSoundSource { systemRingtone, customFile }

class AlarmService {
  static final AlarmService _instance = AlarmService._();
  factory AlarmService() => _instance;
  AlarmService._();

  final AudioPlayer _player = AudioPlayer();
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
    // ابتدا stop کن اگر پخش قبلی هست
    await stop();

    _isPlaying = true;

    try {
      await FlutterRingtonePlayer().playAlarm(
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
      print('Ringtone started');
    } catch (e) {
      print('Ringtone error: $e');
      _isPlaying = false;
      return;
    }

    // تایمر خودکار بعد از پخش شروع شود
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(maxPlayDuration, () {
      if (_isPlaying) {
        stop();
        print('Auto-stop fired');
      }
    });
  }

  Future<void> playCustomFile(String filePath) async {
    final ok = await requestAudioPermission();
    if (!ok) {
      print('Permission denied');
      return;
    }

    await stop();
    _isPlaying = true;

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(DeviceFileSource(filePath));
      print('Custom file started: $filePath');
    } catch (e) {
      print('Custom file error: $e');
      _isPlaying = false;
      return;
    }

    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(maxPlayDuration, () {
      if (_isPlaying) {
        stop();
        print('Auto-stop fired');
      }
    });
  }

  Future<void> stop() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _isPlaying = false;

    try {
      await FlutterRingtonePlayer().stop();
    } catch (_) {}
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}