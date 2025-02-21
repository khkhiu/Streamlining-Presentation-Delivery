import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'dart:io';

void main() {
  runApp(const AvatarApp());
}

class AvatarApp extends StatelessWidget {
  const AvatarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talking Avatar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AvatarControlPage(),
    );
  }
}

class AvatarControlPage extends StatefulWidget {
  const AvatarControlPage({super.key});

  @override
  State<AvatarControlPage> createState() => _AvatarControlPageState();
}

class _AvatarControlPageState extends State<AvatarControlPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isSessionActive = false;
  bool _isSpeaking = false;
  String _selectedRegion = 'westus2';
  String _selectedVoice = 'en-US-AvaMultilingualNeural';
  String _selectedCharacter = 'lisa';
  String _selectedStyle = 'casual-sitting';
  bool _showSubtitles = true;
  
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadConfig();
  }

void _initWebView() {
  final WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          debugPrint('WebView is loading (progress : $progress%)');
        },
        onPageStarted: (String url) {
          debugPrint('Page started loading: $url');
        },
        onPageFinished: (String url) {
          debugPrint('Page finished loading: $url');
        },
        onWebResourceError: (WebResourceError error) {
          debugPrint('''
            Page resource error:
            code: ${error.errorCode}
            description: ${error.description}
            errorType: ${error.errorType}
            isForMainFrame: ${error.isForMainFrame}
          ''');
        },
      ),
    )
    ..loadRequest(Uri.parse('http://localhost:3000'));

  _webViewController = controller;
}

  Future<void> _loadConfig() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/config'));
      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        setState(() {
          _apiKeyController.text = config['speech']['apiKey'];
          _selectedRegion = config['speech']['region'];
          _selectedVoice = config['tts']['voice'];
          _selectedCharacter = config['avatar']['character'];
          _selectedStyle = config['avatar']['style'];
        });
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    }
  }

  Future<void> _startSession() async {
    if (_apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your API key')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/startSession'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'apiKey': _apiKeyController.text,
          'region': _selectedRegion,
          'voice': _selectedVoice,
          'character': _selectedCharacter,
          'style': _selectedStyle,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _isSessionActive = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting session: $e')),
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
      final response = await http.post(
        Uri.parse('http://localhost:3000/speak'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': _textController.text}),
      );

      if (response.statusCode == 200) {
        setState(() => _isSpeaking = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error speaking: $e')),
      );
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/stopSpeaking'),
      );

      if (response.statusCode == 200) {
        setState(() => _isSpeaking = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping speech: $e')),
      );
    }
  }

  Future<void> _stopSession() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/stopSession'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isSessionActive = false;
          _isSpeaking = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping session: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talking Avatar Control'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: WebViewWidget(controller: _webViewController),
          ),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isSessionActive) ...[
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Azure Speech API Key',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      decoration: const InputDecoration(
                        labelText: 'Region',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'westus2', child: Text('West US 2')),
                        DropdownMenuItem(value: 'eastus2', child: Text('East US 2')),
                        DropdownMenuItem(value: 'westeurope', child: Text('West Europe')),
                      ],
                      onChanged: (value) => setState(() => _selectedRegion = value!),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _startSession,
                      child: const Text('Start Session'),
                    ),
                  ],
                  if (_isSessionActive) ...[
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'Enter text to speak',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _isSpeaking ? null : _speak,
                          child: const Text('Speak'),
                        ),
                        ElevatedButton(
                          onPressed: _isSpeaking ? _stopSpeaking : null,
                          child: const Text('Stop Speaking'),
                        ),
                        ElevatedButton(
                          onPressed: _stopSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('End Session'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Show Subtitles'),
                      value: _showSubtitles,
                      onChanged: (value) => setState(() => _showSubtitles = value),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}