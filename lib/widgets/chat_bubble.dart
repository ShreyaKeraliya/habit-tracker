import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTime;
  
  const ChatBubble({
    Key? key,
    required this.message,
    this.showTime = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[600],
              ),
            ),
          ),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          decoration: BoxDecoration(
            color: isUser
                ? theme.primaryColor
                : theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16.0).copyWith(
              bottomRight: isUser ? const Radius.circular(0) : null,
              bottomLeft: !isUser ? const Radius.circular(0) : null,
            ),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 1),
                blurRadius: 2.0,
                color: Colors.black.withOpacity(0.1),
              ),
            ],
          ),
          child: _buildMessageContent(context),
        ),
      ],
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return SelectableText(
      message.text,
      style: TextStyle(
        color: message.isUser ? Colors.white : null,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );
    
    if (messageDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(timestamp)}';
    } else if (messageDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(timestamp)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}
