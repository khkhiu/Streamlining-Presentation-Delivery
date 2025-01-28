# services/audio_service.py
import pyaudio
from ..config.settings import Config
from ..utils.audio_utils import AudioUtils

class AudioService:
    def __init__(self):
        self.config = Config
        self.format = AudioUtils.get_pyaudio_format(self.config.FORMAT)
        
    def record_audio(self):
        p = pyaudio.PyAudio()
        stream = p.open(
            format=self.format,
            channels=self.config.CHANNELS,
            rate=self.config.RATE,
            input=True,
            frames_per_buffer=self.config.CHUNK
        )
        
        print("* Recording...")
        frames = []
        
        for _ in range(0, int(self.config.RATE / self.config.CHUNK * self.config.RECORD_SECONDS)):
            data = stream.read(self.config.CHUNK)
            frames.append(data)
        
        print("* Done recording")
        
        stream.stop_stream()
        stream.close()
        p.terminate()
        
        return AudioUtils.create_temp_wav_file(
            frames,
            self.config.CHANNELS,
            p.get_sample_size(self.format),
            self.config.RATE
        )