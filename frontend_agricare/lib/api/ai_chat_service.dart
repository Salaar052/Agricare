import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/ai_chatbot/ai_chat_model.dart';
import '../controllers/auth_controller.dart';
import 'api_config.dart';

class AIChatService {
  static String get baseUrl => ApiConfig.aiChatbotBase;

  final AuthController _auth = Get.find<AuthController>();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_auth.token.value.isNotEmpty)
          'Authorization': 'Bearer ${_auth.token.value}',
      };

  Future<List<ChatSession>> getAllChats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['chats'] as List)
              .map((chat) => ChatSession.fromJson(chat))
              .toList();
        }
        throw Exception(data['error'] ?? data['message'] ?? 'Failed to load chats');
      }
      if (response.statusCode == 401) {
        throw Exception('Please log in to use AI chat');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load chats: $e');
    }
  }

  Future<ChatSession> createChat(String title) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/new'),
        headers: _headers,
        body: json.encode({'title': title}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ChatSession.fromJson(data['chat']);
        }
        throw Exception(data['error'] ?? 'Failed to create chat');
      }
      if (response.statusCode == 401) {
        throw Exception('Please log in to use AI chat');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  Future<List<ChatMessage>> getMessages(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$chatId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg))
              .toList();
        }
        throw Exception(data['error'] ?? 'Failed to load messages');
      }
      if (response.statusCode == 403) {
        throw Exception('You do not have access to this chat');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  Future<SendMessageResponse> sendMessage(String chatId, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: _headers,
        body: json.encode({'chatId': chatId, 'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return SendMessageResponse.fromJson(data);
        }
        throw Exception(data['error'] ?? 'Failed to send message');
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$chatId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Failed to delete chat');
        }
        return;
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }
}
