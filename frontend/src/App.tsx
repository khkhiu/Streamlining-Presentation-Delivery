import React, { useEffect, useRef, useState } from 'react';
import axios from 'axios';

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

const TalkingAvatarComponent: React.FC = () => {
  const [avatarConfig, setAvatarConfig] = useState<AvatarConfig | null>(null);
  const [isSessionActive, setSessionActive] = useState<boolean>(false);
  const [isSpeaking, setIsSpeaking] = useState<boolean>(false);
  const [inputText, setInputText] = useState<string>("Hello world!");
  
  const videoRef = useRef<HTMLVideoElement>(null);
  const peerConnectionRef = useRef<RTCPeerConnection | null>(null);
  const avatarSynthesizerRef = useRef<any>(null); // Type will be from SpeechSDK
  
  // Fetch initial configuration
  useEffect(() => {
    axios.get<AvatarConfig>('/api/config')
      .then(response => setAvatarConfig(response.data))
      .catch(error => console.error('Error loading configuration:', error));
  }, []);
  
  // Start avatar session
  const startSession = async (): Promise<void> => {
    if (!avatarConfig) return;
    
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
        iceServerData.Password  // Use Password from the response, not Credential
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
        // This is the problem - the property should be "credential", not "iceServerCredential"
        credential: iceServerCredential  // Use "credential" here, not a different property name
      }]
    });
    
    peerConnectionRef.current = peerConnection;
    
    // Handle incoming tracks (video/audio)
    peerConnection.ontrack = (event: RTCTrackEvent) => {
      if (event.track.kind === 'video' && videoRef.current && event.streams[0]) {
        videoRef.current.srcObject = event.streams[0];
      }
    };
    
    // Add transceivers for audio and video
    peerConnection.addTransceiver('video', { direction: 'sendrecv' });
    peerConnection.addTransceiver('audio', { direction: 'sendrecv' });
    
    // Listen for WebRTC connection state changes
    peerConnection.oniceconnectionstatechange = () => {
      console.log(`WebRTC status: ${peerConnection.iceConnectionState}`);
    };
    
    // Initialize avatar synthesizer and start avatar
    const speechConfig = window.SpeechSDK.SpeechConfig.fromSubscription(
      avatarConfig.speech.apiKey, 
      avatarConfig.speech.region
    );
    
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
  const speak = async (): Promise<void> => {
    if (!avatarSynthesizerRef.current || !isSessionActive || !avatarConfig) return;
    
    setIsSpeaking(true);
    
    try {
      const voice = avatarConfig.tts.voice;
      const personalVoiceId = avatarConfig.tts.personalVoiceSpeakerProfileId || '';
      
      // Create SSML with proper HTML encoding
      const encodedText = inputText.replace(/&/g, '&amp;')
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
    
    setSessionActive(false);
    setIsSpeaking(false);
    console.log('Avatar session closed');
  };
  
  return (
    <div className="avatar-container">
      <h2>Talking Avatar</h2>
      
      {/* Video display */}
      <div className="video-container" style={{ position: 'relative', width: '960px' }}>
        <video 
          ref={videoRef}
          autoPlay 
          playsInline
          style={{ width: '100%', height: 'auto' }}
        />
        
        {/* Subtitles would go here */}
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
            onClick={startSession} 
            disabled={isSessionActive || !avatarConfig}
            style={{ padding: '8px 16px' }}
          >
            Start Session
          </button>
          
          <button 
            onClick={speak} 
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
  );
};

export default TalkingAvatarComponent;