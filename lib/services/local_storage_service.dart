import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../models/wardrobe_item_model.dart';
import '../models/body_profile_model.dart';
import '../models/outfit_model.dart';

class LocalStorageService {
  static Database? _database;
  static const String _dbName = 'fyt_database.db';
  static const int _dbVersion = 1;

  // Initialize database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, _dbName);
    
    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Wardrobe items table
    await db.execute('''
      CREATE TABLE wardrobe_items (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        color TEXT NOT NULL,
        pattern TEXT,
        fabric TEXT,
        seasons TEXT,
        occasionTags TEXT,
        notes TEXT,
        imagePath TEXT,
        isFavorite INTEGER DEFAULT 0,
        dateAdded TEXT NOT NULL
      )
    ''');

    // Body profiles table
    await db.execute('''
      CREATE TABLE body_profiles (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        shoulderWidth REAL,
        hipWidth REAL,
        torsoLength REAL,
        legLength REAL,
        armLength REAL,
        bodyType TEXT,
        analyzedAt TEXT NOT NULL
      )
    ''');

    // Outfits table
    await db.execute('''
      CREATE TABLE outfits (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT,
        occasion TEXT NOT NULL,
        weather TEXT,
        mood TEXT,
        colorPreference TEXT,
        items TEXT NOT NULL,
        score INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades if needed
  }

  // WARDROBE ITEM METHODS
  static Future<void> saveWardrobeItem(WardrobeItem item) async {
    final db = await database;
    await db.insert(
      'wardrobe_items',
      {
        'id': item.id,
        'userId': item.userId,
        'name': item.name,
        'category': item.category,
        'color': item.color,
        'pattern': item.pattern,
        'fabric': item.fabric,
        'seasons': jsonEncode(item.seasons),
        'occasionTags': jsonEncode(item.occasionTags),
        'notes': item.notes,
        'imagePath': item.imagePath,
        'isFavorite': item.isFavorite ? 1 : 0,
        'dateAdded': item.dateAdded.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<WardrobeItem>> getWardrobeItems(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wardrobe_items',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateAdded DESC',
    );

    return List.generate(maps.length, (i) {
      return WardrobeItem(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        name: maps[i]['name'],
        category: maps[i]['category'],
        color: maps[i]['color'],
        pattern: maps[i]['pattern'],
        fabric: maps[i]['fabric'],
        seasons: List<String>.from(jsonDecode(maps[i]['seasons'] ?? '[]')),
        occasionTags: List<String>.from(jsonDecode(maps[i]['occasionTags'] ?? '[]')),
        notes: maps[i]['notes'],
        imagePath: maps[i]['imagePath'],
        isFavorite: maps[i]['isFavorite'] == 1,
        dateAdded: DateTime.parse(maps[i]['dateAdded']),
      );
    });
  }

  static Future<void> deleteWardrobeItem(String userId, String itemId) async {
    final db = await database;
    await db.delete(
      'wardrobe_items',
      where: 'userId = ? AND id = ?',
      whereArgs: [userId, itemId],
    );
  }

  static Future<void> toggleFavorite(String userId, String itemId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'wardrobe_items',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'userId = ? AND id = ?',
      whereArgs: [userId, itemId],
    );
  }

  // BODY PROFILE METHODS
  static Future<void> saveBodyProfile(String userId, BodyProfile profile) async {
    final db = await database;
    
    // Delete existing profile for this user
    await db.delete(
      'body_profiles',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    
    // Insert new profile
    await db.insert(
      'body_profiles',
      {
        'id': profile.id,
        'userId': userId,
        'shoulderWidth': profile.shoulderWidth,
        'hipWidth': profile.hipWidth,
        'torsoLength': profile.torsoLength,
        'legLength': profile.legLength,
        'armLength': profile.armLength,
        'bodyType': profile.bodyType,
        'analyzedAt': profile.analyzedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<BodyProfile?> getBodyProfile(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'body_profiles',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'analyzedAt DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps[0];
    return BodyProfile(
      id: map['id'],
      shoulderWidth: map['shoulderWidth']?.toDouble(),
      hipWidth: map['hipWidth']?.toDouble(),
      torsoLength: map['torsoLength']?.toDouble(),
      legLength: map['legLength']?.toDouble(),
      armLength: map['armLength']?.toDouble(),
      bodyType: map['bodyType'],
      analyzedAt: DateTime.parse(map['analyzedAt']),
    );
  }

  // OUTFIT METHODS
  static Future<void> saveOutfit(Outfit outfit) async {
    final db = await database;
    await db.insert(
      'outfits',
      {
        'id': outfit.id,
        'userId': outfit.userId,
        'name': outfit.name,
        'occasion': outfit.occasion,
        'weather': outfit.weather,
        'mood': outfit.mood,
        'colorPreference': outfit.colorPreference,
        'items': jsonEncode(outfit.items),
        'score': outfit.score,
        'createdAt': outfit.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Outfit>> getOutfitsForOccasion(String userId, String occasion) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'outfits',
      where: 'userId = ? AND occasion = ?',
      whereArgs: [userId, occasion],
      orderBy: 'score DESC, createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Outfit(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        name: maps[i]['name'],
        occasion: maps[i]['occasion'],
        weather: maps[i]['weather'],
        mood: maps[i]['mood'],
        colorPreference: maps[i]['colorPreference'],
        items: List<String>.from(jsonDecode(maps[i]['items'])),
        score: maps[i]['score'],
        createdAt: DateTime.parse(maps[i]['createdAt']),
      );
    });
  }

  static Future<List<Outfit>> getAllOutfits(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'outfits',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Outfit(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        name: maps[i]['name'],
        occasion: maps[i]['occasion'],
        weather: maps[i]['weather'],
        mood: maps[i]['mood'],
        colorPreference: maps[i]['colorPreference'],
        items: List<String>.from(jsonDecode(maps[i]['items'])),
        score: maps[i]['score'],
        createdAt: DateTime.parse(maps[i]['createdAt']),
      );
    });
  }

  // IMAGE STORAGE METHODS
  static Future<String> saveImageToLocal(File imageFile, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesPath = path.join(directory.path, 'images');
    
    // Create images directory if it doesn't exist
    await Directory(imagesPath).create(recursive: true);
    
    final localImagePath = path.join(imagesPath, fileName);
    final savedImage = await imageFile.copy(localImagePath);
    
    return savedImage.path;
  }

  static Future<void> deleteLocalImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting local image: $e');
    }
  }

  // UTILITY METHODS
  static Future<int> getWardrobeItemCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM wardrobe_items WHERE userId = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<void> clearAllData(String userId) async {
    final db = await database;
    await db.delete('wardrobe_items', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('body_profiles', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('outfits', where: 'userId = ?', whereArgs: [userId]);
  }

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
