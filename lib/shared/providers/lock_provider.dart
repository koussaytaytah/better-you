import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'data_provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LockState {
  final String? lockedApp;
  final String? quest;

  LockState({this.lockedApp, this.quest});
}

class LockNotifier extends StateNotifier<LockState> {
  final Ref ref;
  LockNotifier(this.ref) : super(LockState());

  void setLock(String pkg, String quest) {
    state = LockState(lockedApp: pkg, quest: quest);
  }

  void unlock() {
    state = LockState();
  }

  Future<void> unlockWithBonus(int bonusMinutes) async {
    final pkg = state.lockedApp;
    if (pkg == null) return;

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final currentLimit = user.appLimits[pkg]?['limit'] ?? 0;
      final quest = user.appLimits[pkg]?['quest'] ?? 'Complete your quest';

      final updatedLimits = Map<String, dynamic>.from(user.appLimits);
      updatedLimits[pkg] = {
        'limit': currentLimit + bonusMinutes,
        'quest': quest,
      };

      // Save to SharedPreferences for Background Service
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_limits', json.encode(updatedLimits));

      // Also clear the locked status for this app
      final statusJson = prefs.getString('locked_apps_status') ?? '{}';
      final Map<String, dynamic> status = json.decode(statusJson);
      status.remove(pkg);
      await prefs.setString('locked_apps_status', json.encode(status));

      // Notify background service
      FlutterBackgroundService().invoke('updateLimits', updatedLimits);

      // Update Firestore
      await ref.read(userRepositoryProvider).updateUserProfile(user.uid, {
        'appLimits': updatedLimits,
      });
    }

    state = LockState();
  }
}

final lockProvider = StateNotifierProvider<LockNotifier, LockState>((ref) {
  return LockNotifier(ref);
});
