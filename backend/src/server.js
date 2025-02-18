// server.js
const express = require('express');
const path = require('path');
const dotenv = require('dotenv');

// Load environment variables from .env file
dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Serve static files from public directory
app.use(express.static(path.join(__dirname, '..', 'public')));

// Serve configuration endpoint
app.get('/api/config', (req, res) => {
    // Return configuration from environment variables
    res.json({
        speech: {
            region: process.env.AZURE_SPEECH_REGION,
            apiKey: process.env.AZURE_SPEECH_API_KEY
        },
        openai: {
            endpoint: process.env.AZURE_OPENAI_ENDPOINT,
            apiKey: process.env.AZURE_OPENAI_API_KEY,
            deploymentName: process.env.AZURE_OPENAI_DEPLOYMENT_NAME,
            systemPrompt: process.env.AZURE_OPENAI_SYSTEM_PROMPT
        },
        stt: {
            locales: process.env.STT_LOCALES
        },
        tts: {
            voice: process.env.TTS_VOICE,
            customVoiceEndpointId: process.env.TTS_CUSTOM_VOICE_ENDPOINT_ID,
            personalVoiceSpeakerProfileId: process.env.TTS_PERSONAL_VOICE_SPEAKER_PROFILE_ID
        },
        avatar: {
            character: process.env.AVATAR_CHARACTER,
            style: process.env.AVATAR_STYLE,
            customized: process.env.AVATAR_CUSTOMIZED === 'true',
            autoReconnect: process.env.AVATAR_AUTO_RECONNECT === 'true',
            useLocalVideoForIdle: process.env.AVATAR_USE_LOCAL_VIDEO_FOR_IDLE === 'true'
        }
    });
});

// Serve index.html for root route
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '..', 'public', 'index.html'));
});

app.listen(port, () => {
    console.log(`Server is running at http://localhost:${port}`);
});