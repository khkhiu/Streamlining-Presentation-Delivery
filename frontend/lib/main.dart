// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatState(),
      child: const AvatarChatApp(),
    ),
  );
}

class AvatarChatApp extends StatelessWidget {
  const AvatarChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avatar Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatState extends ChangeNotifier {
  bool isConnected = false;
  bool isSpeaking = false;
  List<ChatMessage> messages = [];
  RTCPeerConnection? peerConnection;
  RTCVideoRenderer? remoteVideo;
  WebSocketChannel? webSocket;
  String? errorMessage;

  void addMessage(ChatMessage message) {
    messages.add(message);
    notifyListeners();
  }

  void setConnectionStatus(bool status) {
    isConnected = status;
    notifyListeners();
  }

  void setSpeakingStatus(bool status) {
    isSpeaking = status;
    notifyListeners();
  }

  void setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late final RTCVideoRenderer _remoteRenderer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _remoteRenderer = RTCVideoRenderer();
    _initializeWebRTC();
  }

  Future<void> _initializeWebRTC() async {
    try {
      await _remoteRenderer.initialize();
      final chatState = Provider.of<ChatState>(context, listen: false);
      chatState.remoteVideo = _remoteRenderer;
      
      await _setupWebRTCConnection();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('WebRTC initialization error: $e');
      Provider.of<ChatState>(context, listen: false).setError(e.toString());
    }
  }

  Future<void> _setupWebRTCConnection() async {
    try {
      final configuration = <String, dynamic>{
        'iceServers': [
          {
            'urls': [
              'stun:stun1.l.google.com:19302',
              'stun:stun2.l.google.com:19302'
            ]
          }
        ]
      };

      final peerConnection = await createPeerConnection(configuration);
      final chatState = Provider.of<ChatState>(context, listen: false);
      chatState.peerConnection = peerConnection;

      peerConnection.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video') {
          setState(() {
            _remoteRenderer.srcObject = event.streams[0];
          });
        }
      };

      // Ice candidate handling
      peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        final chatState = Provider.of<ChatState>(context, listen: false);
        chatState.webSocket?.sink.add(jsonEncode({
          'type': 'ice-candidate',
          'candidate': candidate.toMap(),
        }));
      };

      // Use secure WebSocket for production
      final wsUrl = Uri.parse('ws://localhost:8080/ws');  // Update with your backend URL
      final ws = WebSocketChannel.connect(wsUrl);
      chatState.webSocket = ws;

      ws.stream.listen(
        (message) => _handleWebSocketMessage(message),
        onError: (error) {
          print('WebSocket error: $error');
          chatState.setError(error.toString());
        },
        onDone: () => chatState.setConnectionStatus(false),
      );
      
      chatState.setConnectionStatus(true);
    } catch (e) {
      print('WebRTC setup error: $e');
      Provider.of<ChatState>(context, listen: false).setError(e.toString());
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      // Handle different message types
      switch (data['type']) {
        case 'ice-candidate':
          _handleIceCandidate(data);
          break;
        case 'offer':
          _handleOffer(data);
          break;
        case 'answer':
          _handleAnswer(data);
          break;
      }
    } catch (e) {
      print('WebSocket message handling error: $e');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    final chatState = Provider.of<ChatState>(context, listen: false);
    if (chatState.peerConnection != null) {
      try {
        await chatState.peerConnection!.addCandidate(
          RTCIceCandidate(
            data['candidate']['candidate'],
            data['candidate']['sdpMid'],
            data['candidate']['sdpMLineIndex'],
          ),
        );
      } catch (e) {
        print('Ice candidate error: $e');
      }
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    final chatState = Provider.of<ChatState>(context, listen: false);
    if (chatState.peerConnection != null) {
      try {
        await chatState.peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type']),
        );
        
        final answer = await chatState.peerConnection!.createAnswer();
        await chatState.peerConnection!.setLocalDescription(answer);
        
        chatState.webSocket?.sink.add(jsonEncode({
          'type': 'answer',
          'sdp': answer.sdp,
        }));
      } catch (e) {
        print('Offer handling error: $e');
      }
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    final chatState = Provider.of<ChatState>(context, listen: false);
    if (chatState.peerConnection != null) {
      try {
        await chatState.peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type']),
        );
      } catch (e) {
        print('Answer handling error: $e');
      }
    }
  }

  // Rest of the code remains the same...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Chat'),
        actions: [
          Consumer<ChatState>(
            builder: (context, chatState, child) {
              return IconButton(
                icon: Icon(chatState.isConnected ? Icons.cloud_done : Icons.cloud_off),
                onPressed: null,
              );
            },
          ),
        ],
      ),
      body: _isInitialized ? _buildChatInterface() : const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black,
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Consumer<ChatState>(
            builder: (context, chatState, child) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatState.messages[index];
                        return MessageBubble(message: message);
                      },
                    ),
                  ),
                  if (chatState.errorMessage != null)
                    ErrorBanner(message: chatState.errorMessage!),
                  _buildMessageInput(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatState = Provider.of<ChatState>(context, listen: false);
    
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/chat'),  // Update with your backend URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'sessionId': 'your-session-id',
        }),
      );

      if (response.statusCode == 200) {
        chatState.addMessage(ChatMessage(
          text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ));
        _messageController.clear();
      } else {
        chatState.setError('Failed to send message');
      }
    } catch (e) {
      chatState.setError(e.toString());
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _remoteRenderer.dispose();
    final chatState = Provider.of<ChatState>(context, listen: false);
    chatState.webSocket?.sink.close();
    if (chatState.peerConnection != null) {
      chatState.peerConnection!.close();
      chatState.peerConnection = null;
    }
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black,
              ),
            ),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: message.isUser ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.red[100],
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Provider.of<ChatState>(context, listen: false).setError(null);
            },
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}