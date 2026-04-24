import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/community_chat/chat_controller.dart';
import '../../controllers/auth_controller.dart';

class ChatDashboard extends StatefulWidget {
  const ChatDashboard({super.key});

  @override
  State<ChatDashboard> createState() => _ChatDashboardState();
}

class _ChatDashboardState extends State<ChatDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _chatController.fetchMyRooms();
  }

  void _performSearch(String query) {
    setState(() {});
  }

  Future<void> _refreshRooms() async {
    await _chatController.fetchMyRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Community Chat',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D5016),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/create-group',
              ).then((_) => _refreshRooms());
            },
            icon: Icon(Icons.add_circle_outline, color: Color(0xFF4A7C2C)),
            tooltip: 'Create Group',
          ),
        ],
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
                hintText: 'Search groups...',
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

          // Discover Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/discover-groups',
                ).then((_) => _refreshRooms());
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Color(0xFF4A7C2C).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFF4A7C2C).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore, color: Color(0xFF4A7C2C), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Discover New Groups',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A7C2C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // My Groups List
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingMyRooms.value) {
                return Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A7C2C)),
                );
              }

              if (_chatController.myRooms.isEmpty) {
                return _buildEmptyState();
              }

              final filteredRooms = _chatController.myRooms.where((room) {
                if (_searchController.text.isEmpty) return true;
                return room.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                );
              }).toList();

              if (filteredRooms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      SizedBox(height: 16),
                      Text(
                        'No groups found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshRooms,
                color: Color(0xFF4A7C2C),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredRooms.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[200], indent: 88),
                  itemBuilder: (context, index) {
                    return _buildGroupListItem(filteredRooms[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupListItem(room) {
    return FutureBuilder<int>(
      future: _chatController.getUnreadCount(room.id),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return InkWell(
          onTap: () {
            _chatController.setCurrentRoom(room);
            Navigator.pushNamed(
              context,
              '/group-chat',
              arguments: {'room': room},
            ).then((_) => _refreshRooms());
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                // Group Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFF5F9F3),
                      backgroundImage:
                          room.image != null && room.image!.isNotEmpty
                          ? NetworkImage(room.image!)
                          : null,
                      child: room.image == null || room.image!.isEmpty
                          ? Icon(
                              Icons.group,
                              color: Color(0xFF4A7C2C),
                              size: 28,
                            )
                          : null,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color(0xFF4A7C2C),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12),

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
                      SizedBox(height: 4),
                      Text(
                        '${room.memberCount} members',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
              child: Icon(
                Icons.forum_outlined,
                size: 64,
                color: Color(0xFF4A7C2C),
              ),
            ),
            SizedBox(height: 24),
            Text(
              "You haven't joined any groups yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D5016),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Discover a group to get started and connect\nwith the community',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/discover-groups',
                ).then((_) => _refreshRooms());
              },
              icon: Icon(Icons.explore),
              label: Text('Explore Communities'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A7C2C),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
