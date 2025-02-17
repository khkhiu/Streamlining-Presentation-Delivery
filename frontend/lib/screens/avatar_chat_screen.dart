// lib/screens/avatar_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/configuration_form.dart';

class AvatarChatScreen extends StatefulWidget {
  const AvatarChatScreen({super.key});

  @override
  State<AvatarChatScreen> createState() => _AvatarChatScreenState();
}

class _AvatarChatScreenState extends State<AvatarChatScreen> {
  late WebViewController _controller;
  bool isConfigured = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white);
  }

  void _startSession(Map<String, String> config) {
    // Inject configuration values into WebView
    _controller.runJavaScript("""
      document.getElementById('region').value = '${config['region']}';
      document.getElementById('APIKey').value = '${config['apiKey']}';
      document.getElementById('azureOpenAIEndpoint').value = '${config['openAIEndpoint']}';
      document.getElementById('azureOpenAIApiKey').value = '${config['openAIKey']}';
      document.getElementById('azureOpenAIDeploymentName').value = '${config['deploymentName']}';
      document.getElementById('ttsVoice').value = '${config['ttsVoice']}';
      startSession();
    """);
    
    setState(() {
      isConfigured = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talking Avatar Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => ConfigurationForm(
                  onSubmit: _startSession,
                ),
              );
            },
          ),
        ],
      ),
      body: !isConfigured 
        ? const Center(
            child: Text('Please configure the avatar settings'),
          )
        : WebViewWidget(controller: _controller),
    );
  }
}