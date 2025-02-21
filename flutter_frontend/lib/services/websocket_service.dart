import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class WebSocketService {
  WebSocketChannel? _channel;
  
  Future<void> connect(String url) async {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    
    _channel?.stream.listen(
      (message) {
        final data = jsonDecode(message);
        // Handle incoming WebSocket messages
        print('Received: $data');
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );
  }

  void send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void dispose() {
    _channel?.sink.close();
  }
}