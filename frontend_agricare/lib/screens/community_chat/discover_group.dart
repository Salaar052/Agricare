import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/community_chat/chat_controller.dart';
import '../../controllers/auth_controller.dart';

class DiscoverGroupsScreen extends StatefulWidget {
  const DiscoverGroupsScreen({super.key});

  @override
  State<DiscoverGroupsScreen> createState() => _DiscoverGroupsScreenState();
}

class _DiscoverGroupsScreenState extends State<DiscoverGroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _chatController.fetchAllRooms();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _chatController.fetchAllRooms();
    } else {
      _chatController.searchRooms(query);
    }
  }

  Future<void> _toggleJoin(room) async {
    final isMember = room.members.contains(_authController.userId.value);

    if (isMember) {
      final success = await _chatController.leaveRoom(room.id);
      if (success) {
        _chatController.fetchAllRooms();
        _chatController.fetchMyRooms();
      }
    } else {
      final success = await _chatController.joinRoom(room.id);
      if (success) {
        _chatController.fetchAllRooms();
        _chatController.fetchMyRooms();
      }
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Discover Groups',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D5016),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search for groups...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF4A7C2C)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Color(0xFFF5F9F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Groups List
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingRooms.value) {
                return Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A7C2C)),
                );
              }

              if (_chatController.allRooms.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F9F3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.search_off,
                              size: 64, color: Color(0xFF4A7C2C)),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'No groups found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D5016),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _chatController.fetchAllRooms(),
                color: Color(0xFF4A7C2C),
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _chatController.allRooms.length,
                  itemBuilder: (context, index) {
                    final room = _chatController.allRooms[index];
                    final isMember = room.members.contains(
                      _authController.userId.value,
                    );
                    return _buildGroupCard(room, isMember);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(room, bool isMember) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Group Image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Color(0xFFF5F9F3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: room.image != null && room.image!.isNotEmpty
                    ? Image.network(
                        room.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.group,
                              color: Color(0xFF4A7C2C), size: 32);
                        },
                      )
                    : Icon(Icons.group, color: Color(0xFF4A7C2C), size: 32),
              ),
            ),
            SizedBox(width: 16),

            // Group Info
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
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        '${room.memberCount} members',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: 12),

            // Join Button
            ElevatedButton(
              onPressed: () => _toggleJoin(room),
              style: ElevatedButton.styleFrom(
                backgroundColor: isMember
                    ? Colors.grey[100]
                    : Color(0xFF4A7C2C),
                foregroundColor: isMember
                    ? Colors.grey[700]
                    : Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMember) ...[
                    Icon(Icons.check, size: 16),
                    SizedBox(width: 4),
                  ],
                  Text(
                    isMember ? 'Joined' : 'Join',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}