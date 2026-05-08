import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Lightweight UI sound effects.
///
/// Sound files should live under `assets/sounds/` and be declared in
/// `pubspec.yaml`. If a file is missing, calls fail silently so the UI
/// never breaks.
///
/// Usage:
///   await SoundService().init();
///   SoundService().play(AppSound.messageSent);
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;
  bool _initialized = false;

  static const _prefsKey = 'sound_effects_enabled';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefsKey) ?? true;
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      AppLogger.e('SoundService init failed', e);
    }
  }

  bool get enabled => _enabled;

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (e) {
      AppLogger.e('Failed to save sound preference', e);
    }
  }

  /// Play a UI sound. Silently no-ops if disabled or asset missing.
  Future<void> play(AppSound sound) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(sound.assetPath), volume: sound.volume);
    } on PlatformException catch (_) {
      // Asset not bundled yet — fail quietly.
    } catch (e) {
      AppLogger.e('SoundService play(${sound.name}) failed', e);
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

enum AppSound {
  messageSent('sounds/message_sent.mp3', 0.6),
  messageReceived('sounds/message_received.mp3', 0.7),
  tap('sounds/tap.mp3', 0.4),
  success('sounds/success.mp3', 0.7),
  error('sounds/error.mp3', 0.6),
  xpGained('sounds/xp_gained.mp3', 0.7),
  levelUp('sounds/level_up.mp3', 0.9),
  achievement('sounds/achievement.mp3', 0.9),
  streak('sounds/streak.mp3', 0.8);

  final String assetPath;
  final double volume;
  const AppSound(this.assetPath, this.volume);
}
