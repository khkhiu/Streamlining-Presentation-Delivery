// lib/services/chat_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatService extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse('http://your-server/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'query': message,
        'config': {/* Configuration */},
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      _messages.add(ChatMessage(
        text: responseData['response'],
        isUser: false,
      ));
      notifyListeners();
    }
  }
}
