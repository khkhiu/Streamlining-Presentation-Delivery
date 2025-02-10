// config/environment.ts
interface EnvironmentConfig {
    azure: {
      apiKey: string;
      region: string;
    }
  }
  
  export const getEnvironmentConfig = (): EnvironmentConfig => {
    if (!process.env.NEXT_PUBLIC_AZURE_API_KEY) {
      console.warn('Azure API key not found in environment variables');
    }
  
    return {
      azure: {
        apiKey: process.env.NEXT_PUBLIC_AZURE_API_KEY || '',
        region: process.env.NEXT_PUBLIC_AZURE_REGION || 'westus2',
      }
    }
  }