class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String sender; // 'user' or 'bot'
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      chatId: json['chatId'] ?? '',
      sender: json['sender'] ?? 'user',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chatId': chatId,
      'sender': sender,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SendMessageResponse {
  final bool success;
  final ChatMessage userMessage;
  final ChatMessage botMessage;

  SendMessageResponse({
    required this.success,
    required this.userMessage,
    required this.botMessage,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendMessageResponse(
      success: json['success'] ?? false,
      userMessage: ChatMessage.fromJson(json['userMessage']),
      botMessage: ChatMessage.fromJson(json['botMessage']),
    );
  }
}