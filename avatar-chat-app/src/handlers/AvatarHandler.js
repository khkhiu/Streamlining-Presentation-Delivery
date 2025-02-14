// src/handlers/AvatarHandler.js - Complete Implementation
const sdk = require('microsoft-cognitiveservices-speech-sdk');

class AvatarHandler {
  constructor(config) {
    this.config = config;
    this.synthesizer = null;
    this.isSpeaking = false;
    this.spokenTextQueue = [];
    this.lastSpeakTime = null;
  }

  async connectAvatar() {
    const speechConfig = this.createSpeechConfig();
    const avatarConfig = this.createAvatarConfig();
    
    this.synthesizer = new sdk.AvatarSynthesizer(speechConfig, avatarConfig);
    this.setupAvatarEventHandling();
    
    return this.synthesizer;
  }

  createSpeechConfig() {
    const { region, apiKey, privateEndpoint } = this.config;
    
    if (privateEndpoint) {
      return sdk.SpeechConfig.fromEndpoint(
        new URL(`wss://${privateEndpoint}/tts/cognitiveservices/websocket/v1?enableTalkingAvatar=true`),
        apiKey
      );
    }
    
    return sdk.SpeechConfig.fromSubscription(apiKey, region);
  }

  createAvatarConfig() {
    const { character, style, customized } = this.config;
    const avatarConfig = new sdk.AvatarConfig(character, style);
    avatarConfig.customized = customized;
    return avatarConfig;
  }

  setupAvatarEventHandling() {
    this.synthesizer.avatarEventReceived = (s, e) => {
      const offsetMessage = e.offset === 0 ? "" : `, offset from session start: ${e.offset / 10000}ms.`;
      console.log(`Event received: ${e.description}${offsetMessage}`);
    };
  }

  async speak(text, endingSilenceMs = 0) {
    if (this.isSpeaking) {
      this.spokenTextQueue.push({ text, endingSilenceMs });
      return;
    }

    await this.speakNext(text, endingSilenceMs);
  }

  async speakNext(text, endingSilenceMs = 0) {
    const { ttsVoice, personalVoiceSpeakerProfileID } = this.config;
    
    let ssml = `<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xmlns:mstts='http://www.w3.org/2001/mstts' xml:lang='en-US'>
      <voice name='${ttsVoice}'>
        <mstts:ttsembedding speakerProfileId='${personalVoiceSpeakerProfileID}'>
          <mstts:leadingsilence-exact value='0'/>
          ${this.htmlEncode(text)}
          ${endingSilenceMs > 0 ? `<break time='${endingSilenceMs}ms' />` : ''}
        </mstts:ttsembedding>
      </voice>
    </speak>`;

    this.lastSpeakTime = new Date();
    this.isSpeaking = true;

    try {
      const result = await this.synthesizer.speakSsmlAsync(ssml);
      
      if (result.reason === sdk.ResultReason.SynthesizingAudioCompleted) {
        console.log(`Speech synthesized for text [ ${text} ]. Result ID: ${result.resultId}`);
        this.lastSpeakTime = new Date();
      } else {
        console.log(`Error occurred while speaking the SSML. Result ID: ${result.resultId}`);
      }

      if (this.spokenTextQueue.length > 0) {
        const nextSpeech = this.spokenTextQueue.shift();
        await this.speakNext(nextSpeech.text, nextSpeech.endingSilenceMs);
      } else {
        this.isSpeaking = false;
      }
    } catch (error) {
      console.error(`Error occurred while speaking the SSML: [ ${error} ]`);
      this.isSpeaking = false;
      throw error;
    }
  }

  async stopSpeaking() {
    this.spokenTextQueue = [];
    try {
      await this.synthesizer.stopSpeakingAsync();
      this.isSpeaking = false;
      console.log(`[${new Date().toISOString()}] Stop speaking request sent.`);
    } catch (error) {
      console.error("Error occurred while stopping speaking:", error);
      throw error;
    }
  }

  htmlEncode(text) {
    const entityMap = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
      '/': '&#x2F;'
    };
    return String(text).replace(/[&<>"'\/]/g, (match) => entityMap[match]);
  }

  disconnect() {
    if (this.synthesizer) {
      this.synthesizer.close();
      this.synthesizer = null;
    }
  }
}
