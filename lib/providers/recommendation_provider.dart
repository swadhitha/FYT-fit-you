import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

class RecommendationProvider extends ChangeNotifier {
  RecommendationResponse? _recommendation;
  bool _loading = false;
  String? _error;
  String? _selectedOccasion;
  String? _mood;
  String? _additionalNotes;

  RecommendationResponse? get recommendation => _recommendation;
  bool get loading => _loading;
  String? get error => _error;
  String? get selectedOccasion => _selectedOccasion;

  void setOccasion(String occasion) {
    _selectedOccasion = occasion;
    notifyListeners();
  }

  void setMood(String mood) {
    _mood = mood;
    notifyListeners();
  }

  void setAdditionalNotes(String notes) {
    _additionalNotes = notes;
    notifyListeners();
  }

  Future<void> fetchRecommendations(int userId) async {
    if (_selectedOccasion == null) {
      _error = 'Please select an occasion first';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _recommendation = await ApiService.getRecommendations(
        userId: userId,
        occasion: _selectedOccasion!,
        mood: _mood,
        climate: null, // Uses user's climate_region from profile
        additionalNotes: _additionalNotes,
      );
    } catch (e) {
      final raw = e.toString().replaceAll('Exception: ', '');
      _error = raw.contains('SocketException') ||
              raw.contains('SocketConnection')
          ? 'Cannot reach backend server. Open Settings and set a reachable Backend URL.'
          : raw;
    }

    _loading = false;
    notifyListeners();
  }

  void clear() {
    _recommendation = null;
    _selectedOccasion = null;
    _mood = null;
    _additionalNotes = null;
    notifyListeners();
  }
}
