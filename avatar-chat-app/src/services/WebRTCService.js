// src/services/WebRTCService.js - Complete Implementation
class WebRTCService {
    constructor(config) {
      this.config = config;
      this.peerConnection = null;
      this.dataChannel = null;
      this.onTrackCallback = null;
    }
  
    setupWebRTC(iceServerConfig) {
      this.peerConnection = new RTCPeerConnection({
        iceServers: [{
          urls: [iceServerConfig.iceServerUrl],
          username: iceServerConfig.iceServerUsername,
          credential: iceServerConfig.iceServerCredential
        }]
      });
  
      this.setupEventHandlers();
      this.createDataChannel();
      this.setupMediaTransceivers();
  
      return this.peerConnection;
    }
  
    setupEventHandlers() {
      this.peerConnection.ontrack = (event) => {
        console.log(`Received ${event.track.kind} track`);
        if (this.onTrackCallback) {
          this.onTrackCallback(event);
        }
      };
  
      this.peerConnection.oniceconnectionstatechange = () => {
        console.log(`WebRTC status: ${this.peerConnection.iceConnectionState}`);
        if (this.peerConnection.iceConnectionState === 'disconnected') {
          this.handleDisconnection();
        }
      };
  
      this.peerConnection.ondatachannel = (event) => {
        const dataChannel = event.channel;
        dataChannel.onmessage = (e) => {
          console.log(`[${new Date().toISOString()}] WebRTC event received: ${e.data}`);
        };
      };
    }
  
    createDataChannel() {
      this.dataChannel = this.peerConnection.createDataChannel("eventChannel");
      this.dataChannel.onmessage = (event) => {
        console.log(`Data channel message received: ${event.data}`);
      };
    }
  
    setupMediaTransceivers() {
      this.peerConnection.addTransceiver('video', { direction: 'sendrecv' });
      this.peerConnection.addTransceiver('audio', { direction: 'sendrecv' });
    }
  
    async createOffer() {
      try {
        const offer = await this.peerConnection.createOffer();
        await this.peerConnection.setLocalDescription(offer);
        return offer;
      } catch (error) {
        console.error('Error creating offer:', error);
        throw error;
      }
    }
  
    async handleAnswer(answer) {
      try {
        await this.peerConnection.setRemoteDescription(answer);
      } catch (error) {
        console.error('Error handling answer:', error);
        throw error;
      }
    }
  
    async addIceCandidate(candidate) {
      try {
        await this.peerConnection.addIceCandidate(candidate);
      } catch (error) {
        console.error('Error adding ICE candidate:', error);
        throw error;
      }
    }
  
    handleDisconnection() {
      if (this.config.onDisconnect) {
        this.config.onDisconnect();
      }
    }
  
    setOnTrack(callback) {
      this.onTrackCallback = callback;
    }
  
    close() {
      if (this.dataChannel) {
        this.dataChannel.close();
      }
      if (this.peerConnection) {
        this.peerConnection.close();
      }
    }
  }
  
  module.exports = {
    AvatarHandler,
    ChatHandler,
    WebRTCService
  };