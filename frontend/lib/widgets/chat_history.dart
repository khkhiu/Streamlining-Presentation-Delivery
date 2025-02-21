import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// This class represents a single chat message with its metadata
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageUrl,
  });
}

class ChatHistory extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  
  const ChatHistory({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // If there are no messages, show a helpful placeholder
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'Start a conversation with the avatar',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    // Build the chat history list with messages
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(context, message);
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    
    // Create the message content widget
    Widget content = Column(
      crossAxisAlignment: message.isUser 
          ? CrossAxisAlignment.end 
          : CrossAxisAlignment.start,
      children: [
        // Show the sender label
        Text(
          message.isUser ? 'You' : 'Avatar',
          style: TextStyle(
            color: theme.colorScheme.secondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        
        // Message bubble with text and optional image
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: message.isUser
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display message text
              Text(
                message.text,
                style: const TextStyle(fontSize: 16),
              ),
              // Display image if present
              if (message.imageUrl != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.imageUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Show timestamp
        Text(
          DateFormat('HH:mm').format(message.timestamp),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );

    // Wrap in Padding and align based on sender
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: message.isUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: content,
      ),
    );
  }
}