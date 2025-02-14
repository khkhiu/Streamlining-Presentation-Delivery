// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/avatar_service.dart';
import 'services/chat_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AvatarService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
      ],
      child: const AvatarChatApp(),
    ),
  );
}

class AvatarChatApp extends StatelessWidget {
  const AvatarChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talking Avatar Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}