import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/community_chat/community_chat_api.dart';
import '../../controllers/auth_controller.dart';
import '../../models/community_chat/chat_room.dart';
import '../../widgets/message_bubble.dart';

class AdminChatRoomDetailScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const AdminChatRoomDetailScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<AdminChatRoomDetailScreen> createState() =>
      _AdminChatRoomDetailScreenState();
}

class _AdminChatRoomDetailScreenState extends State<AdminChatRoomDetailScreen> {
  final ChatApiService _chatApi = ChatApiService();
  final AuthController _authController = Get.find<AuthController>();

  bool _loading = true;
  List<Message> _messages = [];
  List<Map<String, dynamic>> _members = [];
  String _groupAdminId = '';

  @override
  void initState() {
    super.initState();
    _chatApi.setToken(_authController.token.value);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final membersData = await _chatApi.adminGetRoomMembers(widget.roomId);
      final messages = await _chatApi.adminGetMessages(widget.roomId);
      if (!mounted) return;
      setState(() {
        _members = (membersData['members'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _groupAdminId = membersData['admin']?.toString() ?? '';
        _messages = messages;
      });
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Error',
        'Failed to load room details: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmRemoveMember(Map<String, dynamic> member) async {
    final memberId = member['_id']?.toString() ?? '';
    final username = member['username']?.toString() ?? 'Unknown';
    if (memberId.isEmpty) return;

    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Remove member'),
            content: Text('Remove $username from this group?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      await _chatApi.adminRemoveMember(widget.roomId, memberId);
      if (!mounted) return;
      await _loadData();
      Get.snackbar(
        'Success',
        'Member removed from group',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Error',
        'Failed to remove member: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F9F2),
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3E6D25), Color(0xFF5D8F3F)],
              ),
            ),
          ),
          title: Text(widget.roomName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Members'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _messages.isEmpty
                      ? const Center(child: Text('No messages in this group'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final msg = _messages[i];
                            return MessageBubble(
                              sender: msg.sender,
                              senderName: msg.senderName,
                              message: msg.message,
                              fileUrl: msg.fileUrl,
                              isMe: false,
                              timestamp: msg.createdAt,
                            );
                          },
                        ),
                  _members.isEmpty
                      ? const Center(child: Text('No members'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _members.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final member = _members[i];
                            final memberId = member['_id']?.toString() ?? '';
                            final username =
                                member['username']?.toString() ?? 'Unknown';
                            final email = member['email']?.toString() ?? '';
                            final isCreator = memberId == _groupAdminId;
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFD2E5CC)),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF4E5),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Center(
                                    child: Text(
                                      username.isNotEmpty
                                          ? username[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                                title: Text(username),
                                subtitle: Text(
                                  isCreator ? '$email\nGroup Creator' : email,
                                ),
                                isThreeLine: isCreator,
                                trailing: isCreator
                                    ? const SizedBox.shrink()
                                    : TextButton(
                                        onPressed: () => _confirmRemoveMember(member),
                                        child: const Text(
                                          'Remove',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                ],
              ),
      ),
    );
  }
}
