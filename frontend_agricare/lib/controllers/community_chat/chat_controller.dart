import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/community_chat/community_chat_api.dart';
import '../../models/community_chat/chat_room.dart';
import '../auth_controller.dart';

class ChatController extends GetxController {
  final ChatApiService _chatApiService = ChatApiService();
  final AuthController _authController = Get.find<AuthController>();

  // Observable lists
  final RxList<ChatRoom> allRooms = <ChatRoom>[].obs;
  final RxList<ChatRoom> myRooms = <ChatRoom>[].obs;
  final RxList<Message> messages = <Message>[].obs;

  // Loading states
  final RxBool isLoadingRooms = false.obs;
  final RxBool isLoadingMyRooms = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSendingMessage = false.obs;

  // Current room
  final Rx<ChatRoom?> currentRoom = Rx<ChatRoom?>(null);

  @override
  void onInit() {
    super.onInit();
    _chatApiService.setToken(_authController.token.value);

    ever(_authController.token, (token) {
      if (token != null && token.isNotEmpty) {
        _chatApiService.setToken(token);
      }
    });
  }

  /// Fetch all public rooms
  Future<void> fetchAllRooms() async {
    try {
      isLoadingRooms.value = true;
      allRooms.value = await _chatApiService.getRooms();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load rooms: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFD32F2F).withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoadingRooms.value = false;
    }
  }

  /// Fetch rooms user has joined
  Future<void> fetchMyRooms() async {
    try {
      isLoadingMyRooms.value = true;
      myRooms.value = await _chatApiService.getMyRooms();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load your rooms: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFD32F2F).withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoadingMyRooms.value = false;
    }
  }

  /// Create a new room
  Future<bool> createRoom(String name, {File? image}) async {
    try {
      final room = await _chatApiService.createRoom(name: name, image: image);

      allRooms.insert(0, room);
      myRooms.insert(0, room);

      Get.snackbar(
        'Success',
        'Room created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFF4A7C2C),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create room: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFD32F2F).withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    }
  }

  /// Join a room
  Future<bool> joinRoom(String roomId) async {
    try {
      final room = await _chatApiService.joinRoom(roomId);

      final index = allRooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        allRooms[index] = room;
      }

      if (!myRooms.any((r) => r.id == roomId)) {
        myRooms.insert(0, room);
      }

      Get.snackbar(
        'Success',
        'Joined room successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFF4A7C2C),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to join room: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFD32F2F).withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    }
  }

  /// Leave a room
  Future<bool> leaveRoom(String roomId) async {
    try {
      await _chatApiService.leaveRoom(roomId);
      myRooms.removeWhere((r) => r.id == roomId);

      Get.snackbar(
        'Success',
        'Left room successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFF4A7C2C),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to leave room: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFD32F2F).withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    }
  }

  /// Delete a room (only creator can delete)
  Future<bool> deleteRoom(String roomId) async {
    try {
      await _chatApiService.deleteRoom(roomId);

      allRooms.removeWhere((r) => r.id == roomId);
      myRooms.removeWhere((r) => r.id == roomId);

      Get.snackbar(
        'Success',
        'Room deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFF4A7C2C),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete room: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFD32F2F).withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    }
  }

  /// Search rooms
  Future<void> searchRooms(String query) async {
    try {
      if (query.isEmpty) {
        await fetchAllRooms();
        return;
      }

      isLoadingRooms.value = true;
      allRooms.value = await _chatApiService.searchRooms(query);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Search failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFD32F2F).withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoadingRooms.value = false;
    }
  }

  /// Fetch messages for a room
  Future<void> fetchMessages(String roomId) async {
    try {
      isLoadingMessages.value = true;
      messages.value = await _chatApiService.getMessages(roomId);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load messages: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFD32F2F).withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoadingMessages.value = false;
    }
  }

  /// Send a text message
  Future<bool> sendMessage(String roomId, String messageText) async {
    try {
      isSendingMessage.value = true;

      final message = await _chatApiService.sendMessage(
        roomId: roomId,
        message: messageText,
      );

      messages.add(message);
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFD32F2F).withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Upload a file
  Future<bool> uploadFile(String roomId, File file) async {
    try {
      isSendingMessage.value = true;

      final message = await _chatApiService.uploadFile(
        roomId: roomId,
        file: file,
      );

      messages.add(message);

      Get.snackbar(
        'Success',
        'File uploaded successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFF4A7C2C),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFD32F2F).withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Delete a message - THIS IS THE MISSING METHOD
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _chatApiService.deleteMessage(messageId);
      messages.removeWhere((m) => m.id == messageId);

      Get.snackbar(
        'Success',
        'Message deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFF4A7C2C),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete message: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFD32F2F).withOpacity(0.9),
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String roomId) async {
    try {
      await _chatApiService.markAsRead(roomId);
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String roomId) async {
    try {
      final result = await _chatApiService.getUnreadCount(roomId);
      return result['unreadCount'] ?? 0;
    } catch (e) {
      print('Failed to get unread count: $e');
      return 0;
    }
  }

  /// Set current room
  void setCurrentRoom(ChatRoom room) {
    currentRoom.value = room;
    fetchMessages(room.id);
    markMessagesAsRead(room.id);
  }

  /// Clear current room
  void clearCurrentRoom() {
    currentRoom.value = null;
    messages.clear();
  }
}
