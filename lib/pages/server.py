from flask import Flask, request, jsonify
from flask_cors import CORS
import openai
import os
import json

app = Flask(__name__)
CORS(app)

# Configure your OpenAI API key
openai.api_key = os.getenv('OPENAI_API_KEY')

# Your fine-tuned model ID
FINE_TUNED_MODEL = "ft:gpt-3.5-turbo-0613:your-english-teaching-model:id"

@app.route('/api/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        user_message = data.get('message', '')
        context = data.get('context', 'general')
        user_level = data.get('user_level', 'intermediate')
        
        # Enhanced system prompt for English teaching
        system_prompt = f"""
        You are an expert English teacher with specialized training in ESL education.
        
        STUDENT LEVEL: {user_level}
        TEACHING CONTEXT: {context}
        
        Your expertise includes:
        - Grammar explanations and exercises
        - Pronunciation guidance with phonetic transcriptions
        - Vocabulary building and idioms
        - Conversation practice
        - Writing correction and improvement
        - Cultural context and usage
        
        Teaching Methodology:
        1. Assess the student's specific need
        2. Provide clear, structured explanations
        3. Include practical examples
        4. Offer immediate practice opportunities
        5. Give constructive, encouraging feedback
        
        Always respond as a professional English teacher focusing on practical learning.
        """
        
        # Use your fine-tuned model
        response = openai.ChatCompletion.create(
            model=FINE_TUNED_MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message}
            ],
            temperature=0.7,
            max_tokens=1000
        )
        
        return jsonify({
            'response': response.choices[0].message.content,
            'context': context,
            'success': True
        })
        
    except Exception as e:
        # Fallback response if model fails
        return jsonify({
            'response': f"I'm here to help you learn English! Currently, I can assist with grammar, vocabulary, pronunciation, and conversation practice. What specific area would you like to work on?",
            'success': False,
            'error': str(e)
        })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)