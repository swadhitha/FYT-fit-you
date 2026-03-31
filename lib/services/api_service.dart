import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';

/// Centralized API service for all backend communication.
class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'http://192.0.0.2:8000'; // Physical device testing
  // static const String baseUrl = 'http://192.0.0.3:8000'; // Previous IP
  // static const String baseUrl = 'http://10.1.224.57:8000'; // Network IP

  // ─── Users ───────────────────────────────────────────────

  static Future<User> register({
    required String name,
    required String email,
    required String password,
    String stylePreference = 'Minimal',
    String climateRegion = 'Tropical',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'style_preference': stylePreference,
        'climate_region': climateRegion,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Registration failed');
    }
    return User.fromJson(jsonDecode(response.body));
  }

  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Login failed');
    }
    return User.fromJson(jsonDecode(response.body));
  }

  static Future<User> getUser(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/users/$userId'));
    if (response.statusCode != 200) throw Exception('User not found');
    return User.fromJson(jsonDecode(response.body));
  }

  // ─── Body Profile ───────────────────────────────────────

  static Future<BodyProfile> saveBodyProfile({
    required int userId,
    required double heightCm,
    required double weightKg,
    required double shoulderCm,
    required double chestCm,
    required double waistCm,
    required double hipCm,
    required double inseamCm,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/body-profile/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'shoulder_cm': shoulderCm,
        'chest_cm': chestCm,
        'waist_cm': waistCm,
        'hip_cm': hipCm,
        'inseam_cm': inseamCm,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Analysis failed');
    }
    return BodyProfile.fromJson(jsonDecode(response.body));
  }

  static Future<BodyProfile?> getBodyProfile(int userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/body-profile/$userId'));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw Exception('Failed to get profile');
    return BodyProfile.fromJson(jsonDecode(response.body));
  }

  static Future<Map<String, dynamic>> scanBody({
    required int userId,
    required File imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/body-profile/$userId/scan');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Scan failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Wardrobe ────────────────────────────────────────────

  static Future<WardrobeItem> addWardrobeItem({
    required int userId,
    required String category,
    required String color,
    required String formality,
    String? name,
    String? fabric,
    File? imageFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/wardrobe/$userId');
    final request = http.MultipartRequest('POST', uri);

    request.fields['category'] = category;
    request.fields['color'] = color;
    request.fields['formality'] = formality;
    if (name != null) request.fields['name'] = name;
    if (fabric != null) request.fields['fabric'] = fabric;

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to add item');
    }
    return WardrobeItem.fromJson(jsonDecode(response.body));
  }

  static Future<List<WardrobeItem>> getWardrobe(int userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/wardrobe/$userId'));
    if (response.statusCode != 200) throw Exception('Failed to get wardrobe');
    final list = jsonDecode(response.body) as List;
    return list.map((j) => WardrobeItem.fromJson(j)).toList();
  }

  static Future<void> deleteWardrobeItem(int itemId) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/api/wardrobe/item/$itemId'));
    if (response.statusCode != 200) throw Exception('Failed to delete item');
  }

  // ─── Recommendations ────────────────────────────────────

  static Future<RecommendationResponse> getRecommendations({
    required int userId,
    required String occasion,
    String? mood,
    String? climate,
    String? additionalNotes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/recommendations/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'occasion': occasion,
        'mood': mood,
        'climate': climate,
        'additional_notes': additionalNotes,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
          jsonDecode(response.body)['detail'] ?? 'Recommendation failed');
    }
    return RecommendationResponse.fromJson(jsonDecode(response.body));
  }

  // ─── Chat ───────────────────────────────────────────────

  static Future<ChatApiResponse> sendChatMessage({
    required int userId,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'context': context,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Chat failed');
    }
    return ChatApiResponse.fromJson(jsonDecode(response.body));
  }

  static Future<List<Map<String, dynamic>>> getChatHistory(int userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/chat/$userId/history'));
    if (response.statusCode != 200) throw Exception('Failed to get history');
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }
}
