import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/avatar_service.dart';
import '../widgets/avatar_video_view.dart';
import '../widgets/chat_history.dart';
import '../widgets/configuration_panel.dart';

class ChatDemoScreen extends StatefulWidget {
  const ChatDemoScreen({super.key});

  @override
  State<ChatDemoScreen> createState() => _ChatDemoScreenState();
}

class _ChatDemoScreenState extends State<ChatDemoScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showConfig = true;
  bool _isRecording = false;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<AvatarService>().fetchConfig()
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Start speaking if not already in a session
      if (!context.read<AvatarService>().isSessionActive) {
        await context.read<AvatarService>().startSession();
      }

      // Send message to avatar
      await context.read<AvatarService>().speak(message);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleMicrophone() async {
    setState(() => _isRecording = !_isRecording);
    if (_isRecording) {
      // Start recording logic here
    } else {
      // Stop recording logic here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Avatar'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AvatarService>(
        builder: (context, avatarService, child) {
          return Column(
            children: [
              if (_showConfig)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConfigurationPanel(
                      onConfigSubmitted: () {
                        setState(() => _showConfig = false);
                      },
                    ),
                  ),
                ),
              
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    // Left side - Avatar Video
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: AvatarVideoView(
                              stream: avatarService.remoteStream,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Video controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: avatarService.isSessionActive
                                    ? null
                                    : () => avatarService.startSession(),
                                child: const Text('Start Session'),
                              ),
                              ElevatedButton(
                                onPressed: !avatarService.isSessionActive
                                    ? null
                                    : () => avatarService.stopSession(),
                                child: const Text('Stop Session'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Right side - Chat Interface
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Chat history
                            Expanded(
                              child: ChatHistory(
                                messages: _messages,
                                scrollController: _scrollController,
                              ),
                            ),
                            
                            // Message input
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: _toggleMicrophone,
                                    icon: Icon(
                                      _isRecording ? Icons.mic_off : Icons.mic,
                                      color: _isRecording ? Colors.red : null,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      decoration: const InputDecoration(
                                        hintText: 'Type your message...',
                                        border: OutlineInputBorder(),
                                      ),
                                      onSubmitted: (_) => _handleSendMessage(),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _handleSendMessage,
                                    icon: const Icon(Icons.send),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _showConfig = !_showConfig);
        },
        child: Icon(_showConfig ? Icons.visibility_off : Icons.visibility),
      ),
    );
  }
}