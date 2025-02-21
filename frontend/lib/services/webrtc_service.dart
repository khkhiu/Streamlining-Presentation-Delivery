import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// A service class that handles WebRTC connections for avatar video streaming.
/// This service manages the peer connection, ICE servers, and media streams
/// necessary for real-time video communication with the avatar service.
class WebRTCService {
  // Core WebRTC components
  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;
  RTCDataChannel? _dataChannel;

  // Stream controllers for state management
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  final _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();

  // Getters for streams
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;
  Stream<RTCPeerConnectionState> get connectionStateStream => _connectionStateController.stream;
  MediaStream? get currentRemoteStream => _remoteStream;

  /// Initializes the WebRTC peer connection with the given configuration.
  /// This sets up the connection with ICE servers and prepares for media streaming.
  Future<void> initialize({
    required String serverUrl,
    required String username,
    required String credential,
  }) async {
    // Create the peer connection configuration with ICE servers
    final configuration = {
      'iceServers': [
        {
          'urls': serverUrl,
          'username': username,
          'credential': credential,
        }
      ],
      'sdpSemantics': 'unified-plan',
    };

    try {
      // Create the peer connection
      _peerConnection = await createPeerConnection(configuration);

      // Set up event handlers
      _setupPeerConnectionHandlers();
      
      // Add transceivers for audio and video
      await _addMediaTransceivers();

      print('WebRTC peer connection initialized successfully');
    } catch (e) {
      print('Error initializing WebRTC: $e');
      throw Exception('Failed to initialize WebRTC connection: $e');
    }
  }

  /// Sets up all the necessary event handlers for the peer connection.
  /// This includes handling connection state changes, ICE candidates, and media streams.
  void _setupPeerConnectionHandlers() {
    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state changed: $state');
      _connectionStateController.add(state);
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE connection state changed: $state');
    };

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      // In this implementation, ICE candidates are handled by the signaling server
      print('New ICE candidate: ${candidate.candidate}');
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      print('Received track: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream);
      }
    };

    // Set up data channel for avatar events
    _setupDataChannel();
  }

  /// Adds audio and video transceivers to the peer connection.
  /// These transceivers enable the reception of audio and video streams from the avatar.
  Future<void> _addMediaTransceivers() async {
    try {
      // Add video transceiver
      await _peerConnection?.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(
          direction: TransceiverDirection.RecvOnly,
        ),
      );

      // Add audio transceiver
      await _peerConnection?.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(
          direction: TransceiverDirection.RecvOnly,
        ),
      );
    } catch (e) {
      print('Error adding transceivers: $e');
      throw Exception('Failed to add media transceivers: $e');
    }
  }

  /// Sets up the data channel for receiving avatar events.
  /// This channel is used for receiving status updates and synchronization events.
  void _setupDataChannel() {
    _peerConnection?.createDataChannel(
      'events',
      RTCDataChannelInit()..ordered = true,
    ).then((channel) {
      _dataChannel = channel;
      
      _dataChannel?.onMessage = (message) {
        // Handle incoming messages from the avatar service
        try {
          final event = json.decode(message.text);
          print('Received avatar event: $event');
          // Handle different event types here
        } catch (e) {
          print('Error parsing avatar event: $e');
        }
      };

      _dataChannel?.onDataChannelState = (state) {
        print('Data channel state changed: $state');
      };
    });
  }

  /// Creates and sets the local session description.
  /// This is a crucial step in establishing the WebRTC connection.
  Future<void> createOffer() async {
    try {
      final RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });

      await _peerConnection!.setLocalDescription(offer);
      
      print('Local description set successfully');
      return offer;
    } catch (e) {
      print('Error creating offer: $e');
      throw Exception('Failed to create WebRTC offer: $e');
    }
  }

  /// Sets the remote session description received from the signaling server.
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    try {
      await _peerConnection?.setRemoteDescription(description);
      print('Remote description set successfully');
    } catch (e) {
      print('Error setting remote description: $e');
      throw Exception('Failed to set remote description: $e');
    }
  }

  /// Cleans up the WebRTC connection and releases resources.
  Future<void> dispose() async {
    try {
      await _dataChannel?.close();
      await _peerConnection?.close();
      await _remoteStream?.dispose();
      
      await _remoteStreamController.close();
      await _connectionStateController.close();
      
      _peerConnection = null;
      _remoteStream = null;
      _dataChannel = null;
      
      print('WebRTC resources cleaned up successfully');
    } catch (e) {
      print('Error disposing WebRTC resources: $e');
    }
  }
}