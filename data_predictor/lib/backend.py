from flask import Flask, request, jsonify
from flask_cors import CORS  # Add this import
import google.generativeai as genai
from csvToString import convert_csv_to_string, get_smaller_sample
import logging
import trainer
from getParameters import get_parameters
from getTargetVariable import get_target_variable
from csvToString import convert_csv_to_string, get_all_parameters

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
# Add prompts here
model = genai.GenerativeModel(
    model_name="gemini-1.0-pro",
    generation_config=generation_config,
)

chat = model.start_chat(history=[])
conversation_history = []

trained_model = None
preprocessor = None
poly = None
parameters = None
target_variable = None


def train_and_save_model(input_text, input_file):
    global trained_model, preprocessor, poly, parameters, target_variable

    target_variable = get_target_variable(input_text, str(get_all_parameters(convert_csv_to_string(input_file))))
    parameters = get_parameters(input_file, target_variable).split(',')

    trained_model, preprocessor, poly = trainer.train_model(input_text, input_file)

    print("Model trained. Parameters:", parameters)
    print("Target variable:", target_variable)


@app.route('/train', methods=['POST'])
def train_model():
    data = request.get_json()
    input_test = data.get('input_test')
    input_file = data.get('input_file')

    if not input_test or not input_file:
        return jsonify({"error": "Missing required parameters"}), 400

    try:
        train_and_save_model(input_test, input_file)
        return jsonify({"message": "Model trained successfully", "parameters": parameters, "target_variable": target_variable})
    except Exception as e:
        logging.error(f"A training error occurred: {e}")
        return jsonify({"error": f"A training error occurred - Failed to train model: {e}"}), 400


@app.route('/get_parameters', methods=['GET'])
def get_model_parameters():
    if parameters is None:
        return jsonify({"error": "Model not trained yet"}), 400
    return jsonify({"parameters": parameters, "target_variable": target_variable})


@app.route('/chat', methods=['POST'])
def chat_route():
    data = request.get_json()
    user_input = data.get('message')
    if not user_input:
        return jsonify({"error": "No message provided"}), 400
    
    response = generate_response(user_input)
    return jsonify({"response": response})


@app.route('/predict', methods=['POST'])
def predict():
    if trained_model is None:
        return jsonify({"error": "Model not trained yet"}), 400

    data = request.get_json()
    user_input = {param: data.get(param) for param in parameters}

    try:
        prediction = trainer.predict_sales(user_input, trained_model, parameters, preprocessor, poly)
        return jsonify({target_variable: prediction})
    except Exception as e:
        logging.error(f"A prediction error occurred: {str(e)}")
        return jsonify({"error": f"A prediction error occurred: {str(e)}"}), 400


def generate_response(user_input):
    try:
        prompt = f"User: {user_input}\nAI:"
        response = chat.send_message(prompt)

        # Log the response for debugging
        logging.info(f"Full response: {response}")

        ai_response = response.parts[0].text if response.parts and len(response.parts) > 0 else "No response from AI"
        return ai_response
    except Exception as e:
        logging.error("An error occurred: {e}")
        return "An error occurred: {e}"


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
