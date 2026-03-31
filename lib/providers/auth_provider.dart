import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService, [FirestoreService? firestoreService]) 
      : _firestoreService = firestoreService ?? FirestoreService() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        _loadUserModel(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Sign up
  Future<void> signUp(String email, String password, String name) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signUpWithEmail(email, password, name);
    } on FirebaseException catch (e) {
      _setError(_getFirebaseErrorMessage(e));
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Sign in
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signInWithEmail(email, password);
    } on FirebaseException catch (e) {
      _setError(_getFirebaseErrorMessage(e));
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signOut();
    } on FirebaseException catch (e) {
      _setError(_getFirebaseErrorMessage(e));
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.resetPassword(email);
    } on FirebaseException catch (e) {
      _setError(_getFirebaseErrorMessage(e));
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update display name
  Future<void> updateDisplayName(String name) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.updateDisplayName(name);
      if (_userModel != null) {
        _userModel = _userModel!.copyWith(displayName: name);
      }
    } on FirebaseException catch (e) {
      _setError(_getFirebaseErrorMessage(e));
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.updatePassword(newPassword);
    } on FirebaseException catch (e) {
      _setError(_getFirebaseErrorMessage(e));
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.deleteAccount();
    } on FirebaseException catch (e) {
      _setError(_getFirebaseErrorMessage(e));
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load user model from Firestore
  Future<void> _loadUserModel(String uid) async {
    try {
      _userModel = await _firestoreService.getUser(uid);
      notifyListeners();
    } on FirebaseException catch (e) {
      _setError('Failed to load user profile: ${e.message}');
    } catch (e) {
      _setError('Failed to load user profile: ${e.toString()}');
    }
  }

  // Update user model
  void updateUserModel(UserModel userModel) {
    _userModel = userModel;
    notifyListeners();
  }

  // Get user-friendly Firebase error message
  String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
