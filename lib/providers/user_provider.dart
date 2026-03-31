import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  int get userId => _user?.id ?? 1;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String stylePreference = 'Minimal',
    String climateRegion = 'Tropical',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await ApiService.register(
        name: name,
        email: email,
        password: password,
        stylePreference: stylePreference,
        climateRegion: climateRegion,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await ApiService.login(email: email, password: password);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }

  void setDemoUser() {
    _user = User(id: 1, name: 'Demo User', email: 'demo@fyt.app');
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
