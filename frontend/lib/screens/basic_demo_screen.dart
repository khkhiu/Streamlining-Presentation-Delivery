import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/avatar_service.dart';
import '../widgets/avatar_video_view.dart';
import '../widgets/configuration_panel.dart';

class BasicDemoScreen extends StatefulWidget {
  const BasicDemoScreen({super.key});

  @override
  State<BasicDemoScreen> createState() => _BasicDemoScreenState();
}

class _BasicDemoScreenState extends State<BasicDemoScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _showConfig = true;

  @override
  void initState() {
    super.initState();
    // Fetch configuration when screen loads
    Future.microtask(() => 
      context.read<AvatarService>().fetchConfig()
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Avatar Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AvatarService>(
        builder: (context, avatarService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showConfig) 
                  ConfigurationPanel(
                    onConfigSubmitted: () {
                      setState(() => _showConfig = false);
                    },
                  ),
                
                const SizedBox(height: 20),
                
                // Avatar Video Display
                AvatarVideoView(
                  stream: avatarService.remoteStream,
                ),
                
                const SizedBox(height: 20),
                
                // Control Panel
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Avatar Control Panel',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            labelText: 'Enter text for the avatar to speak',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: avatarService.isSessionActive
                                  ? null
                                  : () => avatarService.startSession(),
                              child: const Text('Start Session'),
                            ),
                            ElevatedButton(
                              onPressed: !avatarService.isSessionActive
                                  ? null
                                  : () => avatarService.speak(_textController.text),
                              child: const Text('Speak'),
                            ),
                            ElevatedButton(
                              onPressed: !avatarService.isSpeaking
                                  ? null
                                  : () => avatarService.stopSpeaking(),
                              child: const Text('Stop Speaking'),
                            ),
                            ElevatedButton(
                              onPressed: !avatarService.isSessionActive
                                  ? null
                                  : () => avatarService.stopSession(),
                              child: const Text('Stop Session'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Configuration Toggle
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showConfig = !_showConfig);
                  },
                  icon: Icon(_showConfig ? Icons.visibility_off : Icons.visibility),
                  label: Text(_showConfig ? 'Hide Configuration' : 'Show Configuration'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}