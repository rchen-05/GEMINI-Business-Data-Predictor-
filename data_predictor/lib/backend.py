from flask import Flask, request, jsonify
from flask_cors import CORS  # Add this import
import os
import google.generativeai as genai
from csvToString import convert_csv_to_string, get_smaller_sample
import logging

app = Flask(__name__)
CORS(app)  # Enable CORS

# Configure logging
logging.basicConfig(level=logging.INFO)

# Daniel API key dont remove just make another one 
api_key = "AIzaSyAw0O3QQZalaBbdhwaSpYREwBut_kP3wkw"
genai.configure(api_key=api_key)

generation_config = {
    "temperature": 0.15,
    "top_p": 1,
    "top_k": 0,
    "max_output_tokens": 2048,
    "response_mime_type": "text/plain",
}


def generate_response(user_input):
    try:
        model = genai.GenerativeModel(
            model_name="gemini-1.0-pro",
            generation_config=generation_config,
        )

        prompt = f"User: {user_input}\nAI:"
        response = model.generate_content([prompt])

        # Log the response for debugging
        logging.info(f"Full response: {response}")

        ai_response = response.parts[0].text if response.parts and len(response.parts) > 0 else "No response from AI"
        return ai_response
    except Exception as e:
        logging.error("An error occurred: {e}")
        return "An error occurred: {e}"

@app.route('/chat', methods=['POST'])
def chat_route():
    data = request.get_json()
    user_input = data.get('message')
    if not user_input:
        return jsonify({"error": "No message provided"}), 400
    
    response = generate_response(user_input)
    return jsonify({"response": response})


app.run(host='0.0.0.0', port=5001, debug=True)