import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/wardrobe_item_model.dart';

class MistralService {
  static const String _baseUrl = 'https://api.mistral.ai/v1/chat/completions';
  static const String _model = 'mistral-large-latest';
  
  // System prompt for FYT AI stylist
  static const String _systemPrompt = '''You are FYT, an elite personal fashion stylist AI. You give specific, personalized, actionable fashion advice. You know the user's body type, wardrobe, and style preferences. Be warm, confident, and fashion-forward. Keep responses concise (max 3-4 sentences) but impactful.''';

  // Chat with AI stylist
  static Future<String> chat({
    required String userMessage,
    required List<Map<String, String>> history,
    String? bodyType,
    String? stylePreference,
    List<String>? wardrobeContext,
  }) async {
    try {
      // Build messages array
      List<Map<String, String>> messages = [
        {'role': 'system', 'content': _buildContextualSystemPrompt(bodyType, stylePreference, wardrobeContext)}
      ];
      
      // Add history (last 10 messages)
      messages.addAll(history.take(10));
      
      // Add current message
      messages.add({'role': 'user', 'content': userMessage});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.mistralApiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw 'API Error: ${response.statusCode}';
      }
    } catch (e) {
      developer.log('Mistral API Error: $e');
      return 'Sorry, I\'m having trouble connecting right now. Please try again.';
    }
  }

  // Get styling advice (simplified version for chat)
  static Future<String> getStylingAdvice(
    String userMessage, {
    String? userBodyType,
    List<String>? wardrobeContext,
  }) async {
    const systemPrompt = """You are FYT, an expert AI fashion stylist. 
Give concise, practical, personalized fashion advice. 
Keep responses under 100 words. Be warm and encouraging.""";

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.mistralApiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userMessage}
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw 'API Error: ${response.statusCode}';
      }
    } catch (e) {
      developer.log('Mistral API Error: $e');
      rethrow; // Let caller handle the fallback
    }
  }

  // Analyze outfit compatibility
  static Future<Map<String, dynamic>> analyzeOutfitCompatibility({
    required List<WardrobeItem> items,
    required String occasion,
    String? bodyType,
  }) async {
    try {
      // Build outfit description for analysis
      String outfitDescription = _buildOutfitDescription(items, occasion, bodyType);
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.mistralApiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a fashion expert. Analyze outfit compatibility and provide a score (0-100), reasoning, and styling tips. Consider occasion, body type, color harmony, and style coordination. Return JSON format: {"score": 85, "reasoning": "Great color coordination", "tips": ["tip1", "tip2", "tip3"]}'''
            },
            {
              'role': 'user',
              'content': outfitDescription
            }
          ],
          'max_tokens': 300,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'];
        
        // Try to parse JSON response
        try {
          Map<String, dynamic> result = jsonDecode(content);
          return {
            'score': result['score'] ?? 75,
            'reasoning': result['reasoning'] ?? 'Good outfit choice',
            'tips': List<String>.from(result['tips'] ?? ['Looks great!']),
          };
        } catch (e) {
          // Fallback if JSON parsing fails
          return {
            'score': 80,
            'reasoning': content,
            'tips': ['Great combination!', 'Perfect for the occasion'],
          };
        }
      } else {
        throw 'API Error: ${response.statusCode}';
      }
    } catch (e) {
      developer.log('Outfit Analysis Error: $e');
      return {
        'score': 70,
        'reasoning': 'Unable to analyze outfit',
        'tips': ['Looks good!', 'Have confidence in your choice'],
      };
    }
  }

  // Build contextual system prompt
  static String _buildContextualSystemPrompt(String? bodyType, String? stylePreference, List<String>? wardrobeContext) {
    String contextPrompt = _systemPrompt;
    
    if (bodyType != null) {
      contextPrompt += '\n\nUser Body Type: $bodyType';
    }
    
    if (stylePreference != null) {
      contextPrompt += '\n\nUser Style Preference: $stylePreference';
    }
    
    if (wardrobeContext != null && wardrobeContext.isNotEmpty) {
      contextPrompt += '\n\nUser Wardrobe Items: ${wardrobeContext.take(20).join(', ')}';
    }
    
    return contextPrompt;
  }

  // Build outfit description for analysis
  static String _buildOutfitDescription(List<WardrobeItem> items, String occasion, String? bodyType) {
    List<String> itemDescriptions = items.map((item) => 
      '${item.name} (${item.category}, ${item.color}, ${item.styleVibe ?? item.occasionTags.join(', ')})'
    ).toList();
    
    String description = 'Analyze this outfit for $occasion occasion:\n';
    description += itemDescriptions.join('\n');
    
    if (bodyType != null) {
      description += '\n\nUser Body Type: $bodyType';
    }
    
    description += '\n\nProvide compatibility score and styling advice.';
    
    return description;
  }
}
