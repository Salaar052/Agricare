import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/community_chat/community_chat_api.dart';
import '../../controllers/auth_controller.dart';
import 'admin_chat_room_detail_screen.dart';

class AdminChatMonitorScreen extends StatefulWidget {
  const AdminChatMonitorScreen({super.key});

  @override
  State<AdminChatMonitorScreen> createState() => _AdminChatMonitorScreenState();
}

class _AdminChatMonitorScreenState extends State<AdminChatMonitorScreen> {
  final ChatApiService _chatApi = ChatApiService();
  final AuthController _authController = Get.find<AuthController>();
  bool _loading = true;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _chatApi.setToken(_authController.token.value);
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _loading = true);
    try {
      final rooms = await _chatApi.adminGetAllRooms();
      if (!mounted) return;
      setState(() => _rooms = rooms);
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Error',
        'Failed to load chat groups: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = const Color(0xFF1F3D22);
    return Scaffold(
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
        title: const Text('Admin Chat Monitor'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRooms,
              child: _rooms.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No chat groups found')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                      itemCount: _rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        final roomId = room['_id']?.toString() ?? '';
                        final roomName =
                            room['name']?.toString() ?? 'Unnamed Group';
                        final memberCount = room['memberCount']?.toString() ?? '0';
                        final adminUser =
                            room['adminUser'] as Map<String, dynamic>?;
                        final createdBy =
                            adminUser?['username']?.toString() ?? 'Unknown';

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD2E5CC)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3E6D25).withOpacity(0.10),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF4E5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  roomName.isNotEmpty ? roomName[0].toUpperCase() : 'G',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              roomName,
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              'Members: $memberCount\nCreated by: $createdBy',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: roomId.isEmpty
                                ? null
                                : () async {
                                    await Get.to(
                                      () => AdminChatRoomDetailScreen(
                                        roomId: roomId,
                                        roomName: roomName,
                                      ),
                                      transition: Transition.rightToLeftWithFade,
                                      duration: const Duration(milliseconds: 320),
                                    );
                                    await _loadRooms();
                                  },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
