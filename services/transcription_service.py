# services/transcription_service.py
import boto3
import time
import json
import requests

class TranscriptionService:
    def __init__(self, bucket_name, language_code):
        self.transcribe = boto3.client('transcribe')
        self.s3 = boto3.client('s3')
        self.bucket_name = bucket_name
        self.language_code = language_code
        
    def transcribe_audio(self, audio_file):
        file_name = f"recording_{int(time.time())}.wav"
        self.s3.upload_file(audio_file, self.bucket_name, file_name)
        
        job_name = f"transcription_{int(time.time())}"
        job_uri = f"s3://{self.bucket_name}/{file_name}"
        
        self.transcribe.start_transcription_job(
            TranscriptionJobName=job_name,
            Media={'MediaFileUri': job_uri},
            MediaFormat='wav',
            LanguageCode=self.language_code
        )
        
        while True:
            status = self.transcribe.get_transcription_job(TranscriptionJobName=job_name)
            if status['TranscriptionJob']['TranscriptionJobStatus'] in ['COMPLETED', 'FAILED']:
                break
            time.sleep(1)
        
        if status['TranscriptionJob']['TranscriptionJobStatus'] == 'COMPLETED':
            response = requests.get(status['TranscriptionJob']['Transcript']['TranscriptFileUri'])
            return json.loads(response.text)['results']['transcripts'][0]['transcript']
        return None