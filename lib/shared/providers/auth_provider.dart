import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Async User Provider (Internal)
final currentUserAsyncProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserModel?>>((ref) {
      return CurrentUserNotifier(ref.watch(authServiceProvider));
    });

// Sync User Provider (For backward compatibility)
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(currentUserAsyncProvider).value;
});

class CurrentUserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  StreamSubscription? _authSub;

  CurrentUserNotifier(this._authService) : super(const AsyncValue.loading()) {
    _authSub = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _loadCurrentUser();
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final user = await _authService.getCurrentUser().timeout(
        const Duration(seconds: 15),
      );
      if (mounted) {
        state = AsyncValue.data(user);
      }
    } catch (e, stack) {
      AppLogger.e('Error loading user', e, stack);
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> refreshUser() async {
    await _loadCurrentUser();
  }

  Future<void> updateUser(UserModel user) async {
    await _authService.updateUserProfile(user);
    state = AsyncValue.data(user);
  }

  void setUser(UserModel user) {
    state = AsyncValue.data(user);
  }
}
