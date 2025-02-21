import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import '../models/avatar_configuration.dart';
import '../services/app_state.dart';

/// A comprehensive settings panel that allows users to configure all aspects
/// of the avatar interaction. This widget provides an intuitive interface for
/// managing speech, avatar, and connection settings.
class SettingsPanel extends StatefulWidget {
  final VoidCallback? onSettingsApplied;

  const SettingsPanel({
    super.key,
    this.onSettingsApplied,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  // Track the expansion state of different sections
  bool _speechSettingsExpanded = true;
  bool _avatarSettingsExpanded = false;
  bool _advancedSettingsExpanded = false;

  // Form controllers for the various input fields
  late final TextEditingController _apiKeyController;
  late final TextEditingController _voiceController;
  late final TextEditingController _characterController;
  late final TextEditingController _styleController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current configuration
    final config = context.read<AppState>().config;
    _apiKeyController = TextEditingController(text: config.apiKey);
    _voiceController = TextEditingController(text: config.ttsVoice);
    _characterController = TextEditingController(text: config.character);
    _styleController = TextEditingController(text: config.style);
  }

  @override
  void dispose() {
    // Clean up controllers
    _apiKeyController.dispose();
    _voiceController.dispose();
    _characterController.dispose();
    _styleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(),
            _buildSpeechSettings(),
            _buildAvatarSettings(),
            _buildAdvancedSettings(),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.settings, size: 24),
        const SizedBox(width: 8),
        const Text(
          'Avatar Configuration',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showHelpDialog,
          tooltip: 'Configuration Help',
        ),
      ],
    );
  }

  Widget _buildSpeechSettings() {
    return ExpansionTile(
      initiallyExpanded: _speechSettingsExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _speechSettingsExpanded = expanded);
      },
      leading: const Icon(Icons.mic),
      title: const Text('Speech Settings'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildTextField(
                controller: _apiKeyController,
                label: 'API Key',
                isPassword: true,
                helper: 'Your Azure Speech Services API key',
              ),
              const SizedBox(height: 16),
              _buildDropdownField<String>(
                label: 'Region',
                value: context.select((AppState state) => state.config.region),
                items: const [
                  'westus2',
                  'eastus',
                  'westeurope',
                  'southeastasia',
                ],
                onChanged: (value) {
                  // Update region in configuration
                  if (value != null) {
                    final currentConfig = context.read<AppState>().config;
                    context.read<AppState>().updateConfiguration(
                      currentConfig.copyWith(region: value),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _voiceController,
                label: 'Voice Name',
                helper: 'e.g., en-US-JennyMultilingualNeural',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSettings() {
    return ExpansionTile(
      initiallyExpanded: _avatarSettingsExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _avatarSettingsExpanded = expanded);
      },
      leading: const Icon(Icons.face),
      title: const Text('Avatar Settings'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildTextField(
                controller: _characterController,
                label: 'Character',
                helper: 'Avatar character name (e.g., lisa)',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _styleController,
                label: 'Style',
                helper: 'Avatar style (e.g., casual-sitting)',
              ),
              const SizedBox(height: 16),
              Consumer<AppState>(
                builder: (context, appState, _) {
                  return Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Custom Avatar'),
                        subtitle: const Text('Use customized avatar settings'),
                        value: appState.config.isCustomized,
                        onChanged: (value) {
                          context.read<AppState>().updateConfiguration(
                            appState.config.copyWith(isCustomized: value),
                          );
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Local Video for Idle'),
                        subtitle: const Text('Use local video when avatar is idle'),
                        value: appState.config.useLocalVideoForIdle,
                        onChanged: (value) {
                          context.read<AppState>().updateConfiguration(
                            appState.config.copyWith(useLocalVideoForIdle: value),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return ExpansionTile(
      initiallyExpanded: _advancedSettingsExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _advancedSettingsExpanded = expanded);
      },
      leading: const Icon(Icons.tune),
      title: const Text('Advanced Settings'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Consumer<AppState>(
            builder: (context, appState, _) {
              return Column(
                children: [
                  SwitchListTile(
                    title: const Text('Continuous Conversation'),
                    subtitle: const Text('Keep listening for speech input'),
                    value: appState.config.continuousConversation,
                    onChanged: (value) {
                      context.read<AppState>().updateConfiguration(
                        appState.config.copyWith(continuousConversation: value),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Speech Recognition Languages'),
                    subtitle: Text(appState.config.sttLocales.join(', ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showLanguageSelectionDialog(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _applySettings,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Apply Settings'),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? helper,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
      ),
      obscureText: isPassword,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _showLanguageSelectionDialog() async {
    // Implement language selection dialog
    // This would show a dialog with checkboxes for available languages
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration Help'),
        content: const SingleChildScrollView(
          child: Text(
            'This panel allows you to configure various aspects of the avatar '
            'interaction. The Speech Settings control how the avatar speaks and '
            'understands you. Avatar Settings determine the appearance and '
            'behavior of the avatar. Advanced Settings provide additional '
            'customization options for experienced users.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _applySettings() {
    final currentConfig = context.read<AppState>().config;
    
    // Create new configuration with updated values
    final newConfig = currentConfig.copyWith(
      apiKey: _apiKeyController.text,
      ttsVoice: _voiceController.text,
      character: _characterController.text,
      style: _styleController.text,
    );

    // Update the configuration in the app state
    context.read<AppState>().updateConfiguration(newConfig);

    // Notify parent that settings were applied
    widget.onSettingsApplied?.call();
  }
}