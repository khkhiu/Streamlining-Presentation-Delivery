import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/avatar_configuration.dart';

class ServerService {
  static const String baseUrl = 'http://localhost:3000';

  // Fetch configuration from server
  Future<AvatarConfiguration> fetchConfig() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/config'));
      
      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        return AvatarConfiguration.fromJson(config);
      } else {
        throw Exception('Failed to load configuration: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching config: $e');
    }
  }

  // Start a new avatar session
  Future<void> startSession({
    required String apiKey,
    required String region,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/startSession'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'apiKey': apiKey,
          'region': region,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to start session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error starting session: $e');
    }
  }

  // Send text for the avatar to speak
  Future<void> speak(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/speak'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to start speaking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error speaking: $e');
    }
  }

  // Stop the avatar from speaking
  Future<void> stopSpeaking() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stopSpeaking'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to stop speaking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error stopping speech: $e');
    }
  }

  // Stop the current avatar session
  Future<void> stopSession() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stopSession'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to stop session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error stopping session: $e');
    }
  }
}