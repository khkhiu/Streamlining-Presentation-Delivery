# services/language_model_service.py
import boto3
import json

class LanguageModelService:
    def __init__(self, model_id):
        self.bedrock = boto3.client('bedrock-runtime')
        self.model_id = model_id
        
    def get_answer(self, question):
        prompt = f"Human: {question}\n\nAssistant: Let me help you with that."
        
        response = self.bedrock.invoke_model(
            modelId=self.model_id,
            body=json.dumps({
                "prompt": prompt,
                "max_tokens_to_sample": 500,
                "temperature": 0.7,
            })
        )
        
        response_body = json.loads(response['body'].read())
        return response_body['completion']
