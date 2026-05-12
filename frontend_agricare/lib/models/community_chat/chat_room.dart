class ChatRoom {
  final String id;
  final String name;
  final String? image;
  final String admin;
  final List<String> members;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.name,
    this.image,
    required this.admin,
    required this.members,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      admin: json['admin'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      memberCount: json['memberCount'] ?? 0,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'image': image,
      'admin': admin,
      'members': members,
      'memberCount': memberCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Message {
  final String id;
  final String roomId;
  final String sender;
  final String senderName; // ✅ NEW FIELD
  final String? message;
  final String? fileUrl;
  final List<String> readBy;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.roomId,
    required this.sender,
    required this.senderName, // ✅ NEW FIELD
    this.message,
    this.fileUrl,
    required this.readBy,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      sender: json['sender'] is Map
          ? (json['sender']['_id'] ?? json['sender']['id'] ?? '')
          : (json['sender'] ?? ''),

      senderName: json['sender'] is Map
          ? (json['sender']['username'] ?? '')
          : (json['senderName'] ?? ''), // ✅ NEW FIELD HANDLING

      message: json['message'],
      fileUrl: json['fileUrl'],
      readBy: List<String>.from(json['readBy'] ?? []),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'sender': sender,
      'senderName': senderName, // ✅ NEW FIELD
      'message': message,
      'fileUrl': fileUrl,
      'readBy': readBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
