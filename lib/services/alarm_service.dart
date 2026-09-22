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
  DateTime? _startedAt;

  bool get isPlaying => _isPlaying;
  static const Duration maxPlayDuration = Duration(seconds: 10);

  /// درخواست دسترسی خواندن فایل صوتی
  Future<bool> requestAudioPermission() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.audio.isGranted) return true;
    final result = await Permission.audio.request();
    return result.isGranted;
  }

  Future<void> playSystemRingtone() async {
    await _play(() async {
      await FlutterRingtonePlayer().playAlarm(
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    });
  }

  Future<void> playCustomFile(String filePath) async {
    final ok = await requestAudioPermission();
    if (!ok) return;

    await _play(() async {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(DeviceFileSource(filePath));
    });
  }

  Future<void> _play(Future<void> Function() start) async {
    if (_isPlaying) await stop();
    _isPlaying = true;
    _startedAt = DateTime.now();

    try {
      await start();
    } catch (_) {
      _isPlaying = false;
      return;
    }

    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(maxPlayDuration, () {
      if (_isPlaying) stop();
    });
  }

  Future<void> stop() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _isPlaying = false;
    _startedAt = null;
    try {
      await FlutterRingtonePlayer().stop();
    } catch (_) {}
    try {
      await _player.stop();
    } catch (_) {}
  }

  Duration? get playedDuration {
    if (_startedAt == null) return null;
    return DateTime.now().difference(_startedAt!);
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}