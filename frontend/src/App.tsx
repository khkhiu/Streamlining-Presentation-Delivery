import React, { useEffect, useRef, useState } from 'react';
import axios from 'axios';
import './App.css';

// Component imports
import BasicAvatarMode from './components/BasicAvatarMode';
import ChatAvatarMode from './components/ChatAvatarMode';

// Type definitions
interface AvatarConfig {
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
}

interface IceServerData {
  Urls: string[];
  Username: string;
  Password: string;
}

// Extending global window to include SpeechSDK
declare global {
  interface Window {
    SpeechSDK: any;
  }
}

const App: React.FC = () => {
  const [avatarConfig, setAvatarConfig] = useState<AvatarConfig | null>(null);
  const [isSessionActive, setSessionActive] = useState<boolean>(false);
  const [isSpeaking, setIsSpeaking] = useState<boolean>(false);
  const [inputText, setInputText] = useState<string>("Hello world!");
  const [isSdkReady, setSdkReady] = useState<boolean>(false);
  const [showChatMode, setShowChatMode] = useState<boolean>(false);
  
  const videoRef = useRef<HTMLVideoElement>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const peerConnectionRef = useRef<RTCPeerConnection | null>(null);
  const avatarSynthesizerRef = useRef<any>(null); // Type will be from SpeechSDK
  
  // Check if SDK is loaded when component mounts
  useEffect(() => {
    const checkSdk = () => {
      if (window.SpeechSDK) {
        console.log("Speech SDK loaded successfully");
        setSdkReady(true);
      } else {
        console.warn("Speech SDK not loaded yet, retrying...");
        setTimeout(checkSdk, 100);
      }
    };
    
    checkSdk();

    // Debug SDK loading
    console.log("window.SpeechSDK:", window.SpeechSDK);
    const sdkScript = document.querySelector('script[src*="csspeech"]');
    console.log("SDK Script found:", !!sdkScript);
  }, []);
  
  // Fetch initial configuration
  useEffect(() => {
    axios.get<AvatarConfig>('/api/config')
      .then(response => setAvatarConfig(response.data))
      .catch(error => console.error('Error loading configuration:', error));
  }, []);

  // Ensure audio playback is allowed
  const ensureAudioPlayback = () => {
    const tempAudio = document.createElement('audio');
    tempAudio.src = 'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA';
    
    // Try to play a silent audio to get permission
    const playPromise = tempAudio.play();
    
    if (playPromise !== undefined) {
      playPromise
        .then(() => {
          console.log('Audio playback is allowed');
          tempAudio.remove();
        })
        .catch(error => {
          console.warn('Audio playback was prevented:', error);
          // Audio playback was prevented, you might want to show a message to the user
        });
    }
  };

  // Set default audio output device
  // Use feature detection instead of type augmentation
  const setDefaultAudioOutput = async () => {
    try {
      // Check if the function exists on the object before calling it
      const mediaDevices = navigator.mediaDevices as any;
      if (mediaDevices && typeof mediaDevices.selectAudioOutput === 'function') {
        await mediaDevices.selectAudioOutput();
        console.log('Audio output device selected');
      }
    } catch (error) {
      console.warn('Could not select audio output device:', error);
    }
  };
  
  // Handle the Start Session button click
  const handleStartSession = () => {
    ensureAudioPlayback();
    startSession();
  };
  
  // Start avatar session
  const startSession = async (): Promise<void> => {
    if (!avatarConfig) {
      console.error("Avatar configuration not loaded");
      return;
    }
    
    if (!isSdkReady) {
      console.error("Speech SDK not loaded yet");
      return;
    }
    
    try {
      // Get WebRTC token from backend
      const tokenResponse = await axios.get<IceServerData>(
        `https://${avatarConfig.speech.region}.tts.speech.microsoft.com/cognitiveservices/avatar/relay/token/v1`, 
        {
          headers: {
            'Ocp-Apim-Subscription-Key': avatarConfig.speech.apiKey
          }
        }
      );
      
      const iceServerData = tokenResponse.data;
      
      // Make sure we're using the correct property names from the response
      console.log('ICE Server Data:', iceServerData); // Log to verify the structure
      
      // Check if response has the expected fields
      if (!iceServerData.Urls || !iceServerData.Urls.length || !iceServerData.Username || !iceServerData.Password) {
        console.error('Invalid ICE server data received:', iceServerData);
        return;
      }
      
      setupWebRTC(
        iceServerData.Urls[0],
        iceServerData.Username,
        iceServerData.Password
      );
      
      setSessionActive(true);
    } catch (error) {
      console.error('Failed to start avatar session:', error);
    }
  };
  
  // Set up WebRTC connection
  const setupWebRTC = (
    iceServerUrl: string, 
    iceServerUsername: string, 
    iceServerCredential: string
  ): void => {
    if (!avatarConfig) return;
    
    // Create WebRTC peer connection with ICE servers
    const peerConnection = new RTCPeerConnection({
      iceServers: [{
        urls: [iceServerUrl],
        username: iceServerUsername,
        credential: iceServerCredential
      }]
    });
    
    peerConnectionRef.current = peerConnection;
    
    // Handle incoming tracks (video/audio)
    peerConnection.ontrack = (event: RTCTrackEvent) => {
      if (event.track.kind === 'video' && videoRef.current && event.streams[0]) {
        videoRef.current.srcObject = event.streams[0];
      } else if (event.track.kind === 'audio') {
        // Create an audio element for the audio track
        const audioElement = document.createElement('audio');
        audioElement.srcObject = event.streams[0];
        audioElement.autoplay = true;
        // Important: Make sure audio is not muted
        audioElement.muted = false;
        // Add it to the DOM (can be hidden)
        audioElement.style.display = 'none';
        document.body.appendChild(audioElement);
        
        // Keep a reference to clean up later
        audioRef.current = audioElement;
        
        // Make sure the audio element is not muted when it starts playing
        audioElement.addEventListener('play', () => {
          console.log('Audio started playing');
          audioElement.muted = false;
          audioElement.volume = 1.0;
        });
        
        // Set default audio output
        setDefaultAudioOutput();
      }
    };
    
    // Add transceivers for audio and video
    peerConnection.addTransceiver('video', { direction: 'sendrecv' });
    peerConnection.addTransceiver('audio', { direction: 'sendrecv' });
    
    // Listen for WebRTC connection state changes
    peerConnection.oniceconnectionstatechange = () => {
      console.log(`WebRTC status: ${peerConnection.iceConnectionState}`);
      
      if (peerConnection.iceConnectionState === 'connected') {
        // We could trigger the audio output selection here as well
        setDefaultAudioOutput();
      }
    };
    
    // Setup data channel for events
    const dataChannel = peerConnection.createDataChannel("eventChannel");
    dataChannel.onmessage = (event) => {
      console.log(`WebRTC event received: ${event.data}`);
    };
    
    // Initialize avatar synthesizer and start avatar
    if (!window.SpeechSDK) {
      console.error("Speech SDK not available");
      return;
    }
    
    const speechConfig = window.SpeechSDK.SpeechConfig.fromSubscription(
      avatarConfig.speech.apiKey, 
      avatarConfig.speech.region
    );
    
    // Set high quality audio output format
    speechConfig.speechSynthesisOutputFormat = window.SpeechSDK.SpeechSynthesisOutputFormat.Audio24Khz160KBitRateMonoMp3;
    
    const avatarSdkConfig = new window.SpeechSDK.AvatarConfig(
      avatarConfig.avatar.character,
      avatarConfig.avatar.style
    );
    
    // Set customized flag if needed
    avatarSdkConfig.customized = avatarConfig.avatar.customized;
    
    const synthesizer = new window.SpeechSDK.AvatarSynthesizer(
      speechConfig, 
      avatarSdkConfig
    );
    
    // Set up event handler
    synthesizer.avatarEventReceived = (s: any, e: any) => {
      console.log(`Event received: ${e.description}`);
    };
    
    avatarSynthesizerRef.current = synthesizer;
    
    // Start the avatar with the WebRTC connection
    synthesizer.startAvatarAsync(peerConnection)
      .then((result: any) => {
        if (result.reason === window.SpeechSDK.ResultReason.SynthesizingAudioCompleted) {
          console.log(`Avatar started. Result ID: ${result.resultId}`);
        } else {
          console.log(`Unable to start avatar. Result ID: ${result.resultId}`);
        }
      })
      .catch((error: any) => {
        console.error('Avatar failed to start:', error);
      });
  };
  
  // Make the avatar speak
  const speak = async (text?: string): Promise<void> => {
    if (!avatarSynthesizerRef.current || !isSessionActive || !avatarConfig) return;
    
    // Use provided text or fallback to inputText state
    const textToSpeak = text || inputText;
    
    setIsSpeaking(true);
    
    try {
      const voice = avatarConfig.tts.voice;
      const personalVoiceId = avatarConfig.tts.personalVoiceSpeakerProfileId || '';
      
      // Create SSML with proper HTML encoding
      const encodedText = textToSpeak.replace(/&/g, '&amp;')
                                   .replace(/</g, '&lt;')
                                   .replace(/>/g, '&gt;')
                                   .replace(/"/g, '&quot;')
                                   .replace(/'/g, '&#39;');
      
      const ssml = `<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xmlns:mstts='http://www.w3.org/2001/mstts' xml:lang='en-US'>
        <voice name='${voice}'>
          <mstts:ttsembedding speakerProfileId='${personalVoiceId}'>
            <mstts:leadingsilence-exact value='0'/>
            ${encodedText}
          </mstts:ttsembedding>
        </voice>
      </speak>`;
      
      // Ensure any audio element is not muted
      if (audioRef.current) {
        audioRef.current.muted = false;
        audioRef.current.volume = 1.0;
      }
      
      const result = await avatarSynthesizerRef.current.speakSsmlAsync(ssml);
      
      if (result.reason === window.SpeechSDK.ResultReason.SynthesizingAudioCompleted) {
        console.log(`Speech synthesized. Result ID: ${result.resultId}`);
      } else {
        console.log(`Error occurred while speaking. Result ID: ${result.resultId}`);
      }
      
      setIsSpeaking(false);
    } catch (error) {
      console.error('Error making avatar speak:', error);
      setIsSpeaking(false);
    }
  };
  
  // Stop speaking
  const stopSpeaking = async (): Promise<void> => {
    if (avatarSynthesizerRef.current) {
      try {
        await avatarSynthesizerRef.current.stopSpeakingAsync();
        console.log('Stop speaking request sent.');
        setIsSpeaking(false);
      } catch (error) {
        console.error('Error stopping speaking:', error);
      }
    }
  };
  
  // End session
  const stopSession = (): void => {
    if (avatarSynthesizerRef.current) {
      avatarSynthesizerRef.current.close();
    }
    
    if (peerConnectionRef.current) {
      peerConnectionRef.current.close();
    }
    
    // Clean up audio element
    if (audioRef.current) {
      audioRef.current.srcObject = null;
      audioRef.current.remove();
      audioRef.current = null;
    }
    
    setSessionActive(false);
    setIsSpeaking(false);
    console.log('Avatar session closed');
  };
  
  return (
    <div className="avatar-container">
      <div className="header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <h2>Talking Avatar</h2>
        <button 
          onClick={() => {
            // Make sure to stop any active session before switching modes
            if (isSessionActive) {
              stopSession();
            }
            setShowChatMode(!showChatMode);
          }}
          style={{ 
            padding: '8px 16px', 
            backgroundColor: '#4CAF50', 
            color: 'white', 
            border: 'none', 
            borderRadius: '4px',
            cursor: 'pointer'
          }}
        >
          Switch to {showChatMode ? 'Basic' : 'Chat'} Mode
        </button>
      </div>
      
      {showChatMode ? (
        // Chat Avatar Mode
        <ChatAvatarMode 
          avatarConfig={avatarConfig}
          isSdkReady={isSdkReady}
          isSessionActive={isSessionActive}
          isSpeaking={isSpeaking}
          videoRef={videoRef}
          audioRef={audioRef}
          peerConnectionRef={peerConnectionRef}
          avatarSynthesizerRef={avatarSynthesizerRef}
          setSessionActive={setSessionActive}
          setIsSpeaking={setIsSpeaking}
          startSession={startSession}
          stopSession={stopSession}
          speak={speak}
          stopSpeaking={stopSpeaking}
        />
      ) : (
        // Basic Avatar Mode
        <div>
          {/* Video display */}
          <div className="video-container" style={{ position: 'relative', width: '960px' }}>
            <video 
              ref={videoRef}
              autoPlay 
              playsInline
              style={{ width: '100%', height: 'auto' }}
            />
            
            {/* Subtitles */}
            <div 
              style={{ 
                position: 'absolute',
                bottom: '5%',
                width: '100%',
                textAlign: 'center',
                color: 'white',
                textShadow: '-1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000',
                fontSize: '22px',
                display: isSpeaking ? 'block' : 'none'
              }}
            >
              {isSpeaking ? inputText : ''}
            </div>
          </div>
          
          {/* Avatar controls */}
          <div className="controls" style={{ marginTop: '20px' }}>
            <textarea
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              disabled={!isSessionActive}
              rows={3}
              style={{ width: '100%', marginBottom: '10px', padding: '8px' }}
              placeholder="Enter text for the avatar to speak"
            />
            
            <div className="buttons" style={{ display: 'flex', gap: '10px' }}>
              <button 
                onClick={handleStartSession} 
                disabled={isSessionActive || !avatarConfig || !isSdkReady}
                style={{ padding: '8px 16px' }}
              >
                Start Session
              </button>
              
              <button 
                onClick={() => speak(inputText)} 
                disabled={!isSessionActive || isSpeaking}
                style={{ padding: '8px 16px' }}
              >
                Speak
              </button>
              
              <button 
                onClick={stopSpeaking} 
                disabled={!isSpeaking}
                style={{ padding: '8px 16px' }}
              >
                Stop Speaking
              </button>
              
              <button 
                onClick={stopSession} 
                disabled={!isSessionActive}
                style={{ padding: '8px 16px' }}
              >
                Stop Session
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default App;