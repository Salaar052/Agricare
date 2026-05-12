import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_chatbot/ai_chat_model.dart';
import 'api_config.dart';

class AIChatService {
  static String get baseUrl => ApiConfig.aiChatbotBase;

  // Get all chat sessions
  Future<List<ChatSession>> getAllChats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<ChatSession> chats = (data['chats'] as List)
              .map((chat) => ChatSession.fromJson(chat))
              .toList();
          return chats;
        } else {
          throw Exception(data['error'] ?? 'Failed to load chats');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load chats: $e');
    }
  }

  // Create a new chat
  Future<ChatSession> createChat(String title) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/new'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'title': title}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ChatSession.fromJson(data['chat']);
        } else {
          throw Exception(data['error'] ?? 'Failed to create chat');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Get messages for a specific chat
  Future<List<ChatMessage>> getMessages(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$chatId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<ChatMessage> messages = (data['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg))
              .toList();
          return messages;
        } else {
          throw Exception(data['error'] ?? 'Failed to load messages');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  // Send a message
  Future<SendMessageResponse> sendMessage(String chatId, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'chatId': chatId, 'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return SendMessageResponse.fromJson(data);
        } else {
          throw Exception(data['error'] ?? 'Failed to send message');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$chatId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Failed to delete chat');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }
}
