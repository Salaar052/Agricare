import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final String sender; // sender ID
  final String senderName; // new field for display
  final String? message;
  final String? fileUrl;
  final bool isMe;
  final DateTime? timestamp;

  const MessageBubble({
    super.key,
    required this.sender,
    required this.senderName,
    this.message,
    this.fileUrl,
    required this.isMe,
    this.timestamp,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(time);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(time)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE h:mm a').format(time);
    } else {
      return DateFormat('MMM d, h:mm a').format(time);
    }
  }

  String _getSenderInitial(String name) {
    if (name.isEmpty) return 'U';
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFF5F9F3),
              child: Text(
                _getSenderInitial(senderName),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A7C2C),
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A7C2C),
                      ),
                    ),
                  ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? Color(0xFF4A7C2C) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMe ? 16 : 4),
                      topRight: Radius.circular(isMe ? 4 : 16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message != null && message!.isNotEmpty)
                        Text(
                          message!,
                          style: TextStyle(
                            fontSize: 15,
                            color: isMe ? Colors.white : Color(0xFF2D5016),
                            height: 1.4,
                          ),
                        ),
                      if (fileUrl != null && fileUrl!.isNotEmpty) ...[
                        if (message != null && message!.isNotEmpty)
                          SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            fileUrl!,
                            fit: BoxFit.cover,
                            width: 200,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.white.withOpacity(0.2)
                                      : Color(0xFFF5F9F3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_file,
                                      color: isMe
                                          ? Colors.white
                                          : Color(0xFF4A7C2C),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'File',
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Color(0xFF2D5016),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (timestamp != null)
                  Padding(
                    padding: EdgeInsets.only(
                      top: 4,
                      left: isMe ? 0 : 12,
                      right: isMe ? 12 : 0,
                    ),
                    child: Text(
                      _formatTime(timestamp),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          ),
          if (isMe) SizedBox(width: 8),
        ],
      ),
    );
  }
}
