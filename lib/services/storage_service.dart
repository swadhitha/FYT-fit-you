import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageService {
  
  Future<String> uploadWardrobeImage(
      String userId, String itemId, File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final wardrobeDir = Directory('${appDir.path}/wardrobe/$userId');
    if (!await wardrobeDir.exists()) {
      await wardrobeDir.create(recursive: true);
    }
    final ext = path.extension(imageFile.path);
    final fileName = '${itemId}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = await imageFile.copy('${wardrobeDir.path}/$fileName');
    return savedFile.path;
  }

  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final profileDir = Directory('${appDir.path}/profiles');
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }
    final ext = path.extension(imageFile.path);
    final fileName = 'profile_${userId}$ext';
    final savedFile = await imageFile.copy('${profileDir.path}/$fileName');
    return savedFile.path;
  }

  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  Future<void> deleteWardrobeImage(String imagePath) async {
    await deleteFile(imagePath);
  }

  Future<String> uploadBodyScanImage(String userId, File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final bodyDir = Directory('${appDir.path}/body_scans/$userId');
    if (!await bodyDir.exists()) {
      await bodyDir.create(recursive: true);
    }
    final ext = path.extension(imageFile.path);
    final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = await imageFile.copy('${bodyDir.path}/$fileName');
    return savedFile.path;
  }
}
