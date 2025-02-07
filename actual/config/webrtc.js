// config/webrtc.js
export const createWebRTCConfig = (iceServerUrl, iceServerUsername, iceServerCredential, useTcpForWebRTC = false) => ({
    iceServers: [{
        urls: [ useTcpForWebRTC ? iceServerUrl.replace(':3478', ':443?transport=tcp') : iceServerUrl ],
        username: iceServerUsername,
        credential: iceServerCredential
    }],
    iceTransportPolicy: useTcpForWebRTC ? 'relay' : 'all'
});