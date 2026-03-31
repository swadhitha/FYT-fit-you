import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';

/// Centralized API service for all backend communication.
class ApiService {
  static const String _prefCustomBaseUrl = 'api_custom_base_url';
  static String? _runtimeBaseUrl;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _runtimeBaseUrl = prefs.getString(_prefCustomBaseUrl);
  }

  static Future<void> setCustomBaseUrl(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeUrl(value);
    _runtimeBaseUrl = normalized;
    if (normalized == null) {
      await prefs.remove(_prefCustomBaseUrl);
    } else {
      await prefs.setString(_prefCustomBaseUrl, normalized);
    }
  }

  static String? get customBaseUrl => _runtimeBaseUrl;

  static String? _normalizeUrl(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (_runtimeBaseUrl != null && _runtimeBaseUrl!.isNotEmpty) {
      return _runtimeBaseUrl!;
    }
    if (Platform.isAndroid) {
      // Android emulator host loopback to local machine.
      return 'http://10.0.2.2:8000';
    }
    // iOS simulator local backend.
    return 'http://127.0.0.1:8000';
  }

  static String _extractError(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['detail'] != null) {
        return body['detail'].toString();
      }
    } catch (_) {
      // Non-JSON error body
    }
    return fallback;
  }

  // ─── Users ───────────────────────────────────────────────

  static Future<User> register({
    required String name,
    required String email,
    required String password,
    String stylePreference = 'Minimal',
    String climateRegion = 'Tropical',
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/users/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'style_preference': stylePreference,
            'climate_region': climateRegion,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Registration failed'));
    }
    return User.fromJson(jsonDecode(response.body));
  }

  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/users/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Login failed'));
    }
    return User.fromJson(jsonDecode(response.body));
  }

  static Future<User> getUser(int userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/users/$userId'))
        .timeout(const Duration(seconds: 20));
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
    final response = await http
        .post(
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
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Analysis failed'));
    }
    return BodyProfile.fromJson(jsonDecode(response.body));
  }

  static Future<BodyProfile?> getBodyProfile(int userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/body-profile/$userId'))
        .timeout(const Duration(seconds: 20));
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
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Scan failed'));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<BodyProfile> saveBodyProfileFromScan({
    required int userId,
    required Map<String, dynamic> scanResult,
    double estimatedHeightCm = 170.0,
    double estimatedWeightKg = 68.0,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/body-profile/$userId/scan-save'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'metrics': scanResult['metrics'] ?? {},
            'body_type': scanResult['body_type'] ?? 'rectangle',
            'symmetry': scanResult['symmetry'] ?? 0.0,
            'posture_angle': scanResult['posture_angle'] ?? 0.0,
            'estimated_height_cm': estimatedHeightCm,
            'estimated_weight_kg': estimatedWeightKg,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
          _extractError(response, 'Failed to save scanned profile'));
    }
    return BodyProfile.fromJson(jsonDecode(response.body));
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
      throw Exception(_extractError(response, 'Failed to add item'));
    }
    return WardrobeItem.fromJson(jsonDecode(response.body));
  }

  static Future<List<WardrobeItem>> getWardrobe(int userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/wardrobe/$userId'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Failed to get wardrobe');
    final list = jsonDecode(response.body) as List;
    return list.map((j) => WardrobeItem.fromJson(j)).toList();
  }

  static Future<void> deleteWardrobeItem(int itemId) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/api/wardrobe/item/$itemId'))
        .timeout(const Duration(seconds: 20));
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
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/recommendations/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'occasion': occasion,
            'mood': mood,
            'climate': climate,
            'additional_notes': additionalNotes,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Recommendation failed'));
    }
    return RecommendationResponse.fromJson(jsonDecode(response.body));
  }

  // ─── Chat ───────────────────────────────────────────────

  static Future<ChatApiResponse> sendChatMessage({
    required int userId,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/chat/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': message,
            'context': context,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception(_extractError(response, 'Chat failed'));
    }
    return ChatApiResponse.fromJson(jsonDecode(response.body));
  }

  static Future<List<Map<String, dynamic>>> getChatHistory(int userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/chat/$userId/history'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Failed to get history');
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }
}
