import React, { useState } from 'react';

interface BasicAvatarModeProps {
  avatarConfig: any;
  isSdkReady: boolean;
  isSessionActive: boolean;
  isSpeaking: boolean;
  videoRef: React.RefObject<HTMLVideoElement | null>;
  audioRef: React.RefObject<HTMLAudioElement | null>;
  peerConnectionRef: React.RefObject<RTCPeerConnection | null>;
  avatarSynthesizerRef: React.RefObject<any>;
  setSessionActive: React.Dispatch<React.SetStateAction<boolean>>;
  setIsSpeaking: React.Dispatch<React.SetStateAction<boolean>>;
  startSession: () => Promise<void>;
  stopSession: () => void;
  speak: (text?: string) => Promise<void>;
  stopSpeaking: () => Promise<void>;
}

const BasicAvatarMode: React.FC<BasicAvatarModeProps> = ({
  avatarConfig,
  isSdkReady,
  isSessionActive,
  isSpeaking,
  videoRef,
  startSession,
  stopSession,
  speak,
  stopSpeaking
}) => {
  const [inputText, setInputText] = useState<string>("Hello world!");

  // Ensure audio playback and handle start session
  const handleStartSession = () => {
    const tempAudio = document.createElement('audio');
    tempAudio.src = 'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA';
    
    const playPromise = tempAudio.play();
    if (playPromise !== undefined) {
      playPromise
        .then(() => {
          console.log('Audio playback is allowed');
          tempAudio.remove();
          startSession();
        })
        .catch(error => {
          console.warn('Audio playback was prevented:', error);
        });
    }
  };

  return (
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
            onClick={() => speak()} 
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

export default BasicAvatarMode;