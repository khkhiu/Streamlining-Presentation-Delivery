# chatbot.py
from config.settings import Config
from services.audio_service import AudioService
from services.transcription_service import TranscriptionService
from services.language_model_service import LanguageModelService
from services.speech_service import SpeechService

class VoiceChatbot:
    def __init__(self):
        self.audio_service = AudioService()
        self.transcription_service = TranscriptionService(
            Config.BUCKET_NAME,
            Config.LANGUAGE_CODE
        )
        self.language_model_service = LanguageModelService(Config.MODEL_ID)
        self.speech_service = SpeechService(Config.VOICE_ID)
    
    def chat(self):
        print("Chat bot is ready! Speak your question...")
        
        while True:
            # Record audio
            audio_file = self.audio_service.record_audio()
            
            # Transcribe audio to text
            question = self.transcription_service.transcribe_audio(audio_file)
            print(f"You said: {question}")
            
            if question.lower() in ['quit', 'exit', 'bye']:
                print("Goodbye!")
                break
            
            # Get answer
            answer = self.language_model_service.get_answer(question)
            print(f"Bot: {answer}")
            
            # Convert answer to speech
            self.speech_service.synthesize_and_play(answer)
