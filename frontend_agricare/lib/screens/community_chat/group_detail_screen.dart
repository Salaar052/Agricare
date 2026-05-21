import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/community_chat/chat_controller.dart';
import '../../models/community_chat/chat_room.dart';
import '../../routes/app_routes.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();

  ChatRoom? _room;
  bool _loading = true;
  bool _leaving = false;
  String? _error;
  String _creatorName = 'Loading…';
  List<Map<String, dynamic>> _members = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_room != null) return;

    final args = ModalRoute.of(context)?.settings.arguments ?? Get.arguments;
    if (args is Map && args['room'] is ChatRoom) {
      _room = args['room'] as ChatRoom;
      _loadMembers();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  Future<void> _loadMembers() async {
    final room = _room;
    if (room == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _chatController.getRoomMembersDetail(room.id);
      if (!mounted) return;
      setState(() {
        _creatorName = data['adminUsername'] ?? 'Unknown';
        _members = List<Map<String, dynamic>>.from(data['members'] ?? []);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _leaveGroup() async {
    final room = _room;
    if (room == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Leave "${room.name}"? You can rejoin from Discover Groups.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _leaving = true);
    final ok = await _chatController.leaveRoom(room.id);
    if (!mounted) return;
    setState(() => _leaving = false);

    if (ok) {
      Navigator.of(context).popUntil((route) => route.settings.name == AppRoutes.community || route.isFirst);
    }
  }

  void _openChat() {
    final room = _room;
    if (room == null) return;
    _chatController.setCurrentRoom(room);
    Navigator.pushNamed(
      context,
      AppRoutes.groupChat,
      arguments: {'room': room},
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final isCreator = room?.admin == _authController.userId.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2D5016),
        title: Text(
          room?.name ?? 'Group',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: room == null
          ? const Center(child: CircularProgressIndicator())
          : _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A7C2C)))
              : RefreshIndicator(
                  onRefresh: _loadMembers,
                  color: const Color(0xFF4A7C2C),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFFE8F5E9),
                          backgroundImage: room.image != null && room.image!.isNotEmpty
                              ? NetworkImage(room.image!)
                              : null,
                          child: room.image == null || room.image!.isEmpty
                              ? const Icon(Icons.group, size: 56, color: Color(0xFF4A7C2C))
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        room.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D5016),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Created by $_creatorName',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openChat,
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Open Group Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A7C2C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, color: Color(0xFF4A7C2C)),
                          const SizedBox(width: 8),
                          Text(
                            'Members (${_members.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D5016),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                      ..._members.map((m) {
                        final username = m['username']?.toString() ?? 'User';
                        final isAdmin = m['id']?.toString() == room.admin;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFF0FDF4),
                              backgroundImage: m['profileImage'] != null
                                  ? NetworkImage(m['profileImage'].toString())
                                  : null,
                              child: m['profileImage'] == null
                                  ? Text(
                                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Color(0xFF4A7C2C)),
                                    )
                                  : null,
                            ),
                            title: Text(username),
                            trailing: isAdmin
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A7C2C).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Creator',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4A7C2C),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      if (!isCreator)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _leaving ? null : _leaveGroup,
                            icon: _leaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.exit_to_app, color: Colors.red),
                            label: const Text(
                              'Leave Group',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
