import axios from 'axios';
import { AvatarConfiguration } from '../models/AvatarConfiguration';

class AvatarService {
  // Get configuration from server
  static async getConfig(): Promise<AvatarConfiguration> {
    const response = await axios.get<AvatarConfiguration>('/api/config');
    return response.data;
  }

  // Start a new avatar session
  static async startSession(apiKey: string, region: string): Promise<void> {
    await axios.post('/startSession', { apiKey, region });
  }

  // Make the avatar speak text
  static async speak(text: string): Promise<void> {
    await axios.post('/speak', { text });
  }

  // Stop the avatar from speaking
  static async stopSpeaking(): Promise<void> {
    await axios.post('/stopSpeaking');
  }

  // End the avatar session
  static async stopSession(): Promise<void> {
    await axios.post('/stopSession');
  }

  // Get WebRTC token
  static async getWebRTCToken(region: string, apiKey: string): Promise<any> {
    const response = await axios.get(
      `https://${region}.tts.speech.microsoft.com/cognitiveservices/avatar/relay/token/v1`, 
      {
        headers: {
          'Ocp-Apim-Subscription-Key': apiKey
        }
      }
    );
    return response.data;
  }
}

export default AvatarService;