// src/config/environment.ts
interface EnvironmentConfig {
  azure: {
    apiKey: string;
    region: string;
  }
}

export const getEnvironmentConfig = (): EnvironmentConfig => {
  if (!import.meta.env.VITE_AZURE_API_KEY) {
    console.warn('Azure API key not found in environment variables');
  }

  return {
    azure: {
      apiKey: import.meta.env.VITE_AZURE_API_KEY || '',
      region: import.meta.env.VITE_AZURE_REGION || 'westus2',
    }
  }
}