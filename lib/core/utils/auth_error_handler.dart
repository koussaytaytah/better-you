import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  static String getFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email address is already registered. Please log in instead.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'invalid-email':
          return 'The email address is not valid. Please check your spelling.';
        case 'user-not-found':
          return 'No account exists for this email. Please check your spelling or register.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This login method is currently disabled.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'An unexpected error occurred: ${error.message ?? 'Please try again.'}';
      }
    }
    
    return error?.toString() ?? 'An unknown error occurred. Please try again.';
  }
}
