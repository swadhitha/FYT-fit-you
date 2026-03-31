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
      _error = e.toString().replaceAll('Exception: ', '');
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
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
