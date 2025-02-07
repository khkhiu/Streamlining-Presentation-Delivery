// config/azure.js
export const getAzureConfig = () => {
    const config = {
        region: import.meta.env.VITE_AZURE_SPEECH_REGION,
        speechKey: import.meta.env.VITE_AZURE_SPEECH_KEY,
        privateEndpoint: import.meta.env.VITE_AZURE_PRIVATE_ENDPOINT || null
    };

    if (!config.region || !config.speechKey) {
        throw new Error(
            'Missing required Azure configuration. Please ensure VITE_AZURE_SPEECH_REGION and VITE_AZURE_SPEECH_KEY are set in your .env file'
        );
    }

    return config;
};