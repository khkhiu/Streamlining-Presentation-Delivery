import 'package:flutter_webrtc/flutter_webrtc.dart';
//import 'dart:convert';

class WebRTCService {
  RTCPeerConnection? peerConnection;
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  
  Future<void> initialize() async {
    await remoteRenderer.initialize();
    
    // WebRTC Configuration
    final configuration = <String, dynamic>{
      'iceServers': [
        {
          'urls': ['stun:stun.l.google.com:19302']
        }
      ]
    };
    
    // Create Peer Connection
    peerConnection = await createPeerConnection(configuration);
    
    // Handle remote stream
    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video') {
        remoteRenderer.srcObject = event.streams[0];
      }
    };
  }

  void dispose() {
    remoteRenderer.dispose();
    peerConnection?.dispose();
  }
}