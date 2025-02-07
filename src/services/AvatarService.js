// services/AvatarService.js
import { getAzureConfig } from '../config/azure';

export class AvatarService {
    constructor({ onLog }) {
        this.avatarSynthesizer = null;
        this.peerConnection = null;
        this.onLog = onLog;
        this.azureConfig = getAzureConfig();
    }
      
      log(message) {
        console.log(message);
        this.onLog?.(message);
      }
    
    async startSession(config) {
        const { region, speechKey, privateEndpoint } = this.azureConfig;
        
        try {
            const tokenResponse = await this.getRelayToken(
                region,
                speechKey,
                config.privateEndpointEnabled,
                privateEndpoint || config.privateEndpoint
              );
            const avatarConfig = this.createAvatarConfig(config, tokenResponse);
            
            const speechConfig = createSpeechConfig(cogSvcSubKey, cogSvcRegion, privateEndpointEnabled, privateEndpoint);
            speechConfig.endpointId = config.customVoiceEndpointId;
            
            this.avatarSynthesizer = new SpeechSDK.AvatarSynthesizer(speechConfig, avatarConfig);
            this.setupEventHandlers();
            
            return this.setupWebRTCConnection(tokenResponse);
        } catch (error) {
            this.log('Failed to start session: ' + error.message);
            throw error;
        }
    }
    
    async speak(text, voice, speakerProfileId) {
        const ssml = this.createSpeechSSML(text, voice, speakerProfileId);
        try {
            const result = await this.avatarSynthesizer.speakSsmlAsync(ssml);
            return this.handleSpeechResult(result, text);
        } catch (error) {
            console.error('Speech synthesis failed:', error);
            throw error;
        }
    }
    
    stopSpeaking() {
        return this.avatarSynthesizer.stopSpeakingAsync();
    }
    
    stopSession() {
        if (this.avatarSynthesizer) {
            this.avatarSynthesizer.close();
        }
    }
    
    // Private methods
    createSpeechSSML(text, voice, speakerProfileId) {
        return `<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' 
                xmlns:mstts='http://www.w3.org/2001/mstts' xml:lang='en-US'>
                <voice name='${voice}'>
                    <mstts:ttsembedding speakerProfileId='${speakerProfileId}'>
                        <mstts:leadingsilence-exact value='0'/>
                        ${htmlEncode(text)}
                    </mstts:ttsembedding>
                </voice>
            </speak>`;
    }
    
    async getRelayToken(region, key, privateEndpointEnabled, privateEndpoint) {
        const endpoint = privateEndpointEnabled
            ? `https://${privateEndpoint}/tts/cognitiveservices/avatar/relay/token/v1`
            : `https://${region}.tts.speech.microsoft.com/cognitiveservices/avatar/relay/token/v1`;
            
        const response = await fetch(endpoint, {
            headers: { "Ocp-Apim-Subscription-Key": key }
        });
        return response.json();
    }
        
}