// config.js

// Validate required environment variables
const requiredEnvVars = [
    'REACT_APP_COG_SVC_REGION',
    'REACT_APP_COG_SVC_KEY',
    'REACT_APP_ICE_URL',
    'REACT_APP_ICE_USERNAME',
    'REACT_APP_ICE_CREDENTIAL'
  ];
  
  // Check for missing environment variables
  const missingEnvVars = requiredEnvVars.filter(varName => !import.meta.env[varName]);
  if (missingEnvVars.length > 0) {
    throw new Error(`Missing required environment variables: ${missingEnvVars.join(', ')}`);
  }
  
  export const avatarAppConfig = {
    cogSvcRegion: import.meta.env.REACT_APP_COG_SVC_REGION,
    cogSvcSubKey: import.meta.env.REACT_APP_COG_SVC_KEY,
    voiceName: import.meta.env.REACT_APP_VOICE_NAME || "en-US-JennyNeural",
    avatarCharacter: import.meta.env.REACT_APP_AVATAR_CHARACTER || "lisa",
    avatarStyle: import.meta.env.REACT_APP_AVATAR_STYLE || "casual-sitting",
    avatarBackgroundColor: import.meta.env.REACT_APP_AVATAR_BG_COLOR || "#FFFFFFFF",
    iceUrl: import.meta.env.REACT_APP_ICE_URL,
    iceUsername: import.meta.env.REACT_APP_ICE_USERNAME,
    iceCredential: import.meta.env.REACT_APP_ICE_CREDENTIAL
  }