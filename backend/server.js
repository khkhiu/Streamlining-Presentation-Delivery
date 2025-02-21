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

// Log the current directory and public path for debugging
console.log('Current directory:', __dirname);
console.log('Public directory:', path.join(__dirname, 'public'));

// Serve static files from public directory
app.use(express.static(path.join(__dirname, 'public')));

// Enable CORS
app.use(cors({
    origin: '*',
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
    res.json({
        speech: {
            region: process.env.AZURE_SPEECH_REGION || '',
            apiKey: process.env.AZURE_SPEECH_API_KEY || ''
        },
        openai: {
            endpoint: process.env.AZURE_OPENAI_ENDPOINT || '',
            apiKey: process.env.AZURE_OPENAI_API_KEY || '',
            deploymentName: process.env.AZURE_OPENAI_DEPLOYMENT_NAME || '',
            systemPrompt: process.env.AZURE_OPENAI_SYSTEM_PROMPT || ''
        },
        stt: {
            locales: process.env.STT_LOCALES || 'en-US'
        },
        tts: {
            voice: process.env.TTS_VOICE || '',
            customVoiceEndpointId: process.env.TTS_CUSTOM_VOICE_ENDPOINT_ID || '',
            personalVoiceSpeakerProfileId: process.env.TTS_PERSONAL_VOICE_SPEAKER_PROFILE_ID || ''
        },
        avatar: {
            character: process.env.AVATAR_CHARACTER || '',
            style: process.env.AVATAR_STYLE || '',
            customized: process.env.AVATAR_CUSTOMIZED === 'true',
            autoReconnect: process.env.AVATAR_AUTO_RECONNECT === 'true',
            useLocalVideoForIdle: process.env.AVATAR_USE_LOCAL_VIDEO_FOR_IDLE === 'true'
        }
    });
});

// Define routes for different HTML pages
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'basic.html'));
});

app.get('/basic', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'basic.html'));
});

app.get('/chat', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'chat.html'));
});

// Session management endpoints
app.post('/startSession', (req, res) => {
    try {
        const sessionConfig = req.body;
        activeSession = sessionConfig;
        res.status(200).json({ message: 'Session started successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

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
        res.status(200).json({ message: 'Speaking started' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/stopSpeaking', (req, res) => {
    try {
        if (!activeSession) {
            throw new Error('No active session');
        }
        isSpeaking = false;
        res.status(200).json({ message: 'Speaking stopped' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/stopSession', (req, res) => {
    try {
        if (!activeSession) {
            throw new Error('No active session');
        }
        activeSession = null;
        isSpeaking = false;
        res.status(200).json({ message: 'Session stopped successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err.stack);
    res.status(500).json({
        error: 'Internal Server Error',
        message: err.message
    });
});

// Start the server
app.listen(port, () => {
    console.log(`Server is running at http://localhost:${port}`);
    console.log(`Basic demo available at http://localhost:${port}/basic`);
    console.log(`Chat demo available at http://localhost:${port}/chat`);
});