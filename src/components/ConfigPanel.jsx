// src/components/ConfigPanel.jsx
import { useState } from 'react';
import { getAzureConfig } from '../config/azure';

function ConfigPanel({ onStartSession, disabled }) {
  const azureConfig = getAzureConfig();
  
  const [config, setConfig] = useState({
    cogSvcRegion: azureConfig.region, // Pre-filled from environment
    privateEndpointEnabled: !!azureConfig.privateEndpoint,
    privateEndpoint: azureConfig.privateEndpoint || '',
    customVoiceEndpointId: '',
    talkingAvatarCharacter: '',
    talkingAvatarStyle: '',
    transparentBackground: false,
    videoCrop: false,
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    onStartSession(config);
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setConfig(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  return (
    <form onSubmit={handleSubmit} className="config-panel">
      <div className="form-group">
        <label htmlFor="cogSvcRegion">Region:</label>
        <input
          type="text"
          id="cogSvcRegion"
          name="cogSvcRegion"
          value={config.cogSvcRegion}
          onChange={handleChange}
          disabled={disabled}
        />
      </div>
      
      {/* Add other configuration inputs similarly */}
      
      <button type="submit" disabled={disabled}>
        Start Session
      </button>
    </form>
  );
}

export default ConfigPanel;