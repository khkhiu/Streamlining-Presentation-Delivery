import 'package:flutter/material.dart';

class ConfigurationPanel extends StatefulWidget {
  final VoidCallback onConfigSubmitted;

  const ConfigurationPanel({
    super.key,
    required this.onConfigSubmitted,
  });

  @override
  State<ConfigurationPanel> createState() => _ConfigurationPanelState();
}

class _ConfigurationPanelState extends State<ConfigurationPanel> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _regionController = TextEditingController(text: 'westus2');
  final _apiKeyController = TextEditingController();
  final _ttsVoiceController = TextEditingController(text: 'en-US-JennyMultilingualNeural');
  final _avatarCharacterController = TextEditingController(text: 'lisa');
  final _avatarStyleController = TextEditingController(text: 'casual-sitting');
  
  bool _useCustomVoice = false;
  bool _customizeAvatar = false;
  bool _usePrivateEndpoint = false;

  @override
  void dispose() {
    _regionController.dispose();
    _apiKeyController.dispose();
    _ttsVoiceController.dispose();
    _avatarCharacterController.dispose();
    _avatarStyleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Azure Speech Configuration
              _buildSectionTitle('Azure Speech Resource'),
              _buildDropdownField(
                label: 'Region',
                value: _regionController.text,
                items: const [
                  'westus2',
                  'westeurope',
                  'southeastasia',
                  'southcentralus',
                  'northeurope',
                  'swedencentral',
                  'eastus2',
                ],
                onChanged: (value) {
                  if (value != null) {
                    _regionController.text = value;
                  }
                },
              ),
              _buildTextField(
                controller: _apiKeyController,
                label: 'API Key',
                isPassword: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your API key';
                  }
                  return null;
                },
              ),
              
              // Private Endpoint Toggle
              CheckboxListTile(
                title: const Text('Enable Private Endpoint'),
                value: _usePrivateEndpoint,
                onChanged: (value) {
                  setState(() => _usePrivateEndpoint = value ?? false);
                },
              ),
              if (_usePrivateEndpoint)
                _buildTextField(
                  label: 'Private Endpoint',
                  hint: 'https://{your custom name}.cognitiveservices.azure.com/',
                ),
              
              const SizedBox(height: 20),
              
              // TTS Configuration
              _buildSectionTitle('TTS Configuration'),
              _buildTextField(
                controller: _ttsVoiceController,
                label: 'TTS Voice',
              ),
              CheckboxListTile(
                title: const Text('Use Custom Voice'),
                value: _useCustomVoice,
                onChanged: (value) {
                  setState(() => _useCustomVoice = value ?? false);
                },
              ),
              if (_useCustomVoice) ...[
                _buildTextField(
                  label: 'Custom Voice Deployment ID',
                ),
                _buildTextField(
                  label: 'Personal Voice Speaker Profile ID',
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Avatar Configuration
              _buildSectionTitle('Avatar Configuration'),
              _buildTextField(
                controller: _avatarCharacterController,
                label: 'Avatar Character',
              ),
              _buildTextField(
                controller: _avatarStyleController,
                label: 'Avatar Style',
              ),
              CheckboxListTile(
                title: const Text('Customize Avatar'),
                value: _customizeAvatar,
                onChanged: (value) {
                  setState(() => _customizeAvatar = value ?? false);
                },
              ),
              
              const SizedBox(height: 20),
              
              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      // Here you would typically save the configuration
                      widget.onConfigSubmitted();
                    }
                  },
                  child: const Text('Apply Configuration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    String? hint,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        obscureText: isPassword,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: value,
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}