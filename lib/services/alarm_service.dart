import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

enum AlarmSoundSource { systemRingtone, customFile }

class AlarmService {
  static final AlarmService _instance = AlarmService._();
  factory AlarmService() => _instance;
  AlarmService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// پخش زنگ پیش‌فرض گوشی
  Future<void> playSystemRingtone() async {
    _isPlaying = true;
    await FlutterRingtonePlayer().playAlarm(
      looping: true,
      volume: 1.0,
      asAlarm: true,
    );
  }

  /// پخش فایل صوتی دلخواه
  Future<void> playCustomFile(String filePath) async {
    _isPlaying = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);
    await _player.play(DeviceFileSource(filePath));
  }

  /// توقف پخش
  Future<void> stop() async {
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