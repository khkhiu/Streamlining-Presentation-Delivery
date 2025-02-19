const express = require('express');
const path = require('path');
const dotenv = require('dotenv');
const cors = require('cors');
const app = express();
const port = process.env.PORT || 3000;

// Load environment variables from .env file
dotenv.config();

// Middleware for parsing JSON bodies
app.use(express.json());

// Serve static files from public directory
//app.use(express.static(path.join(__dirname, '..', 'public')));

// Enable CORS for Flutter frontend
app.use(cors({
    origin: ['http://localhost:34887', 'http://localhost:3000'],
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: [
        'Content-Type',
        'Authorization',
        'Access-Control-Allow-Origin',
        'Access-Control-Allow-Methods',
        'Access-Control-Allow-Headers'
    ],
    credentials: true,
    optionsSuccessStatus: 204
}));

// Store active session state
let activeSession = null;
let isSpeaking = false;

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

// Start session endpoint
app.post('/startSession', (req, res) => {
    try {
        const sessionConfig = req.body;
        // Initialize your avatar session here with the config
        activeSession = sessionConfig;
        res.status(200).json({ message: 'Session started successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Speak endpoint
app.post('/speak', (req, res) => {
    try {
        if (!activeSession) {
            throw new Error('No active session');
        }
        const { text } = req.body;
        if (!text) {
            throw new Error('No text provided');
        }
        isSpeaking = true;
        // Implement your text-to-speech logic here
        res.status(200).json({ message: 'Speaking started' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Stop speaking endpoint
app.post('/stopSpeaking', (req, res) => {
    try {
        if (!activeSession) {
            throw new Error('No active session');
        }
        isSpeaking = false;
        // Implement your stop speaking logic here
        res.status(200).json({ message: 'Speaking stopped' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Stop session endpoint
app.post('/stopSession', (req, res) => {
    try {
        if (!activeSession) {
            throw new Error('No active session');
        }
        // Clean up session resources here
        activeSession = null;
        isSpeaking = false;
        res.status(200).json({ message: 'Session stopped successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Serve index.html for root route
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '..', 'public', 'index.html'));
});

app.listen(port, () => {
    console.log(`Server is running at http://localhost:${port}`);
});