// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../services/avatar_service.dart';
import '../services/chat_service.dart';
import '../widgets/avatar_view.dart';
import '../widgets/chat_input.dart';
import '../widgets/configuration_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isConfigVisible = true;

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talking Avatar Chat'),
        actions: [
          IconButton(
            icon: Icon(_isConfigVisible ? Icons.settings_off : Icons.settings),
            onPressed: () => setState(() => _isConfigVisible = !_isConfigVisible),
          ),
        ],
      ),
      body: Row(
        children: [
          if (_isConfigVisible)
            const SizedBox(
              width: 300,
              child: ConfigurationPanel(),
            ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: AvatarView(renderer: _remoteRenderer),
                ),
                const ChatInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}