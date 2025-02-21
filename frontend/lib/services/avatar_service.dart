import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webrtc/flutter_webrtc.dart';

class AvatarService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:3000';
  
  bool _isSessionActive = false;
  bool _isSpeaking = false;
  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;
  String? _apiKey;
  String? _region;

  bool get isSessionActive => _isSessionActive;
  bool get isSpeaking => _isSpeaking;
  MediaStream? get remoteStream => _remoteStream;

  // Fetch configuration from backend
  Future<void> fetchConfig() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/config'));
      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        _apiKey = config['speech']['apiKey'];
        _region = config['speech']['region'];
        notifyListeners();
      } else {
        throw Exception('Failed to load configuration');
      }
    } catch (e) {
      print('Error fetching config: $e');
      rethrow;
    }
  }

  // Initialize WebRTC connection
  Future<void> initializeWebRTC() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {
          'urls': 'stun:stun.l.google.com:19302',
        }
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    // Handle remote stream
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        notifyListeners();
      }
    };

    // Add transceivers for audio and video
    await _peerConnection?.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    await _peerConnection?.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
  }

  // Start avatar session
  Future<void> startSession() async {
    try {
      await initializeWebRTC();
      
      final response = await http.post(
        Uri.parse('$baseUrl/startSession'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'apiKey': _apiKey,
          'region': _region,
        }),
      );

      if (response.statusCode == 200) {
        _isSessionActive = true;
        notifyListeners();
      } else {
        throw Exception('Failed to start session');
      }
    } catch (e) {
      print('Error starting session: $e');
      rethrow;
    }
  }

  // Speak text through avatar
  Future<void> speak(String text) async {
    if (!_isSessionActive) {
      throw Exception('No active session');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/speak'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        _isSpeaking = true;
        notifyListeners();
      } else {
        throw Exception('Failed to start speaking');
      }
    } catch (e) {
      print('Error speaking: $e');
      rethrow;
    }
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    if (!_isSessionActive) return;

    try {
      final response = await http.post(Uri.parse('$baseUrl/stopSpeaking'));
      
      if (response.statusCode == 200) {
        _isSpeaking = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error stopping speech: $e');
    }
  }

  // Stop session
  Future<void> stopSession() async {
    if (!_isSessionActive) return;

    try {
      final response = await http.post(Uri.parse('$baseUrl/stopSession'));
      
      if (response.statusCode == 200) {
        _isSessionActive = false;
        _isSpeaking = false;
        
        // Clean up WebRTC resources
        await _remoteStream?.dispose();
        await _peerConnection?.close();
        _remoteStream = null;
        _peerConnection = null;
        
        notifyListeners();
      }
    } catch (e) {
      print('Error stopping session: $e');
    }
  }

  @override
  void dispose() {
    stopSession();
    super.dispose();
  }
}