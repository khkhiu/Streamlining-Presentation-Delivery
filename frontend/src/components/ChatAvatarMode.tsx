import React, { useState, useRef, useEffect } from 'react';

interface Message {
  text: string;
  isUser: boolean;
  timestamp: Date;
}

interface ChatAvatarModeProps {
  avatarConfig: any;
  isSdkReady: boolean;
  isSessionActive: boolean;
  isSpeaking: boolean;
  videoRef: React.RefObject<HTMLVideoElement>;
  audioRef: React.RefObject<HTMLAudioElement>;
  peerConnectionRef: React.RefObject<RTCPeerConnection>;
  avatarSynthesizerRef: React.RefObject<any>;
  setSessionActive: React.Dispatch<React.SetStateAction<boolean>>;
  setIsSpeaking: React.Dispatch<React.SetStateAction<boolean>>;
  startSession: () => Promise<void>;
  stopSession: () => void;
  speak: (text?: string) => Promise<void>;
  stopSpeaking: () => Promise<void>;
}

const ChatAvatarMode: React.FC<ChatAvatarModeProps> = ({
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
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputMessage, setInputMessage] = useState<string>("");
  const [isRecording, setIsRecording] = useState<boolean>(false);
  const chatHistoryRef = useRef<HTMLDivElement>(null);
  
  // Scroll to bottom of chat when messages change
  useEffect(() => {
    if (chatHistoryRef.current) {
      chatHistoryRef.current.scrollTop = chatHistoryRef.current.scrollHeight;
    }
  }, [messages]);

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

  const handleSendMessage = async () => {
    if (!inputMessage.trim()) return;
    
    // Add user message to chat
    const userMessage: Message = {
      text: inputMessage,
      isUser: true,
      timestamp: new Date()
    };
    
    setMessages(prev => [...prev, userMessage]);
    setInputMessage("");
    
    // In a real app, you would process this message with a backend service
    // For now, we'll just make the avatar speak it and then add a simple response
    
    try {
      // Avatar speaks user's message
      await speak(inputMessage);
      
      // Simulate assistant response
      setTimeout(() => {
        const botMessage: Message = {
          text: `I received your message: "${inputMessage}". How can I assist you further?`,
          isUser: false,
          timestamp: new Date()
        };
        
        setMessages(prev => [...prev, botMessage]);
        
        // Make avatar speak the response
        speak(botMessage.text);
      }, 1000);
    } catch (error) {
      console.error('Error processing message:', error);
    }
  };

  const toggleMicrophone = () => {
    // In a real implementation, this would start/stop speech recognition
    setIsRecording(!isRecording);
    
    if (!isRecording) {
      // Start recording - this would use the Speech SDK in a real implementation
      console.log('Starting microphone...');
    } else {
      // Stop recording
      console.log('Stopping microphone...');
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'row', gap: '20px' }}>
      {/* Left side - Avatar Video */}
      <div style={{ flex: 1 }}>
        <div className="video-container" style={{ position: 'relative', width: '100%', marginBottom: '16px' }}>
          <video 
            ref={videoRef}
            autoPlay 
            playsInline
            style={{ width: '100%', height: 'auto', borderRadius: '8px' }}
          />
        </div>
        
        {/* Video controls */}
        <div className="buttons" style={{ display: 'flex', justifyContent: 'center', gap: '10px' }}>
          <button 
            onClick={handleStartSession} 
            disabled={isSessionActive || !avatarConfig || !isSdkReady}
            style={{ padding: '8px 16px' }}
          >
            Start Session
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
      
      {/* Right side - Chat Interface */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', height: '540px', border: '1px solid #ddd', borderRadius: '8px' }}>
        {/* Chat history */}
        <div 
          ref={chatHistoryRef}
          style={{ 
            flex: 1, 
            padding: '16px', 
            overflowY: 'auto',
            display: 'flex',
            flexDirection: 'column',
            gap: '8px'
          }}
        >
          {messages.length === 0 ? (
            <div style={{ 
              display: 'flex', 
              justifyContent: 'center', 
              alignItems: 'center', 
              height: '100%',
              color: '#888'
            }}>
              Start a conversation with the avatar
            </div>
          ) : (
            messages.map((message, index) => (
              <div 
                key={index} 
                style={{
                  alignSelf: message.isUser ? 'flex-end' : 'flex-start',
                  maxWidth: '70%',
                  backgroundColor: message.isUser ? '#DCF8C6' : '#F1F0F0',
                  padding: '12px',
                  borderRadius: '8px',
                }}
              >
                <div style={{ fontWeight: 'bold' }}>
                  {message.isUser ? 'You' : 'Avatar'}
                </div>
                <div>{message.text}</div>
                <div style={{ fontSize: '0.8em', color: '#888', textAlign: 'right' }}>
                  {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </div>
              </div>
            ))
          )}
        </div>
        
        {/* Message input */}
        <div style={{ 
          display: 'flex', 
          padding: '16px', 
          borderTop: '1px solid #ddd',
          alignItems: 'center',
          gap: '8px'
        }}>
          <button
            onClick={toggleMicrophone}
            disabled={!isSessionActive}
            style={{
              backgroundColor: isRecording ? '#f44336' : '#e0e0e0',
              color: isRecording ? 'white' : 'black',
              border: 'none',
              borderRadius: '50%',
              width: '40px',
              height: '40px',
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              cursor: isSessionActive ? 'pointer' : 'not-allowed'
            }}
          >
            <span role="img" aria-label="microphone">🎤</span>
          </button>
          
          <textarea
            value={inputMessage}
            onChange={(e) => setInputMessage(e.target.value)}
            onKeyPress={handleKeyPress}
            disabled={!isSessionActive}
            placeholder="Type your message..."
            style={{
              flex: 1,
              padding: '12px',
              borderRadius: '4px',
              border: '1px solid #ddd',
              resize: 'none',
              minHeight: '24px',
              maxHeight: '120px'
            }}
            rows={1}
          />
          
          <button
            onClick={handleSendMessage}
            disabled={!isSessionActive || !inputMessage.trim()}
            style={{
              backgroundColor: '#4CAF50',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              padding: '12px',
              cursor: isSessionActive && inputMessage.trim() ? 'pointer' : 'not-allowed'
            }}
          >
            Send
          </button>
        </div>
      </div>
    </div>
  );
};

export default ChatAvatarMode;