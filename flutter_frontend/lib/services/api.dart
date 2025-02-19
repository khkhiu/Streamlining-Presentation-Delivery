import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'http://localhost:3000'; //NodeJS backend URL

  Future<Map<String, dynamic>> getConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/config'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<void> startSession(Map<String, dynamic> sessionConfig) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/startSession'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Accept': 'application/json',
        },
        body: json.encode(sessionConfig),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to start session: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to start session: $e');
    }
  }

  Future<void> speak(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/speak'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Accept': 'application/json',
        },
        body: json.encode({'text': text}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to start speaking: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to start speaking: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stopSpeaking'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to stop speaking: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to stop speaking: $e');
    }
  }

  Future<void> stopSession() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stopSession'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to stop session: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to stop session: $e');
    }
  }
}