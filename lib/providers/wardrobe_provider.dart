import 'dart:io';
import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

class WardrobeProvider extends ChangeNotifier {
  List<WardrobeItem> _items = [];
  bool _loading = false;
  String? _error;

  List<WardrobeItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadWardrobe(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await ApiService.getWardrobe(userId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> addItem({
    required int userId,
    required String category,
    required String color,
    required String formality,
    String? name,
    String? fabric,
    File? imageFile,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final item = await ApiService.addWardrobeItem(
        userId: userId,
        category: category,
        color: color,
        formality: formality,
        name: name,
        fabric: fabric,
        imageFile: imageFile,
      );
      _items.insert(0, item);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final raw = e.toString().replaceAll('Exception: ', '');
      _error = raw.contains('SocketException') ||
              raw.contains('SocketConnection')
          ? 'Cannot reach backend server. Open Settings and set a reachable Backend URL.'
          : raw;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(int itemId) async {
    try {
      await ApiService.deleteWardrobeItem(itemId);
      _items.removeWhere((i) => i.id == itemId);
      notifyListeners();
      return true;
    } catch (e) {
      final raw = e.toString().replaceAll('Exception: ', '');
      _error = raw.contains('SocketException') ||
              raw.contains('SocketConnection')
          ? 'Cannot reach backend server. Open Settings and set a reachable Backend URL.'
          : raw;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem({
    required int itemId,
    String? name,
    required String category,
    required String color,
    String? fabric,
    required String formality,
  }) async {
    try {
      final updated = await ApiService.updateWardrobeItem(
        itemId: itemId,
        name: name,
        category: category,
        color: color,
        fabric: fabric,
        formality: formality,
      );
      final idx = _items.indexWhere((i) => i.id == itemId);
      if (idx >= 0) {
        _items[idx] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      final raw = e.toString().replaceAll('Exception: ', '');
      _error = raw.contains('SocketException') ||
              raw.contains('SocketConnection')
          ? 'Cannot reach backend server. Open Settings and set a reachable Backend URL.'
          : raw;
      notifyListeners();
      return false;
    }
  }
}
