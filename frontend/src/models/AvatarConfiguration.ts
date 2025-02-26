export interface AvatarConfiguration {
    speech: {
      region: string;
      apiKey: string;
      privateEndpoint?: string;
    };
    tts: {
      voice: string;
      customVoiceEndpointId?: string;
      personalVoiceSpeakerProfileId?: string;
    };
    avatar: {
      character: string;
      style: string;
      customized: boolean;
      useLocalVideoForIdle: boolean;
    };
    openai?: {
      endpoint?: string;
      apiKey?: string;
      deploymentName?: string;
      systemPrompt?: string;
    };
    stt?: {
      locales: string[];
      continuousConversation: boolean;
    };
  }