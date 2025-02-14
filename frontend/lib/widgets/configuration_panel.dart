// lib/widgets/configuration_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/avatar_service.dart';

class ConfigurationPanel extends StatefulWidget {
  const ConfigurationPanel({super.key});

  @override
  State<ConfigurationPanel> createState() => _ConfigurationPanelState();
}

class _ConfigurationPanelState extends State<ConfigurationPanel> {
  final _formKey = GlobalKey<FormState>();
  final _regionController = TextEditingController(text: 'westus2');
  final _apiKeyController = TextEditingController();
  final _endpointController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Azure Configuration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _regionController,
                decoration: const InputDecoration(
                  labelText: 'Region',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _endpointController,
                decoration: const InputDecoration(
                  labelText: 'Endpoint',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AvatarService>().initializeConnection(
                          serverUrl: 'ws://your-server-url',
                          iceServers: {/* ICE server config */},
                          avatarConfig: {/* Avatar config */},
                        );
                  }
                },
                child: const Text('Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}