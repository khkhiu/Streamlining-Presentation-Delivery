import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/basic_demo_screen.dart';
import 'screens/chat_demo_screen.dart';
import 'services/avatar_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AvatarService()),
      ],
      child: const TalkingAvatarApp(),
    ),
  );
}

class TalkingAvatarApp extends StatelessWidget {
  const TalkingAvatarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talking Avatar Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/basic': (context) => const BasicDemoScreen(),
        '/chat': (context) => const ChatDemoScreen(),
      },
    );
  }
}