// src/App.jsx
import { useState, useEffect, useRef } from 'react';
import { AvatarService } from './services/AvatarService';
import ConfigPanel from './components/ConfigPanel';
import VideoPanel from './components/VideoPanel';
import Controls from './components/Controls';
import Logger from './components/Logger';
import './App.css';

function App() {
  const [isSessionActive, setIsSessionActive] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [logs, setLogs] = useState([]);
  const avatarServiceRef = useRef(null);
  
  useEffect(() => {
    avatarServiceRef.current = new AvatarService({
      onLog: (message) => setLogs(prev => [...prev, message])
    });
    
    return () => {
      if (avatarServiceRef.current) {
        avatarServiceRef.current.stopSession();
      }
    };
  }, []);

  const handleStartSession = async (config) => {
    try {
      await avatarServiceRef.current.startSession(config);
      setIsSessionActive(true);
    } catch (error) {
      setLogs(prev => [...prev, `Error starting session: ${error.message}`]);
    }
  };

  const handleStopSession = () => {
    avatarServiceRef.current.stopSession();
    setIsSessionActive(false);
    setIsSpeaking(false);
  };

  const handleSpeak = async (text, voice, speakerProfileId) => {
    try {
      setIsSpeaking(true);
      await avatarServiceRef.current.speak(text, voice, speakerProfileId);
    } catch (error) {
      setLogs(prev => [...prev, `Error during speech: ${error.message}`]);
    } finally {
      setIsSpeaking(false);
    }
  };

  const handleStopSpeaking = async () => {
    try {
      await avatarServiceRef.current.stopSpeaking();
      setIsSpeaking(false);
    } catch (error) {
      setLogs(prev => [...prev, `Error stopping speech: ${error.message}`]);
    }
  };

  return (
    <div className="app">
      <ConfigPanel 
        onStartSession={handleStartSession}
        disabled={isSessionActive}
      />
      
      <VideoPanel 
        isSessionActive={isSessionActive}
      />
      
      <Controls
        isSessionActive={isSessionActive}
        isSpeaking={isSpeaking}
        onSpeak={handleSpeak}
        onStopSpeaking={handleStopSpeaking}
        onStopSession={handleStopSession}
      />
      
      <Logger logs={logs} />
    </div>
  );
}

export default App;