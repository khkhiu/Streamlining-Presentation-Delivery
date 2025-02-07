// config.js

// Load environment variables from .env file in development
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config();
  }
  
  // Validate required environment variables
  const requiredEnvVars = [
    'REACT_APP_COG_SVC_REGION',
    'REACT_APP_COG_SVC_KEY',
    'REACT_APP_ICE_URL',
    'REACT_APP_ICE_USERNAME',
    'REACT_APP_ICE_CREDENTIAL'
  ];
  
  const missingEnvVars = requiredEnvVars.filter(varName => !process.env[varName]);
  if (missingEnvVars.length > 0) {
    throw new Error(`Missing required environment variables: ${missingEnvVars.join(', ')}`);
  }
  
  export const avatarAppConfig = {
    cogSvcRegion: process.env.REACT_APP_COG_SVC_REGION,
    cogSvcSubKey: process.env.REACT_APP_COG_SVC_KEY,
    voiceName: process.env.REACT_APP_VOICE_NAME || "en-US-JennyNeural", // Providing default if not specified
    avatarCharacter: process.env.REACT_APP_AVATAR_CHARACTER || "lisa",
    avatarStyle: process.env.REACT_APP_AVATAR_STYLE || "casual-sitting",
    avatarBackgroundColor: process.env.REACT_APP_AVATAR_BG_COLOR || "#FFFFFFFF",
    iceUrl: process.env.REACT_APP_ICE_URL,
    iceUsername: process.env.REACT_APP_ICE_USERNAME,
    iceCredential: process.env.REACT_APP_ICE_CREDENTIAL
  }