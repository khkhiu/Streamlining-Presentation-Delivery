// App.tsx
import { useState, useRef } from 'react'
import * as SpeechSDK from 'microsoft-cognitiveservices-speech-sdk'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { getEnvironmentConfig } from '@/config/environment'

// Configuration object
const CONFIG = getEnvironmentConfig()

interface RelayTokenResponse {
  Urls: string[]
  Username: string
  Password: string
}

export default function App() {
  // State for configuration - initialized with default values
  /* keeping this for reference
  const [region, setRegion] = useState<string>(CONFIG.azure.region)
  const [apiKey, setApiKey] = useState<string>(CONFIG.azure.apiKey)
  const [ttsVoice, setTtsVoice] = useState<string>('en-US-AvaMultilingualNeural')
  const [customVoiceEndpointId, setCustomVoiceEndpointId] = useState<string>('')
  const [personalVoiceSpeakerProfileId, setPersonalVoiceSpeakerProfileId] = useState<string>('')
  const [avatarCharacter, setAvatarCharacter] = useState<string>('lisa')
  const [avatarStyle, setAvatarStyle] = useState<string>('casual-sitting')
  const [backgroundColor, setBackgroundColor] = useState<string>('#FFFFFFFF')
  const [customizedAvatar, setCustomizedAvatar] = useState<boolean>(false)
  const [transparentBackground, setTransparentBackground] = useState<boolean>(false)
  const [videoCrop, setVideoCrop] = useState<boolean>(false)
  */
  const region: string = CONFIG.azure.region;
  const apiKey: string = CONFIG.azure.region;
  const ttsVoice: string = 'en-US-AvaMultilingualNeural';
  const customVoiceEndpointId: string = '';
  const personalVoiceSpeakerProfileId: string = '';
  const avatarCharacter: string = 'lisa';
  const avatarStyle: string = 'casual-sitting';
  const backgroundColor: string = '#FFFFFFFF';
  const customizedAvatar: boolean = false;
  const transparentBackground: boolean = false;
  const videoCrop: boolean = false;
  
  // State for avatar control
  const [spokenText, setSpokenText] = useState<string>('Hello world!')
  const [isSessionStarted, setIsSessionStarted] = useState<boolean>(false)
  const [isSpeaking, setIsSpeaking] = useState<boolean>(false)
  const [logs, setLogs] = useState<string[]>([])

  // Refs
  const avatarSynthesizerRef = useRef<SpeechSDK.AvatarSynthesizer | null>(null)
  const peerConnectionRef = useRef<RTCPeerConnection | null>(null)
  const remoteVideoRef = useRef<HTMLDivElement | null>(null)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const tmpCanvasRef = useRef<HTMLCanvasElement | null>(null)

  const log = (msg: string): void => {
    setLogs(prev => [...prev, msg])
  }

  const htmlEncode = (text: string): string => {
    const entityMap: { [key: string]: string } = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
      '/': '&#x2F;'
    }
    return String(text).replace(/[&<>"'\/]/g, (match) => entityMap[match])
  }

  const setupWebRTC = async (
    iceServerUrl: string,
    iceServerUsername: string,
    iceServerCredential: string
  ): Promise<RTCPeerConnection> => {
    const peerConnection = new RTCPeerConnection({
      iceServers: [{
        urls: [iceServerUrl],
        username: iceServerUsername,
        credential: iceServerCredential
      }]
    })

    peerConnectionRef.current = peerConnection

    peerConnection.ontrack = (event: RTCTrackEvent) => {
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
          videoElement.addEventListener('play', () => {
            makeBackgroundTransparent()
          })
        }
      } else if (event.track.kind === 'audio') {
        const audioElement = document.createElement('audio')
        audioElement.srcObject = event.streams[0]
        audioElement.autoplay = true
        audioElement.muted = true
        
        if (remoteVideoRef.current) {
          remoteVideoRef.current.appendChild(audioElement)
        }
      }
    }

    peerConnection.oniceconnectionstatechange = () => {
      log(`WebRTC status: ${peerConnection.iceConnectionState}`)
      if (peerConnection.iceConnectionState === 'connected') {
        setIsSessionStarted(true)
      } else if (['disconnected', 'failed'].includes(peerConnection.iceConnectionState)) {
        setIsSessionStarted(false)
        setIsSpeaking(false)
      }
    }

    peerConnection.addTransceiver('video', { direction: 'sendrecv' })
    peerConnection.addTransceiver('audio', { direction: 'sendrecv' })

    return peerConnection
  }

  const makeBackgroundTransparent = (): void => {
    if (!canvasRef.current || !tmpCanvasRef.current) return

    const video = document.querySelector('video')
    if (!video) return

    const tmpCtx = tmpCanvasRef.current.getContext('2d', { willReadFrequently: true })
    const ctx = canvasRef.current.getContext('2d')
    
    if (!tmpCtx || !ctx) return

    const animate = (): void => {
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

  const startSession = async (): Promise<void> => {
    if (!apiKey) {
      alert('Please fill in the API key of your speech resource.')
      return
    }

    try {
      const response = await fetch(
        `https://${region}.tts.speech.microsoft.com/cognitiveservices/avatar/relay/token/v1`,
        {
          headers: {
            'Ocp-Apim-Subscription-Key': apiKey
          }
        }
      )

      const tokenData: RelayTokenResponse = await response.json()
      
      const speechConfig = SpeechSDK.SpeechConfig.fromSubscription(apiKey, region)
      speechConfig.endpointId = customVoiceEndpointId

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
      //avatarConfig.backgroundImage = backgroundImageUrl

      const peerConnection = await setupWebRTC(
        tokenData.Urls[0],
        tokenData.Username,
        tokenData.Password
      )

      const synthesizer = new SpeechSDK.AvatarSynthesizer(speechConfig, avatarConfig)
      avatarSynthesizerRef.current = synthesizer

      synthesizer.avatarEventReceived = (s: unknown, e: SpeechSDK.AvatarEventArgs) => {
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
      log(`Error starting session: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  const speak = async (): Promise<void> => {
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
      log(`Error speaking: ${error instanceof Error ? error.message : String(error)}`)
    } finally {
      setIsSpeaking(false)
    }
  }

  const stopSpeaking = async (): Promise<void> => {
    if (!avatarSynthesizerRef.current) return
    
    try {
      await avatarSynthesizerRef.current.stopSpeakingAsync()
      log('Stop speaking request sent.')
      setIsSpeaking(false)
    } catch (error) {
      log(`Error stopping speech: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  const stopSession = (): void => {
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