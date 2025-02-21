import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'avatar_configuration.dart';
import 'webrtc_service.dart';
import 'speech_service.dart';

/// AppState manages the overall state of the application and coordinates between
/// different services. It acts as the central hub for managing the avatar session,
/// speech recognition, and WebRTC connections.
class AppState extends ChangeNotifier {
  // Service instances
  final WebRTCService _webRTCService;
  final SpeechService _speechService;
  
  // Configuration state
  AvatarConfiguration _config;
  bool _isConfigured = false;
  bool _isSessionActive = false;
  bool _isSpeaking = false;
  
  // Chat state
  final List<ChatMessage> _chatHistory = [];
  String _currentTranscript = '';
  
  // Stream subscriptions
  StreamSubscription? _remoteStreamSubscription;
  StreamSubscription? _connectionStateSubscription;
  
  // Public getters
  AvatarConfiguration get config => _config;
  bool get isConfigured => _isConfigured;
  bool get isSessionActive => _isSessionActive;
  bool get isSpeaking => _isSpeaking;
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  String get currentTranscript => _currentTranscript;
  MediaStream? get remoteStream => _webRTCService.currentRemoteStream;

  AppState({
    required WebRTCService webRTCService,
    required SpeechService speechService,
  }) : _webRTCService = webRTCService,
       _speechService = speechService,
       _config = AvatarConfiguration.defaultConfig() {
    _initializeServices();
  }

  /// Initializes all required services and sets up stream subscriptions.
  Future<void> _initializeServices() async {
    try {
      // Initialize speech recognition
      await _speechService.initialize();
      
      // Set up WebRTC stream listeners
      _remoteStreamSubscription = _webRTCService.remoteStreamStream.listen(
        (stream) {
          if (stream != null) {
            _isSessionActive = true;
            notifyListeners();
          }
        },
      );

      _connectionStateSubscription = _webRTCService.connectionStateStream.listen(
        (state) {
          if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
              state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
            _handleConnectionFailure();
          }
        },
      );

      print('Services initialized successfully');
    } catch (e) {
      print('Error initializing services: $e');
      rethrow;
    }
  }

  /// Updates the application configuration.
  Future<void> updateConfiguration(AvatarConfiguration newConfig) async {
    _config = newConfig;
    _isConfigured = true;
    notifyListeners();
  }

  /// Starts a new avatar session.
  Future<void> startSession() async {
    if (!_isConfigured) {
      throw Exception('Configuration not set');
    }

    try {
      // Initialize WebRTC with avatar service
      await _webRTCService.initialize(
        serverUrl: 'turn:${_config.region}.turn.azure.com:3478',
        username: _config.apiKey,
        credential: _config.apiKey,
      );

      _isSessionActive = true;
      notifyListeners();
      
      print('Avatar session started successfully');
    } catch (e) {
      print('Error starting session: $e');
      _isSessionActive = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Handles sending a message to the avatar.
  Future<void> sendMessage(String message) async {
    if (!_isSessionActive) {
      throw Exception('No active session');
    }

    try {
      // Add message to chat history
      _chatHistory.add(
        ChatMessage(
          text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      
      _isSpeaking = true;
      notifyListeners();

      // TODO: Implement the actual message sending logic through the avatar service
      
      // Simulate avatar response for now
      await Future.delayed(const Duration(seconds: 2));
      _chatHistory.add(
        ChatMessage(
          text: 'This is a simulated response from the avatar.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      print('Error sending message: $e');
      _isSpeaking = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Toggles speech recognition on/off.
  Future<void> toggleSpeechRecognition() async {
    if (_speechService.isListening) {
      await _speechService.stopListening();
    } else {
      final started = await _speechService.startListening(
        selectedLocale: _config.sttLocales.first,
        continuous: _config.continuousConversation,
      );

      if (started) {
        // Update transcript as speech is recognized
        _currentTranscript = _speechService.lastWords;
        notifyListeners();
      }
    }
  }

  /// Handles connection failures.
  void _handleConnectionFailure() {
    _isSessionActive = false;
    _isSpeaking = false;
    notifyListeners();
  }

  /// Stops the current session and cleans up resources.
  Future<void> stopSession() async {
    try {
      if (_speechService.isListening) {
        await _speechService.stopListening();
      }

      await _webRTCService.dispose();
      
      _isSessionActive = false;
      _isSpeaking = false;
      notifyListeners();
      
      print('Session stopped successfully');
    } catch (e) {
      print('Error stopping session: $e');
      rethrow;
    }
  }

  /// Cleans up resources when the app state is disposed.
  @override
  void dispose() {
    _remoteStreamSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    stopSession();
    super.dispose();
  }
}