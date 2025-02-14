// lib/services/avatar_service.dart
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class AvatarService extends ChangeNotifier {
  RTCPeerConnection? _peerConnection;
  WebSocketChannel? _webSocket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> initializeConnection({
    required String serverUrl,
    required Map<String, dynamic> iceServers,
    required Map<String, dynamic> avatarConfig,
  }) async {
    final configuration = {
      'iceServers': [iceServers],
    };

    _peerConnection = await createPeerConnection(configuration);
    _setupPeerConnectionListeners();
    _connectWebSocket(serverUrl);
  }

  void _setupPeerConnectionListeners() {
    _peerConnection?.onIceCandidate = (candidate) {
      // Send candidate to server
    };

    _peerConnection?.onTrack = (event) {
      // Handle incoming tracks
    };
  }

  void _connectWebSocket(String serverUrl) {
    _webSocket = WebSocketChannel.connect(Uri.parse(serverUrl));
    _webSocket?.stream.listen(
      (message) {
        // Handle incoming WebSocket messages
      },
      onError: (error) {
        print('WebSocket error: $error');
        _isConnected = false;
        notifyListeners();
      },
      onDone: () {
        _isConnected = false;
        notifyListeners();
      },
    );
  }

  Future<void> disconnect() async {
    await _peerConnection?.close();
    _webSocket?.sink.close();
    _isConnected = false;
    notifyListeners();
  }
}