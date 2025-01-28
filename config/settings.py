# config/settings.py
class Config:
    CHUNK = 1024
    FORMAT = 'int16'  # Will be converted to pyaudio constant
    CHANNELS = 1
    RATE = 16000
    RECORD_SECONDS = 5
    BUCKET_NAME = 'your-bucket-name'
    LANGUAGE_CODE = 'en-US'
    VOICE_ID = 'Joanna'
    MODEL_ID = 'anthropic.claude-v2'