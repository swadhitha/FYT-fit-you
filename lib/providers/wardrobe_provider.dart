import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/wardrobe_item_model.dart';

class WardrobeProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  String? _error;

  WardrobeProvider(this._firestoreService, this._storageService);

  List<WardrobeItem> _items = [];
  String _selectedCategory = 'All';
  String _selectedOccasion = 'All';
  String _searchQuery = '';
  bool _isLoading = false;

  // Getters
  List<WardrobeItem> get items => _items;
  String get selectedCategory => _selectedCategory;
  String get selectedOccasion => _selectedOccasion;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed getter for filtered items
  List<WardrobeItem> get filteredItems {
    List<WardrobeItem> filtered = _items;

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }

    // Apply occasion filter
    if (_selectedOccasion != 'All') {
      filtered = filtered.where((item) => item.occasionTags.contains(_selectedOccasion)).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) => 
        item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.category.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  // Get items by occasion
  List<WardrobeItem> itemsByOccasion(String occasion) {
    return _items.where((item) => item.occasionTags.contains(occasion)).toList();
  }

  // Load wardrobe from Firestore
  Future<void> loadWardrobe(String uid) async {
    _setLoading(true);
    _clearError();
    try {
      _firestoreService.wardrobeStream(uid).listen((items) {
        _items = items;
        notifyListeners();
      });
    } on FirebaseException catch (e) {
      _setError('Failed to load wardrobe: ${e.message}');
    } catch (e) {
      _setError('Failed to load wardrobe: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Add new item
  Future<void> addItem(WardrobeItem item, String imageFile) async {
    _setLoading(true);
    _clearError();
    try {
      // Upload image if provided
      if (imageFile.isNotEmpty) {
        // In production, you'd convert the file path to File object
        // For now, use placeholder URL
        final updatedItem = item.copyWith(imagePath: '');
        await _firestoreService.addWardrobeItem(updatedItem);
      } else {
        await _firestoreService.addWardrobeItem(item);
      }
    } on FirebaseException catch (e) {
      _setError('Failed to add item: ${e.message}');
    } catch (e) {
      _setError('Failed to add item: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update existing item
  Future<void> updateItem(WardrobeItem item, {String? newImagePath}) async {
    _setLoading(true);
    _clearError();
    try {
      // Upload new image if provided
      if (newImagePath != null && newImagePath.isNotEmpty) {
        if (item.imagePath != null && item.imagePath!.isNotEmpty) {
          await _storageService.deleteWardrobeImage(item.imagePath!);
        }
        final newImageUrl = await _storageService.uploadWardrobeImage(item.userId, item.id, 
          // Convert to File object in production
          File(newImagePath));
        final updatedItem = item.copyWith(imagePath: newImageUrl);
        await _firestoreService.updateWardrobeItem(updatedItem);
      } else {
        await _firestoreService.updateWardrobeItem(item);
      }
    } on FirebaseException catch (e) {
      _setError('Failed to update item: ${e.message}');
    } catch (e) {
      _setError('Failed to update item: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Delete item
  Future<void> deleteItem(String uid, String itemId) async {
    _setLoading(true);
    _clearError();
    try {
      // Find the item to get its image path
      final item = _items.firstWhere((item) => item.id == itemId);
      if (item.imagePath != null && item.imagePath!.isNotEmpty) {
        await _storageService.deleteWardrobeImage(item.imagePath!);
      }
      await _firestoreService.deleteWardrobeItem(uid, itemId);
    } on FirebaseException catch (e) {
      _setError('Failed to delete item: ${e.message}');
    } catch (e) {
      _setError('Failed to delete item: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String uid, String itemId, bool isFavorite) async {
    _clearError();
    try {
      await _firestoreService.toggleFavorite(uid, itemId, isFavorite);
      
      // Update local item
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = _items[index].copyWith(isFavorite: isFavorite);
        notifyListeners();
      }
    } on FirebaseException catch (e) {
      _setError('Failed to update favorite status: ${e.message}');
    } catch (e) {
      _setError('Failed to update favorite status: ${e.toString()}');
    }
  }

  // Set category filter
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Set occasion filter
  void setOccasion(String occasion) {
    _selectedOccasion = occasion;
    notifyListeners();
  }

  // Set search query
  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedCategory = 'All';
    _selectedOccasion = 'All';
    _searchQuery = '';
    notifyListeners();
  }

  // Get stats
  Map<String, int> getStats() {
    final Map<String, int> categoryCount = {};
    for (final item in _items) {
      categoryCount[item.category] = (categoryCount[item.category] ?? 0) + 1;
    }
    return categoryCount;
  }

  // Get favorites count
  int get favoritesCount => _items.where((item) => item.isFavorite).length;

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
