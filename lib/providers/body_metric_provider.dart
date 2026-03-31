import 'dart:io';
import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

class BodyMetricProvider extends ChangeNotifier {
  BodyProfile? _profile;
  Map<String, dynamic>? _scanResult;
  bool _loading = false;
  String? _error;

  BodyProfile? get profile => _profile;
  Map<String, dynamic>? get scanResult => _scanResult;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadProfile(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await ApiService.getBodyProfile(userId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> scanBody(int userId, File imageFile) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _scanResult = await ApiService.scanBody(userId: userId, imageFile: imageFile);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveProfile({
    required int userId,
    required double heightCm,
    required double weightKg,
    required double shoulderCm,
    required double chestCm,
    required double waistCm,
    required double hipCm,
    required double inseamCm,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await ApiService.saveBodyProfile(
        userId: userId,
        heightCm: heightCm,
        weightKg: weightKg,
        shoulderCm: shoulderCm,
        chestCm: chestCm,
        waistCm: waistCm,
        hipCm: hipCm,
        inseamCm: inseamCm,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveProfileFromScan({
    required int userId,
    required Map<String, dynamic> scanResult,
    double targetHeightCm = 170.0,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final metrics = scanResult['metrics'] as Map<String, dynamic>;
      // Total vertical distance in normalized units (torso + leg)
      final totalVert = (metrics['torso_length'] as num).toDouble() +
          (metrics['leg_length'] as num).toDouble();
      
      // We assume targetHeight is the full height. 
      // Roughly, total body height is ~1.15 to 1.2 times the shoulder-to-ankle vertical distance.
      final scaleFactor = targetHeightCm / (totalVert * 1.15); // Adjusting for head/neck
      final shoulderCm = scaleFactor; // Since shoulder is 1.0 in normalized units
      
      final shoulderWidth = shoulderCm;
      final hipCm = (metrics['hip_width'] as num).toDouble() * shoulderWidth;
      final waistCm =
          (metrics['waist_ratio'] as num).toDouble() * shoulderWidth; // Heuristic
      final chestCm = (shoulderWidth + waistCm) / 2; // Heuristic
      final inseamCm =
          (metrics['leg_length'] as num).toDouble() * shoulderWidth;

      _profile = await ApiService.saveBodyProfile(
        userId: userId,
        heightCm: targetHeightCm,
        weightKg: 65, // Default placeholder
        shoulderCm: shoulderWidth,
        chestCm: chestCm,
        waistCm: waistCm,
        hipCm: hipCm,
        inseamCm: inseamCm,
      );
      
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
