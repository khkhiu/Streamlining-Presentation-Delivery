# services/speech_service.py
import boto3
from contextlib import closing
import pyaudio
import wave
from tempfile import NamedTemporaryFile

class SpeechService:
    def __init__(self, voice_id):
        self.polly = boto3.client('polly')
        self.voice_id = voice_id
        
    def synthesize_and_play(self, text):
        response = self.polly.synthesize_speech(
            Text=text,
            OutputFormat='mp3',
            VoiceId=self.voice_id
        )
        
        if "AudioStream" in response:
            with closing(response["AudioStream"]) as stream:
                with NamedTemporaryFile(suffix=".mp3", delete=False) as f:
                    f.write(stream.read())
                    
            p = pyaudio.PyAudio()
            chunk = 1024
            
            with wave.open(f.name, 'rb') as wf:
                stream = p.open(
                    format=p.get_format_from_width(wf.getsampwidth()),
                    channels=wf.getnchannels(),
                    rate=wf.getframerate(),
                    output=True
                )
                
                data = wf.readframes(chunk)
                while data:
                    stream.write(data)
                    data = wf.readframes(chunk)
                
                stream.stop_stream()
                stream.close()
                p.terminate()
