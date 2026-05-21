import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:io';

import '../../controllers/community_chat/chat_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/message_bubble.dart';
import '../../models/community_chat/chat_room.dart';
import '../../api/api_config.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();

  IO.Socket? socket;
  ChatRoom? room;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments ?? Get.arguments;

    if (args is Map) {
      final r = args['room'];
      if (r is ChatRoom) {
        room = r;
        _loadInitialData();
        connectSocket();
        return;
      }
      print("❌ Invalid room data passed");
    } else {
      print("❌ No room data passed");
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).maybePop();
    });
  }

  Future<void> _loadInitialData() async {
    final currentRoom = room;
    if (currentRoom == null) return;

    await _chatController.fetchMessages(currentRoom.id);
    _chatController.markMessagesAsRead(currentRoom.id);
    _scrollToBottom(force: true);
  }

  void connectSocket() {
    socket = IO.io(ApiConfig.socketBase, {
      "transports": ["websocket"],
      "autoConnect": true,
    });

    socket!.onConnect((_) {
      print('✅ Socket connected');
      final currentRoom = room;
      if (currentRoom != null) {
        socket!.emit("joinRoom", currentRoom.id);
      }
    });

    socket!.on("newMessage", (data) {
      if (data is! Map) return;
      final raw = Map<String, dynamic>.from(data);
      final newMessage = Message.fromJson(raw);

      // Avoid duplicates: REST upload already adds once; socket may use a
      // different id shape than the HTTP response, so also match file + sender.
      final exists = _chatController.messages.any((m) {
        if (m.id.isNotEmpty &&
            newMessage.id.isNotEmpty &&
            m.id == newMessage.id) {
          return true;
        }
        final u = m.fileUrl;
        final v = newMessage.fileUrl;
        if (u != null &&
            v != null &&
            u == v &&
            m.sender == newMessage.sender) {
          return true;
        }
        return false;
      });
      if (!exists) {
        _chatController.messages.add(newMessage);
        _scrollToBottom();
      }
    });

    socket!.on("messageDeleted", (data) {
      _chatController.messages.removeWhere((m) => m.id == data['messageId']);
    });

    socket!.onDisconnect((_) => print('❌ Socket disconnected'));
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final currentRoom = room;
    if (currentRoom == null) return;

    final messageText = _messageController.text.trim();

    socket!.emit("sendMessage", {
      "roomId": currentRoom.id,
      "sender": _authController.userId.value,
      "message": messageText,
    });

    _messageController.clear();
  }

  void _scrollToBottom({bool force = false}) {
    void doScroll() {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (force) {
        _scrollController.jumpTo(max);
      } else {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => doScroll());
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) doScroll();
    });
  }

  Future<void> _pickImage() async {
    final currentRoom = room;
    if (currentRoom == null) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final name = image.name.isNotEmpty ? image.name : 'image.jpg';
        final success =
            await _chatController.uploadFileBytes(currentRoom.id, bytes, filename: name);
        if (success) _scrollToBottom();
        return;
      }

      File? file = File(image.path);

      final success = await _chatController.uploadFile(currentRoom.id, file);
      if (success) _scrollToBottom();
    }
  }

  void _showMessageOptions(Message message) {
    final currentRoom = room;
    if (currentRoom == null) return;

    final isMyMessage = message.sender == _authController.userId.value;
    final isCreator = currentRoom.admin == _authController.userId.value;

    if (!isMyMessage && !isCreator) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text("Delete Message"),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteMessage(message.id);
            },
          ),
        );
      },
    );
  }

  void _confirmDeleteMessage(String messageId) {
    final currentRoom = room;
    if (currentRoom == null) return;

    _chatController.messages.removeWhere((m) => m.id == messageId);

    socket?.emit(
      "deleteMessage",
      {"roomId": currentRoom.id, "messageId": messageId},
    );

    _chatController.deleteMessage(messageId);
  }

  @override
  void dispose() {
    socket?.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _chatController.clearCurrentRoom();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final currentRoom = room;
    return Scaffold(
      appBar: AppBar(
        title: Text(currentRoom?.name ?? 'Group Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            socket?.disconnect();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingMessages.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_chatController.messages.isEmpty) {
                return const Center(child: Text("No messages yet"));
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount: _chatController.messages.length,
                itemBuilder: (context, index) {
                  final message = _chatController.messages[index];
                  final isMe = message.sender == _authController.userId.value;

                  return GestureDetector(
                    onLongPress: () => _showMessageOptions(message),
                    child: MessageBubble(
                      sender: message.sender,
                      senderName: message.senderName,
                      message: message.message,
                      fileUrl: message.fileUrl,
                      isMe: isMe,
                      timestamp: message.createdAt,
                    ),
                  );
                },
              );
            }),
          ),

          // INPUT
          Row(
            children: [
              Obx(() {
                final uploading = _chatController.isSendingMessage.value;
                return IconButton(
                  tooltip: uploading ? "Uploading…" : "Send image",
                  icon: uploading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.image_outlined),
                  onPressed: uploading ? null : _pickImage,
                );
              }),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(hintText: "Type a message"),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ],
      ),
    );
  }
}
