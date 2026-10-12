import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_exception.dart';
import '../models/app_user.dart';

/// Email/password authentication backed by Firebase Auth. Creates the
/// traveller's profile document on sign-up.
class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AppException(_message(e));
    }
  }

  Future<void> signUp({required String name, required String email, required String phone, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(name.trim());
      final profile = AppUser(uid: uid, name: name.trim(), email: email.trim(), phone: phone.trim());
      await _firestore.collection('users').doc(uid).set({...profile.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    } on FirebaseAuthException catch (e) {
      throw AppException(_message(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException(_message(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  static String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Try logging in.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a minute and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this app yet.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
