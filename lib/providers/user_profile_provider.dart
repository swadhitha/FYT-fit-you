import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/body_profile_model.dart';

class UserProfileProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  String? _error;

  UserProfileProvider(this._firestoreService);

  UserModel? _user;
  BodyProfile? _bodyProfile;
  bool _isLoading = false;

  // Getters
  UserModel? get user => _user;
  BodyProfile? get bodyProfile => _bodyProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user profile
  Future<void> loadProfile(String uid) async {
    _setLoading(true);
    _clearError();
    try {
      _user = await _firestoreService.getUser(uid);
      notifyListeners();
    } on FirebaseException catch (e) {
      _setError('Failed to load profile: ${e.message}');
    } catch (e) {
      _setError('Failed to load profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();
    try {
      await _firestoreService.updateUser(uid, data);
      if (_user != null) {
        // Update local user model with new data
        final updatedUser = _user!.copyWith(
          displayName: data['displayName'] ?? _user!.displayName,
          stylePreference: data['stylePreference'] ?? _user!.stylePreference,
          climate: data['climate'] ?? _user!.climate,
          preferredColors: data['preferredColors'] ?? _user!.preferredColors,
        );
        _user = updatedUser;
      }
      notifyListeners();
    } on FirebaseException catch (e) {
      _setError('Failed to update profile: ${e.message}');
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding(String uid) async {
    _setLoading(true);
    _clearError();
    try {
      await _firestoreService.updateUser(uid, {'onboardingComplete': true});
      if (_user != null) {
        _user = _user!.copyWith(onboardingComplete: true);
      }
      notifyListeners();
    } on FirebaseException catch (e) {
      _setError('Failed to complete onboarding: ${e.message}');
    } catch (e) {
      _setError('Failed to complete onboarding: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Save body profile
  Future<void> saveBodyProfile(String uid, BodyProfile profile) async {
    _setLoading(true);
    _clearError();
    try {
      await _firestoreService.saveBodyProfile(uid, profile);
      _bodyProfile = profile;
      notifyListeners();
    } on FirebaseException catch (e) {
      _setError('Failed to save body profile: ${e.message}');
    } catch (e) {
      _setError('Failed to save body profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load body profile
  Future<void> loadBodyProfile(String uid) async {
    _setLoading(true);
    _clearError();
    try {
      _bodyProfile = await _firestoreService.getBodyProfile(uid);
      notifyListeners();
    } on FirebaseException catch (e) {
      _setError('Failed to load body profile: ${e.message}');
    } catch (e) {
      _setError('Failed to load body profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update style preference
  Future<void> updateStylePreference(String uid, String stylePreference) async {
    await updateProfile(uid, {'stylePreference': stylePreference});
  }

  // Update climate preference
  Future<void> updateClimate(String uid, String climate) async {
    await updateProfile(uid, {'climate': climate});
  }

  // Update preferred colors
  Future<void> updatePreferredColors(String uid, List<String> colors) async {
    await updateProfile(uid, {'preferredColors': colors});
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

  // Set user directly (for auth state changes)
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // Clear profile
  void clearProfile() {
    _user = null;
    _bodyProfile = null;
    _error = null;
    notifyListeners();
  }
}
