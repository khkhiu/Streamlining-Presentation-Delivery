// App.jsx
import { useState, useEffect, useRef } from 'react'
import * as SpeechSDK from 'microsoft-cognitiveservices-speech-sdk'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Label } from '@/components/ui/label'
import { Checkbox } from '@/components/ui/checkbox'



const REGIONS = [
  { value: 'westus2', label: 'West US 2' },
  { value: 'westeurope', label: 'West Europe' },
  { value: 'southeastasia', label: 'Southeast Asia' },
  { value: 'southcentralus', label: 'South Central US' },
  { value: 'northeurope', label: 'North Europe' },
  { value: 'swedencentral', label: 'Sweden Central' },
  { value: 'eastus2', label: 'East US 2' }
]

export default function App() {
  // State for configuration
  const [region, setRegion] = useState('westus2')
  const [apiKey, setApiKey] = useState('')
  const [enablePrivateEndpoint, setEnablePrivateEndpoint] = useState(false)
  const [privateEndpoint, setPrivateEndpoint] = useState('')
  const [ttsVoice, setTtsVoice] = useState('en-US-AvaMultilingualNeural')
  const [customVoiceEndpointId, setCustomVoiceEndpointId] = useState('')
  const [personalVoiceSpeakerProfileId, setPersonalVoiceSpeakerProfileId] = useState('')
  const [avatarCharacter, setAvatarCharacter] = useState('lisa')
  const [avatarStyle, setAvatarStyle] = useState('casual-sitting')
  const [backgroundColor, setBackgroundColor] = useState('#FFFFFFFF')
  const [backgroundImageUrl, setBackgroundImageUrl] = useState('')
  const [customizedAvatar, setCustomizedAvatar] = useState(false)
  const [transparentBackground, setTransparentBackground] = useState(false)
  const [videoCrop, setVideoCrop] = useState(false)
  
  // State for avatar control
  const [spokenText, setSpokenText] = useState('Hello world!')
  const [isSessionStarted, setIsSessionStarted] = useState(false)
  const [isSpeaking, setIsSpeaking] = useState(false)
  const [logs, setLogs] = useState([])

  // Refs
  const avatarSynthesizerRef = useRef(null)
  const peerConnectionRef = useRef(null)
  const remoteVideoRef = useRef(null)
  const canvasRef = useRef(null)
  const tmpCanvasRef = useRef(null)

  const log = (msg) => {
    setLogs(prev => [...prev, msg])
  }

  const htmlEncode = (text) => {
    const entityMap = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
      '/': '&#x2F;'
    }
    return String(text).replace(/[&<>"'\/]/g, (match) => entityMap[match])
  }

  const setupWebRTC = async (iceServerUrl, iceServerUsername, iceServerCredential) => {
    // Create WebRTC peer connection
    const peerConnection = new RTCPeerConnection({
      iceServers: [{
        urls: [iceServerUrl],
        username: iceServerUsername,
        credential: iceServerCredential
      }]
    })

    peerConnectionRef.current = peerConnection

    // Handle incoming tracks
    peerConnection.ontrack = (event) => {
      if (event.track.kind === 'video') {
        const videoElement = document.createElement('video')
        videoElement.srcObject = event.streams[0]
        videoElement.autoplay = true
        videoElement.playsInline = true
        
        if (remoteVideoRef.current) {
          remoteVideoRef.current.innerHTML = ''
          remoteVideoRef.current.appendChild(videoElement)
        }

        if (transparentBackground) {
          // Handle transparent background logic
          videoElement.addEventListener('play', () => {
            makeBackgroundTransparent()
          })
        }
      } else if (event.track.kind === 'audio') {
        const audioElement = document.createElement('audio')
        audioElement.srcObject = event.streams[0]
        audioElement.autoplay = true
        audioElement.muted = true // Will unmute when speaking
        
        if (remoteVideoRef.current) {
          remoteVideoRef.current.appendChild(audioElement)
        }
      }
    }

    // Handle connection state changes
    peerConnection.oniceconnectionstatechange = () => {
      log(`WebRTC status: ${peerConnection.iceConnectionState}`)
      if (peerConnection.iceConnectionState === 'connected') {
        setIsSessionStarted(true)
      } else if (['disconnected', 'failed'].includes(peerConnection.iceConnectionState)) {
        setIsSessionStarted(false)
        setIsSpeaking(false)
      }
    }

    // Add transceivers
    peerConnection.addTransceiver('video', { direction: 'sendrecv' })
    peerConnection.addTransceiver('audio', { direction: 'sendrecv' })

    return peerConnection
  }

  const makeBackgroundTransparent = () => {
    if (!canvasRef.current || !tmpCanvasRef.current) return

    const video = document.querySelector('video')
    if (!video) return

    const tmpCtx = tmpCanvasRef.current.getContext('2d', { willReadFrequently: true })
    const ctx = canvasRef.current.getContext('2d')

    const animate = () => {
      tmpCtx.drawImage(video, 0, 0, video.videoWidth, video.videoHeight)
      
      const frame = tmpCtx.getImageData(0, 0, video.videoWidth, video.videoHeight)
      for (let i = 0; i < frame.data.length / 4; i++) {
        const r = frame.data[i * 4 + 0]
        const g = frame.data[i * 4 + 1]
        const b = frame.data[i * 4 + 2]
        
        if (g - 150 > r + b) {
          frame.data[i * 4 + 3] = 0
        } else if (g + g > r + b) {
          const adjustment = (g - (r + b) / 2) / 3
          frame.data[i * 4 + 0] = r + adjustment
          frame.data[i * 4 + 1] = g - adjustment * 2
          frame.data[i * 4 + 2] = b + adjustment
          frame.data[i * 4 + 3] = Math.max(0, 255 - adjustment * 4)
        }
      }
      
      ctx.putImageData(frame, 0, 0)
      requestAnimationFrame(animate)
    }

    requestAnimationFrame(animate)
  }

  const startSession = async () => {
    if (!apiKey) {
      alert('Please fill in the API key of your speech resource.')
      return
    }

    if (enablePrivateEndpoint && !privateEndpoint) {
      alert('Please fill in the Azure Speech endpoint.')
      return
    }

    try {
      // Get relay token
      const response = await fetch(
        enablePrivateEndpoint
          ? `https://${privateEndpoint}/tts/cognitiveservices/avatar/relay/token/v1`
          : `https://${region}.tts.speech.microsoft.com/cognitiveservices/avatar/relay/token/v1`,
        {
          headers: {
            'Ocp-Apim-Subscription-Key': apiKey
          }
        }
      )

      const tokenData = await response.json()
      
      // Configure speech synthesis
      let speechConfig
      if (enablePrivateEndpoint) {
        speechConfig = SpeechSDK.SpeechConfig.fromEndpoint(
          new URL(`wss://${privateEndpoint}/tts/cognitiveservices/websocket/v1?enableTalkingAvatar=true`),
          apiKey
        )
      } else {
        speechConfig = SpeechSDK.SpeechConfig.fromSubscription(apiKey, region)
      }
      
      speechConfig.endpointId = customVoiceEndpointId

      // Configure avatar
      const videoFormat = new SpeechSDK.AvatarVideoFormat()
      if (videoCrop) {
        videoFormat.setCropRange(
          new SpeechSDK.Coordinate(600, 0),
          new SpeechSDK.Coordinate(1320, 1080)
        )
      }

      const avatarConfig = new SpeechSDK.AvatarConfig(
        avatarCharacter,
        avatarStyle,
        videoFormat
      )
      
      avatarConfig.customized = customizedAvatar
      avatarConfig.backgroundColor = backgroundColor
      avatarConfig.backgroundImage = backgroundImageUrl

      // Setup WebRTC and start avatar
      const peerConnection = await setupWebRTC(
        tokenData.Urls[0],
        tokenData.Username,
        tokenData.Password
      )

      const synthesizer = new SpeechSDK.AvatarSynthesizer(speechConfig, avatarConfig)
      avatarSynthesizerRef.current = synthesizer

      synthesizer.avatarEventReceived = (s, e) => {
        const offsetMessage = e.offset ? `, offset from session start: ${e.offset / 10000}ms.` : ''
        log(`Event received: ${e.description}${offsetMessage}`)
      }

      const result = await synthesizer.startAvatarAsync(peerConnection)
      if (result.reason === SpeechSDK.ResultReason.SynthesizingAudioCompleted) {
        log(`Avatar started. Result ID: ${result.resultId}`)
      } else {
        throw new Error(`Unable to start avatar. Result ID: ${result.resultId}`)
      }
    } catch (error) {
      log(`Error starting session: ${error.message}`)
    }
  }

  const speak = async () => {
    if (!avatarSynthesizerRef.current) return

    setIsSpeaking(true)
    const audioElement = document.querySelector('audio')
    if (audioElement) audioElement.muted = false

    const ssml = `
      <speak version='1.0' 
             xmlns='http://www.w3.org/2001/10/synthesis' 
             xmlns:mstts='http://www.w3.org/2001/mstts' 
             xml:lang='en-US'>
        <voice name='${ttsVoice}'>
          <mstts:ttsembedding speakerProfileId='${personalVoiceSpeakerProfileId}'>
            <mstts:leadingsilence-exact value='0'/>
            ${htmlEncode(spokenText)}
          </mstts:ttsembedding>
        </voice>
      </speak>
    `

    try {
      const result = await avatarSynthesizerRef.current.speakSsmlAsync(ssml)
      if (result.reason === SpeechSDK.ResultReason.SynthesizingAudioCompleted) {
        log(`Speech synthesized for text [ ${spokenText} ]. Result ID: ${result.resultId}`)
      } else {
        throw new Error(`Unable to speak text. Result ID: ${result.resultId}`)
      }
    } catch (error) {
      log(`Error speaking: ${error.message}`)
    } finally {
      setIsSpeaking(false)
    }
  }

  const stopSpeaking = async () => {
    if (!avatarSynthesizerRef.current) return
    
    try {
      await avatarSynthesizerRef.current.stopSpeakingAsync()
      log('Stop speaking request sent.')
      setIsSpeaking(false)
    } catch (error) {
      log(`Error stopping speech: ${error.message}`)
    }
  }

  const stopSession = () => {
    if (avatarSynthesizerRef.current) {
      avatarSynthesizerRef.current.close()
      avatarSynthesizerRef.current = null
    }
    setIsSessionStarted(false)
    setIsSpeaking(false)
  }

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-3xl font-bold mb-6">Talking Avatar Service Demo</h1>
      
      {!isSessionStarted && (
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>Azure Speech Resource</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center gap-4">
              <Label htmlFor="region">Region:</Label>
              <Select value={region} onValueChange={setRegion}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {REGIONS.map(region => (
                    <SelectItem key={region.value} value={region.value}>
                      {region.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="flex items-center gap-4">
              <Label htmlFor="apiKey">API Key:</Label>
              <Input
                id="apiKey"
                type="password"
                value={apiKey}
                onChange={(e) => setApiKey(e.target.value)}
              />
            </div>

            <div className="flex items-center gap-2">
              <Checkbox
                id="enablePrivateEndpoint"
                checked={enablePrivateEndpoint}
                onCheckedChange={setEnablePrivateEndpoint}
              />
              <Label htmlFor="enablePrivateEndpoint">Enable Private Endpoint</Label>
            </div>

            {enablePrivateEndpoint && (
              <div className="flex items-center gap-4">
                <Label htmlFor="privateEndpoint">Private Endpoint:</Label>
                <Input
                  id="privateEndpoint"
                  placeholder="https://{your custom name}.cognitiveservices.azure.com/"
                  value={privateEndpoint}
                  onChange={(e) => setPrivateEndpoint(e.target.value)}
                />
              </div>
            )}
          </CardContent>
        </Card>
      )}

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Avatar Control Panel</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="spokenText">Spoken Text:</Label>
            <Textarea
              id="spokenText"
              value={spokenText}
              onChange={(e) => setSpokenText(e.target.value)}
              className="h-20"
            />
          </div>

          <div className="flex gap-2">
            {!isSessionStarted ? (
              <Button onClick={startSession}>Start Session</Button>
            ) : (
              <>
                <Button 
                  onClick={speak} 
                  disabled={isSpeaking}>
                  Speak
                </Button>
                <Button 
                  onClick={stopSpeaking} 
                  disabled={!isSpeaking}>
                  Stop Speaking
                </Button>
                <Button 
                  onClick={stopSession}>
                  Stop Session
                </Button>
              </>
            )}
          </div>
        </CardContent>
      </Card>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Avatar Video</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="relative w-full max-w-3xl">
            <div 
              ref={remoteVideoRef} 
              className="relative z-10"
            />
            <canvas 
              ref={canvasRef}
              width="1920"
              height="1080"
              className={`absolute top-0 left-0 ${transparentBackground ? 'block' : 'hidden'}`}
            />
            <canvas 
              ref={tmpCanvasRef}
              width="1920"
              height="1080"
              className="hidden"
            />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Logs</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="bg-gray-100 p-4 rounded-lg max-h-60 overflow-y-auto">
            {logs.map((log, index) => (
              <div key={index} className="mb-1">{log}</div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
