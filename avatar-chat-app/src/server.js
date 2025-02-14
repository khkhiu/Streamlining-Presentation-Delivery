const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const sdk = require('microsoft-cognitiveservices-speech-sdk');
const path = require('path');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Serve static files
app.use(express.static('public'));
app.use(express.json());

// Global state
let avatarSynthesizer;
let speechRecognizer;
let peerConnection;
let messages = [];
let messageInitiated = false;
let dataSources = [];
let isSpeaking = false;
let spokenTextQueue = [];
let sessionActive = false;
let lastSpeakTime;

const sentenceLevelPunctuations = ['.', '?', '!', ':', ';', '。', '？', '！', '：', '；'];
const byodDocRegex = new RegExp(/\[doc(\d+)\]/g);

// Configuration defaults
const defaultConfig = {
  enableDisplayTextAlignmentWithSpeech: true,
  enableQuickReply: false,
  quickReplies: ['Let me take a look.', 'Let me check.', 'One moment, please.']
};

// Helper function to handle WebRTC setup
function setupWebRTC(config) {
  const { iceServerUrl, iceServerUsername, iceServerCredential } = config;
  
  peerConnection = new RTCPeerConnection({
    iceServers: [{
      urls: [iceServerUrl],
      username: iceServerUsername,
      credential: iceServerCredential
    }]
  });

  peerConnection.ontrack = handleTrack;
  peerConnection.ondatachannel = handleDataChannel;
  
  // Create data channel for events
  const dataChannel = peerConnection.createDataChannel("eventChannel");
  
  return peerConnection;
}

// Handle incoming media tracks
function handleTrack(event) {
  if (event.track.kind === 'audio') {
    handleAudioTrack(event);
  } else if (event.track.kind === 'video') {
    handleVideoTrack(event);
  }
}

function handleAudioTrack(event) {
  // Implementation for handling audio track
  // Note: Browser-specific audio handling would need to be adapted for Node.js
  console.log('Audio track received');
}

function handleVideoTrack(event) {
  // Implementation for handling video track
  // Note: Browser-specific video handling would need to be adapted for Node.js
  console.log('Video track received');
}

// Handle WebRTC data channel
function handleDataChannel(event) {
  const dataChannel = event.channel;
  dataChannel.onmessage = (e) => {
    console.log(`[${new Date().toISOString()}] WebRTC event received: ${e.data}`);
  };
}

// Avatar synthesis handling
class AvatarHandler {
  constructor(config) {
    this.config = config;
    this.synthesizer = null;
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
}

// Chat message handling
class ChatHandler {
  constructor(config) {
    this.config = config;
    this.messages = [];
    this.dataSources = [];
  }

  async handleUserQuery(userQuery, userQueryHTML = '', imgUrlPath = '') {
    const chatMessage = this.createChatMessage(userQuery, imgUrlPath);
    this.messages.push(chatMessage);

    // Handle quick replies if enabled
    if (this.dataSources.length > 0 && this.config.enableQuickReply) {
      await this.handleQuickReply();
    }

    const response = await this.fetchChatResponse(userQuery);
    return this.processResponse(response);
  }

  createChatMessage(userQuery, imgUrlPath) {
    const content = imgUrlPath.trim() 
      ? [
          { type: 'text', text: userQuery },
          { type: 'image_url', image_url: { url: imgUrlPath }}
        ]
      : userQuery;

    return {
      role: 'user',
      content: content
    };
  }

  async fetchChatResponse(userQuery) {
    const url = this.buildChatApiUrl();
    const body = this.buildRequestBody();

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'api-key': this.config.azureOpenAIApiKey,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    });

    if (!response.ok) {
      throw new Error(`Chat API response status: ${response.status} ${response.statusText}`);
    }

    return response;
  }

  buildChatApiUrl() {
    const { azureOpenAIEndpoint, azureOpenAIDeploymentName } = this.config;
    const baseUrl = this.dataSources.length > 0
      ? `${azureOpenAIEndpoint}/openai/deployments/${azureOpenAIDeploymentName}/extensions/chat/completions`
      : `${azureOpenAIEndpoint}/openai/deployments/${azureOpenAIDeploymentName}/chat/completions`;
    
    return `${baseUrl}?api-version=2023-06-01-preview`;
  }

  buildRequestBody() {
    const body = {
      messages: this.messages,
      stream: true
    };

    if (this.dataSources.length > 0) {
      body.dataSources = this.dataSources;
    }

    return body;
  }
}

// Express routes
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.post('/api/chat', async (req, res) => {
  try {
    const chatHandler = new ChatHandler(req.body.config);
    const response = await chatHandler.handleUserQuery(req.body.query);
    res.json(response);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = {
  AvatarHandler,
  ChatHandler,
  setupWebRTC
};