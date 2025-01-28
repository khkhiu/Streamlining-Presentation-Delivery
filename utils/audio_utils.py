# utils/audio_utils.py
import pyaudio
import wave
from tempfile import NamedTemporaryFile

class AudioUtils:
    @staticmethod
    def get_pyaudio_format(format_str):
        return pyaudio.paInt16 if format_str == 'int16' else None

    @staticmethod
    def create_temp_wav_file(frames, channels, sample_width, rate):
        with NamedTemporaryFile(suffix=".wav", delete=False) as f:
            wf = wave.open(f.name, 'wb')
            wf.setnchannels(channels)
            wf.setsampwidth(sample_width)
            wf.setframerate(rate)
            wf.writeframes(b''.join(frames))
            wf.close()
            return f.name
