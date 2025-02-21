//import 'package:flutter/foundation.dart';

// This class manages all configuration settings for the avatar system
class AvatarConfiguration {
  // Speech configuration
  final String region;
  final String apiKey;
  final String? privateEndpoint;

  // TTS (Text-to-Speech) configuration
  final String ttsVoice;
  final String? customVoiceDeploymentId;
  final String? personalVoiceSpeakerProfileId;

  // Avatar appearance configuration
  final String character;
  final String style;
  final bool isCustomized;
  final bool useLocalVideoForIdle;

  // OpenAI configuration for chat
  final String? openAiEndpoint;
  final String? openAiApiKey;
  final String? openAiDeploymentName;
  final String? systemPrompt;

  // Speech-to-Text configuration
  final List<String> sttLocales;
  final bool continuousConversation;

  const AvatarConfiguration({
    required this.region,
    required this.apiKey,
    this.privateEndpoint,
    required this.ttsVoice,
    this.customVoiceDeploymentId,
    this.personalVoiceSpeakerProfileId,
    required this.character,
    required this.style,
    this.isCustomized = false,
    this.useLocalVideoForIdle = false,
    this.openAiEndpoint,
    this.openAiApiKey,
    this.openAiDeploymentName,
    this.systemPrompt,
    this.sttLocales = const ['en-US'],
    this.continuousConversation = false,
  });

  // Create a copy of the configuration with some modified values
  AvatarConfiguration copyWith({
    String? region,
    String? apiKey,
    String? privateEndpoint,
    String? ttsVoice,
    String? customVoiceDeploymentId,
    String? personalVoiceSpeakerProfileId,
    String? character,
    String? style,
    bool? isCustomized,
    bool? useLocalVideoForIdle,
    String? openAiEndpoint,
    String? openAiApiKey,
    String? openAiDeploymentName,
    String? systemPrompt,
    List<String>? sttLocales,
    bool? continuousConversation,
  }) {
    return AvatarConfiguration(
      region: region ?? this.region,
      apiKey: apiKey ?? this.apiKey,
      privateEndpoint: privateEndpoint ?? this.privateEndpoint,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      customVoiceDeploymentId: customVoiceDeploymentId ?? this.customVoiceDeploymentId,
      personalVoiceSpeakerProfileId: personalVoiceSpeakerProfileId ?? this.personalVoiceSpeakerProfileId,
      character: character ?? this.character,
      style: style ?? this.style,
      isCustomized: isCustomized ?? this.isCustomized,
      useLocalVideoForIdle: useLocalVideoForIdle ?? this.useLocalVideoForIdle,
      openAiEndpoint: openAiEndpoint ?? this.openAiEndpoint,
      openAiApiKey: openAiApiKey ?? this.openAiApiKey,
      openAiDeploymentName: openAiDeploymentName ?? this.openAiDeploymentName,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      sttLocales: sttLocales ?? this.sttLocales,
      continuousConversation: continuousConversation ?? this.continuousConversation,
    );
  }

  // Convert configuration to JSON format for API calls
  Map<String, dynamic> toJson() {
    return {
      'speech': {
        'region': region,
        'apiKey': apiKey,
        'privateEndpoint': privateEndpoint,
      },
      'tts': {
        'voice': ttsVoice,
        'customVoiceEndpointId': customVoiceDeploymentId,
        'personalVoiceSpeakerProfileId': personalVoiceSpeakerProfileId,
      },
      'avatar': {
        'character': character,
        'style': style,
        'customized': isCustomized,
        'useLocalVideoForIdle': useLocalVideoForIdle,
      },
      'openai': {
        'endpoint': openAiEndpoint,
        'apiKey': openAiApiKey,
        'deploymentName': openAiDeploymentName,
        'systemPrompt': systemPrompt,
      },
      'stt': {
        'locales': sttLocales,
        'continuousConversation': continuousConversation,
      },
    };
  }

  // Create configuration from JSON response
  factory AvatarConfiguration.fromJson(Map<String, dynamic> json) {
    return AvatarConfiguration(
      region: json['speech']['region'] as String,
      apiKey: json['speech']['apiKey'] as String,
      privateEndpoint: json['speech']['privateEndpoint'] as String?,
      ttsVoice: json['tts']['voice'] as String,
      customVoiceDeploymentId: json['tts']['customVoiceEndpointId'] as String?,
      personalVoiceSpeakerProfileId: json['tts']['personalVoiceSpeakerProfileId'] as String?,
      character: json['avatar']['character'] as String,
      style: json['avatar']['style'] as String,
      isCustomized: json['avatar']['customized'] as bool? ?? false,
      useLocalVideoForIdle: json['avatar']['useLocalVideoForIdle'] as bool? ?? false,
      openAiEndpoint: json['openai']['endpoint'] as String?,
      openAiApiKey: json['openai']['apiKey'] as String?,
      openAiDeploymentName: json['openai']['deploymentName'] as String?,
      systemPrompt: json['openai']['systemPrompt'] as String?,
      sttLocales: (json['stt']['locales'] as String).split(','),
      continuousConversation: json['stt']['continuousConversation'] as bool? ?? false,
    );
  }

  // Create a default configuration
  factory AvatarConfiguration.defaultConfig() {
    return const AvatarConfiguration(
      region: 'westus2',
      apiKey: '',
      ttsVoice: 'en-US-JennyMultilingualNeural',
      character: 'lisa',
      style: 'casual-sitting',
      sttLocales: ['en-US'],
    );
  }
}