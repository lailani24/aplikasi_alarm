import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  Timer? _vibrateTimer;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  // ─── Simpan preferensi alarm ke SharedPreferences ───────────────────────────
  static Future<void> saveAlarmPrefs({
    required String soundPath,
    required int challengeCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_sound', soundPath);
    await prefs.setInt('alarm_challenge_count', challengeCount);
  }

  static Future<String> getSavedSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('alarm_sound') ?? 'sound1.mp3';
  }

  static Future<int> getSavedChallengeCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('alarm_challenge_count') ?? 3;
  }

  // ─── Jadwalkan alarm via package alarm ──────────────────────────────────────
  static Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String soundFileName,
    required int challengeCount,
  }) async {
    await saveAlarmPrefs(
        soundPath: soundFileName, challengeCount: challengeCount);

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: 'assets/sounds/$soundFileName',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 5),
      ),
      notificationSettings: NotificationSettings(
        title: 'GetUp! ⏰',
        body: 'Alarm berbunyi! Selesaikan misi untuk mematikan.',
        stopButton: 'Stop',
        icon: 'notification_icon',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  static Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }

  // ─── Cek apakah ada alarm yang sedang berbunyi (async) ───────────────────────
  static Future<bool> isAlarmRinging() async {
    final alarms = await Alarm.getAlarms();
    return alarms.isNotEmpty;
  }

  // ─── Mulai getaran periodik saat alarm screen tampil ────────────────────────
  Future<void> startVibration() async {
    if (_isPlaying) return;
    _isPlaying = true;

    bool? canVibrate = await Vibration.hasVibrator();
    if (canVibrate == true) {
      Vibration.vibrate(duration: 1200);
      _vibrateTimer =
          Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (_isPlaying) {
          Vibration.vibrate(duration: 1000);
        } else {
          timer.cancel();
        }
      });
    }
  }

  // ─── Stop semua: suara (package alarm) + getaran ────────────────────────────
  Future<void> stopAlarm({int? alarmId}) async {
    _isPlaying = false;

    _vibrateTimer?.cancel();
    _vibrateTimer = null;

    try {
      Vibration.cancel();
    } catch (_) {}

    try {
      if (alarmId != null) {
        await Alarm.stop(alarmId);
      } else {
        // Stop semua alarm yang aktif
        final activeAlarms = await Alarm.getAlarms();
        for (final a in activeAlarms) {
          await Alarm.stop(a.id);
        }
      }
    } catch (e) {
      debugPrint('Gagal menghentikan alarm: $e');
    }
  }
}