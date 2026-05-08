import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== GOOGLE SIGN IN ====================
  
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserInFirestore(userCredential.user!, 'google');
      }

      AppLogger.i('Google sign-in successful: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e, stack) {
      AppLogger.e('Google sign-in error', e, stack);
      throw _handleAuthError(e);
    }
  }

  // ==================== FACEBOOK SIGN IN ====================
  
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        return null;
      }

      if (result.status == LoginStatus.failed) {
        throw Exception(result.message ?? 'Facebook login failed');
      }

      // Get the access token
      final AccessToken? accessToken = result.accessToken;

      if (accessToken == null) {
        throw Exception('Failed to get Facebook access token');
      }

      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(accessToken.token);

      // Sign in to Firebase with the Facebook credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(facebookAuthCredential);

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserInFirestore(userCredential.user!, 'facebook');
      }

      AppLogger.i('Facebook sign-in successful: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e, stack) {
      AppLogger.e('Facebook sign-in error', e, stack);
      throw _handleAuthError(e);
    }
  }

  // ==================== HELPER METHODS ====================
  
  Future<void> _createUserInFirestore(User user, String provider) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      
      // Check if user already exists
      final doc = await userRef.get();
      if (doc.exists) {
        return;
      }

      // Create new user document
      await userRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? 'User',
        'photoUrl': user.photoURL ?? '',
        'role': 'initial',
        'provider': provider,
        'hasCompletedOnboarding': false,
        'verificationStatus': 'pending',
        'xp': 0,
        'level': 1,
        'badges': [],
        'createdAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'lastActive': FieldValue.serverTimestamp(),
      });

      AppLogger.i('New user created in Firestore: ${user.uid}');
    } catch (e, stack) {
      AppLogger.e('Error creating user in Firestore', e, stack);
      rethrow;
    }
  }

  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email address but different sign-in credentials.';
        case 'invalid-credential':
          return 'The credential is malformed or has expired.';
        case 'operation-not-allowed':
          return 'This operation is not allowed. Please enable the sign-in method in Firebase Console.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No user found for this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'invalid-verification-code':
          return 'The verification code is invalid.';
        case 'invalid-verification-id':
          return 'The verification ID is invalid.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Check if user needs to select a role
  Future<bool> needsRoleSelection(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return true;
      
      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] as String?;
      return role == null || role == 'initial';
    } catch (e) {
      AppLogger.e('Error checking role selection status', e);
      return true;
    }
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>;
      return data['hasCompletedOnboarding'] ?? false;
    } catch (e) {
      AppLogger.e('Error checking onboarding status', e);
      return false;
    }
  }
}
