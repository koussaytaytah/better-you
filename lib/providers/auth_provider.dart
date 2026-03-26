import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current User Provider
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
      return CurrentUserNotifier(ref.watch(authServiceProvider));
    });

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;

  CurrentUserNotifier(this._authService) : super(null) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    state = await _authService.getCurrentUser();
  }

  Future<void> updateUser(UserModel user) async {
    await _authService.updateUserProfile(user);
    state = user;
  }

  void setUser(UserModel user) {
    state = user;
  }
}
