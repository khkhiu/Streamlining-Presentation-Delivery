// src/components/Controls.jsx
import { useState } from 'react';

function Controls({ isSessionActive, isSpeaking, onSpeak, onStopSpeaking, onStopSession }) {
  const [text, setText] = useState('');
  const [voice, setVoice] = useState('');
  const [speakerProfileId, setSpeakerProfileId] = useState('');

  const handleSpeak = (e) => {
    e.preventDefault();
    onSpeak(text, voice, speakerProfileId);
  };

  return (
    <div className="controls">
      <form onSubmit={handleSpeak}>
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          disabled={!isSessionActive || isSpeaking}
          placeholder="Enter text to speak..."
        />
        <input
          type="text"
          value={voice}
          onChange={(e) => setVoice(e.target.value)}
          disabled={!isSessionActive || isSpeaking}
          placeholder="Voice name"
        />
        <input
          type="text"
          value={speakerProfileId}
          onChange={(e) => setSpeakerProfileId(e.target.value)}
          disabled={!isSessionActive || isSpeaking}
          placeholder="Speaker Profile ID"
        />
        <button type="submit" disabled={!isSessionActive || isSpeaking}>
          Speak
        </button>
      </form>
      
      <button
        onClick={onStopSpeaking}
        disabled={!isSessionActive || !isSpeaking}
      >
        Stop Speaking
      </button>
      
      <button
        onClick={onStopSession}
        disabled={!isSessionActive}
      >
        Stop Session
      </button>
    </div>
  );
}

export default Controls;