import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/community_chat/chat_room.dart';

class ChatApiService {
  static const String baseUrl = 'http://10.209.229.141:5000/api/v1/chat';

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Room Management

  /// Create a new public room
  Future<ChatRoom> createRoom({required String name, File? image}) async {
    try {
      final uri = Uri.parse('$baseUrl/room');
      final request = http.MultipartRequest('POST', uri);

      request.fields['name'] = name;

      if (image != null) {
        if (kIsWeb) {
          // For web, add file from bytes
          final bytes = await image.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: 'group_image.jpg',
            ),
          );
        } else {
          // For mobile, add file from path
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              image.path,
              filename: image.path.split('/').last,
            ),
          );
        }
      }

      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatRoom.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create room: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating room: $e');
    }
  }

  /// Get all public rooms
  Future<List<ChatRoom>> getRooms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rooms'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChatRoom.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load rooms');
      }
    } catch (e) {
      throw Exception('Error fetching rooms: $e');
    }
  }

  /// Get rooms that the current user has joined
  Future<List<ChatRoom>> getMyRooms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-rooms'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChatRoom.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load my rooms');
      }
    } catch (e) {
      throw Exception('Error fetching my rooms: $e');
    }
  }

  /// Get room members
  Future<Map<String, dynamic>> getRoomMembers(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/room/$roomId/members'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get members: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching members: $e');
    }
  }

  /// Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/room/$roomId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete room: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting room: $e');
    }
  }

  /// Join a public room
  Future<ChatRoom> joinRoom(String roomId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/room/$roomId/join'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChatRoom.fromJson(data['room']);
      } else {
        throw Exception('Failed to join room: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error joining room: $e');
    }
  }

  /// Leave a room
  Future<void> leaveRoom(String roomId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/room/$roomId/leave'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to leave room: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error leaving room: $e');
    }
  }

  /// Search public rooms
  Future<List<ChatRoom>> searchRooms(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rooms/search?query=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChatRoom.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search rooms');
      }
    } catch (e) {
      throw Exception('Error searching rooms: $e');
    }
  }

  // Message Management

  /// Get messages from a room
  Future<List<Message>> getMessages(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$roomId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  /// Send a text message
  Future<Message> sendMessage({
    required String roomId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/message/$roomId'),
        headers: _headers,
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Message.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  /// Upload a file
  Future<Message> uploadFile({
    required String roomId,
    required File file,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/$roomId'),
      );

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'upload_file.jpg',
          ),
        );
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Message.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to upload file: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/message/$messageId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }

  /// Get unread message count
  Future<Map<String, dynamic>> getUnreadCount(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/unread/$roomId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get unread count');
      }
    } catch (e) {
      throw Exception('Error fetching unread count: $e');
    }
  }

  /// Mark all messages in a room as read
  Future<void> markAsRead(String roomId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/read/$roomId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark as read: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error marking as read: $e');
    }
  }
}
