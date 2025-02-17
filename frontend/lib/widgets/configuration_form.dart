// lib/widgets/configuration_form.dart
import 'package:flutter/material.dart';

class ConfigurationForm extends StatefulWidget {
  final Function(Map<String, String>) onSubmit;

  const ConfigurationForm({super.key, required this.onSubmit});

  @override
  State<ConfigurationForm> createState() => _ConfigurationFormState();
}

class _ConfigurationFormState extends State<ConfigurationForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {
    'region': 'westus2',
    'apiKey': '',
    'openAIEndpoint': '',
    'openAIKey': '',
    'deploymentName': '',
    'ttsVoice': 'en-US-JennyMultilingualNeural',
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: controller,
            children: [
              const Text(
                'Avatar Configuration',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _formData['region'],
                decoration: const InputDecoration(
                  labelText: 'Region',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'westus2', child: Text('West US 2')),
                  DropdownMenuItem(value: 'westeurope', child: Text('West Europe')),
                  DropdownMenuItem(value: 'southeastasia', child: Text('Southeast Asia')),
                ],
                onChanged: (value) {
                  setState(() {
                    _formData['region'] = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Azure Speech API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter API key';
                  }
                  return null;
                },
                onSaved: (value) {
                  _formData['apiKey'] = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Azure OpenAI Endpoint',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter OpenAI endpoint';
                  }
                  return null;
                },
                onSaved: (value) {
                  _formData['openAIEndpoint'] = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Azure OpenAI API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter OpenAI API key';
                  }
                  return null;
                },
                onSaved: (value) {
                  _formData['openAIKey'] = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Deployment Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter deployment name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _formData['deploymentName'] = value!;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    widget.onSubmit(_formData);
                    Navigator.pop(context);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Start Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}