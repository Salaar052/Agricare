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
  late dynamic room;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    room = args['room'];

    _loadInitialData();
    connectSocket();
  }

  Future<void> _loadInitialData() async {
    await _chatController.fetchMessages(room.id);
    _chatController.markMessagesAsRead(room.id);
    _scrollToBottom();
  }

  void connectSocket() {
    socket = IO.io("http://10.209.229.141:5000", {
      "transports": ["websocket"],
      "autoConnect": true,
    });

    socket!.onConnect((_) {
      print('✅ Socket connected');
      socket!.emit("joinRoom", room.id);
    });

    socket!.on("newMessage", (data) {
      print('📨 New message received: $data');
      final newMessage = Message(
        id: data['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        roomId: data['roomId'] ?? '',
        sender: data['sender'] ?? '',
        senderName: data['senderName'] ?? '', // ✅ ADD THIS
        message: data['message'],
        fileUrl: data['fileUrl'],
        readBy: List<String>.from(data['readBy'] ?? []),
        createdAt: DateTime.parse(
          data['createdAt'] ?? DateTime.now().toIso8601String(),
        ),
      );

      // Check if message already exists before adding
      if (!_chatController.messages.any((m) => m.id == newMessage.id)) {
        setState(() {
          _chatController.messages.add(newMessage);
        });
        _scrollToBottom();
      }
    });

    socket!.on("messageDeleted", (data) {
      print('🗑️ Message deleted: $data');
      setState(() {
        _chatController.messages.removeWhere((m) => m.id == data['messageId']);
      });
    });

    socket!.onDisconnect((_) => print('❌ Socket disconnected'));
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();

    // Create optimistic message
    final tempMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      roomId: room.id,
      sender: _authController.userId.value,
      senderName: _authController.username.value, // ✅ ADD THIS
      message: messageText,
      fileUrl: null,
      readBy: [_authController.userId.value],
      createdAt: DateTime.now(),
    );

    // Add to UI immediately
    setState(() {
      _chatController.messages.add(tempMessage);
    });

    // Emit via Socket.IO
    socket!.emit("sendMessage", {
      "roomId": room.id,
      "sender": _authController.userId.value,
      "message": messageText,
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      File? file;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        file = File.fromRawPath(bytes);
      } else {
        file = File(image.path);
      }

      final success = await _chatController.uploadFile(room.id, file);
      if (success) {
        _scrollToBottom();
      }
    }
  }

  void _showMessageOptions(Message message) {
    final isMyMessage = message.sender == _authController.userId.value;
    final isCreator = room.admin == _authController.userId.value;

    if (!isMyMessage && !isCreator) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
                title: Text(
                  'Delete Message',
                  style: TextStyle(color: Color(0xFFD32F2F)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMessage(message.id);
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Message',
          style: TextStyle(
            color: Color(0xFF2D5016),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this message?',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Remove from local list immediately
              setState(() {
                _chatController.messages.removeWhere((m) => m.id == messageId);
              });

              // Notify server via Socket.IO
              socket!.emit("deleteMessage", {
                "roomId": room.id,
                "messageId": messageId,
              });

              // Also call API to delete from database
              try {
                await _chatController.deleteMessage(messageId);
              } catch (e) {
                print('Error deleting message: $e');
              }
            },
            child: Text('Delete', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }

  void _showGroupOptions() {
    final isCreator = room.admin == _authController.userId.value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: Color(0xFF4A7C2C)),
                title: Text('Group Info'),
                onTap: () {
                  Navigator.pop(context);
                  _showGroupInfo();
                },
              ),
              ListTile(
                leading: Icon(Icons.people_outline, color: Color(0xFF4A7C2C)),
                title: Text('View Members (${room.memberCount})'),
                onTap: () {
                  Navigator.pop(context);
                  Get.snackbar(
                    'Members',
                    '${room.memberCount} members in this group',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Color(0xFF4A7C2C),
                    colorText: Colors.white,
                    margin: EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
              ),
              if (isCreator)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
                  title: Text(
                    'Delete Group',
                    style: TextStyle(color: Color(0xFFD32F2F)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteGroup();
                  },
                )
              else
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: Color(0xFFD32F2F)),
                  title: Text(
                    'Leave Group',
                    style: TextStyle(color: Color(0xFFD32F2F)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLeaveGroup();
                  },
                ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showGroupInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Group Info',
          style: TextStyle(
            color: Color(0xFF2D5016),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (room.image != null && room.image!.isNotEmpty)
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(room.image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 16),
            _buildInfoRow('Name', room.name),
            SizedBox(height: 8),
            _buildInfoRow('Members', '${room.memberCount}'),
            SizedBox(height: 8),
            _buildInfoRow('Created', _formatDate(room.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFF4A7C2C))),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D5016),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey[700])),
        ),
      ],
    );
  }

  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Group',
          style: TextStyle(
            color: Color(0xFF2D5016),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _chatController.deleteRoom(room.id);
              if (success) {
                Navigator.pop(context);
              }
            },
            child: Text('Delete', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Leave Group',
          style: TextStyle(
            color: Color(0xFF2D5016),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to leave this group?',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _chatController.leaveRoom(room.id);
              if (success) {
                Navigator.pop(context);
              }
            },
            child: Text('Leave', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2D5016)),
          onPressed: () {
            socket?.disconnect();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFF5F9F3),
              backgroundImage: room.image != null && room.image!.isNotEmpty
                  ? NetworkImage(room.image!)
                  : null,
              child: room.image == null || room.image!.isEmpty
                  ? Icon(Icons.group, color: Color(0xFF4A7C2C), size: 20)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D5016),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${room.memberCount} Members',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Color(0xFF2D5016)),
            onPressed: _showGroupOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingMessages.value) {
                return Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A7C2C)),
                );
              }

              if (_chatController.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F9F3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Color(0xFF4A7C2C),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D5016),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start the conversation!',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

          // Message Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F9F3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _pickImage,
                        icon: Icon(Icons.add, color: Color(0xFF4A7C2C)),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor: Color(0xFFF5F9F3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF4A7C2C),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: Icon(Icons.send, color: Colors.white, size: 20),
                        padding: EdgeInsets.all(10),
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socket?.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _chatController.clearCurrentRoom();
    super.dispose();
  }
}
