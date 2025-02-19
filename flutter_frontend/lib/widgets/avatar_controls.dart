import 'package:flutter/material.dart';
import '../services/api.dart';

class AvatarControls extends StatefulWidget {
  const AvatarControls({super.key});

  @override
  State<AvatarControls> createState() => _AvatarControlsState();
}

class _AvatarControlsState extends State<AvatarControls> {
  final ApiService _apiService = ApiService();
  final TextEditingController _textController = TextEditingController();
  bool _isSessionActive = false;
  bool _isSpeaking = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    try {
      final config = await _apiService.getConfig();
      await _apiService.startSession(config);
      setState(() => _isSessionActive = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session started successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _speak() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text to speak')),
      );
      return;
    }

    try {
      await _apiService.speak(_textController.text);
      setState(() => _isSpeaking = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await _apiService.stopSpeaking();
      setState(() => _isSpeaking = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _stopSession() async {
    try {
      await _apiService.stopSession();
      setState(() {
        _isSessionActive = false;
        _isSpeaking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session stopped successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _isSessionActive ? null : _startSession,
            child: const Text('Start Session'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Enter text to speak',
              border: OutlineInputBorder(),
            ),
            enabled: _isSessionActive,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSessionActive && !_isSpeaking ? _speak : null,
            child: const Text('Speak'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isSpeaking ? _stopSpeaking : null,
            child: const Text('Stop Speaking'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSessionActive ? _stopSession : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Stop Session'),
          ),
        ],
      ),
    );
  }
}