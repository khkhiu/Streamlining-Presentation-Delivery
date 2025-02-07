// config/speech.js
export const createSpeechConfig = (cogSvcSubKey, cogSvcRegion, privateEndpointEnabled, privateEndpoint) => {
    let speechSynthesisConfig;
    if (privateEndpointEnabled) {
        speechSynthesisConfig = SpeechSDK.SpeechConfig.fromEndpoint(
            new URL(`wss://${privateEndpoint}/tts/cognitiveservices/websocket/v1?enableTalkingAvatar=true`),
            cogSvcSubKey
        );
    } else {
        speechSynthesisConfig = SpeechSDK.SpeechConfig.fromSubscription(cogSvcSubKey, cogSvcRegion);
    }
    return speechSynthesisConfig;
};