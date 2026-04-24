import 'package:flutter/material.dart';

class AIMessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isUser;

  const AIMessageBubble({super.key, required this.sender, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? Color(0xFF4A7C2C) : Color(0xFFF5F9F3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Color(0xFF333333),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
