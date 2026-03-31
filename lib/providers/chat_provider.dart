import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMsg> _messages = [];
  bool _loading = false;
  List<String> _suggestions = ['Why this outfit?', 'Make it casual', 'Style tips'];

  List<ChatMsg> get messages => _messages;
  bool get loading => _loading;
  List<String> get suggestions => _suggestions;

  Future<void> loadHistory(int userId) async {
    try {
      final history = await ApiService.getChatHistory(userId);
      _messages.clear();
      for (final h in history) {
        _messages.add(ChatMsg(
          role: h['role'],
          message: h['message'],
        ));
      }
      notifyListeners();
    } catch (_) {
      // Silently fail — history is optional
    }
  }

  Future<void> sendMessage(int userId, String message,
      {Map<String, dynamic>? context}) async {
    // Add user message
    _messages.add(ChatMsg(role: 'user', message: message));
    _loading = true;
    notifyListeners();

    try {
      final response = await ApiService.sendChatMessage(
        userId: userId,
        message: message,
        context: context,
      );

      _messages.add(ChatMsg(
        role: 'assistant',
        message: response.response,
        intent: response.intent,
        suggestions: response.suggestions,
      ));
      _suggestions = response.suggestions;
    } catch (e) {
      _messages.add(ChatMsg(
        role: 'assistant',
        message: 'Sorry, I couldn\'t process that. Please try again.',
      ));
    }

    _loading = false;
    notifyListeners();
  }

  void clear() {
    _messages.clear();
    _suggestions = ['Why this outfit?', 'Make it casual', 'Style tips'];
    notifyListeners();
  }
}
