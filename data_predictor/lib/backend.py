from flask import Flask, request, jsonify
from flask_cors import CORS  # Add this import
import google.generativeai as genai
from csvToString import convert_csv_to_string
import logging
import trainer
from getTargetVariable import get_target_variable
from getParameters import get_all_relevant_parameters, get_user_parameters, get_all_parameters
from getValues import get_values
from chatFilter import filter_chat

target_variable, parameters, best_split, best_degree, mae, mse, r2, cv_scores, model, preprocessor, poly = None, None, None, None, None, None, None, None


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

# Global variables
trained_model = None
preprocessor = None
poly = None
parameters = None
target_variable = None
all_parameters = None
relevant_parameters = None


def download_file_from_drive(url):
    # Extract file ID from the Google Drive link
    file_id = re.findall(r'\/file\/d\/(.+?)\/view', url)
    if not file_id:
        raise ValueError("Invalid Google Drive URL")

    file_id = file_id[0]
    output = f'downloaded_file_{file_id}.csv'
    gdown.download(f'https://drive.google.com/uc?id={file_id}', output, quiet=False)
    return output


def extract_drive_link(user_input):
    # Simple regex to find a Google Drive link in the user input
    match = re.search(r'https://drive\.google\.com/file/d/[^\s]+', user_input)
    return match.group(0) if match else None


def train_and_save_model(input_text, input_file):
    global trained_model, preprocessor, poly, parameters, target_variable, all_parameters, relevant_parameters

    target_variable = get_target_variable(input_text, all_parameters)
    relevant_parameters = get_all_relevant_parameters(input_file, target_variable)
    parameters = get_user_parameters(input_text, relevant_parameters).split(',')

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
        return jsonify({
            "message": "Model trained successfully",
            "parameters": parameters,
            "target_variable": target_variable,
            "all_parameters": all_parameters,
            "relevant_parameters": relevant_parameters
        })
    except Exception as e:
        logging.error(f"A training error occurred: {e}")
        return jsonify({"error": f"A training error occurred - Failed to train model: {e}"}), 400


@app.route('/get_parameters', methods=['GET'])
def get_model_parameters():
    if parameters is None:
        return jsonify({"error": "Model not trained yet"}), 400
    return jsonify({
        "parameters": parameters,
        "target_variable": target_variable,
        "all_parameters": all_parameters,
        "relevant_parameters": relevant_parameters
    })


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
    user_input = data.get('user_input')

    if not user_input:
        return jsonify({"error": "No user input provided"}), 400

    try:
        values = get_values(user_input, ','.join(parameters))
        user_data = dict(zip(parameters, values))
        prediction = trainer.predict(user_data, trained_model, parameters, preprocessor, poly)
        return jsonify({target_variable: prediction})
    except Exception as e:
        logging.error(f"A prediction error occurred: {str(e)}")
        return jsonify({"error": f"A prediction error occurred: {str(e)}"}), 400


@app.route('/get_all_parameters', methods=['POST'])
def get_all_params():
    data = request.get_json()
    input_file = data.get('input_file')
    if not input_file:
        return jsonify({"error": "No input file provided"}), 400

    all_params = get_all_parameters(input_file)
    return jsonify({"all_parameters": all_params})


@app.route('/get_relevant_parameters', methods=['POST'])
def get_relevant_params():
    data = request.get_json()
    input_file = data.get('input_file')
    target_var = data.get('target_variable')
    if not input_file or not target_var:
        return jsonify({"error": "Missing input file or target variable"}), 400

    relevant_params = get_all_relevant_parameters(input_file, target_var)
    return jsonify({"relevant_parameters": relevant_params})


@app.route('/get_user_parameters', methods=['POST'])
def get_user_params():
    data = request.get_json()
    user_input = data.get('user_input')
    relevant_params = data.get('relevant_parameters')
    if not user_input or not relevant_params:
        return jsonify({"error": "Missing user input or relevant parameters"}), 400

    user_params = get_user_parameters(user_input, relevant_params)
    return jsonify({"user_parameters": user_params})


def handle_train_request(user_input):
    input_text = user_input
    input_file = extract_drive_link(user_input)

    if not input_file:
        return "No Google Drive link found in the input. Please provide a link to the dataset."

    try:
        input_file = download_file_from_drive(input_file)
        train_and_save_model(input_text, input_file)
        return f"Model trained successfully using file {input_file}. Parameters: {parameters}, " \
               f"Target variable: {target_variable}"
    except Exception as e:
        return f"Failed to train model: {str(e)}"


def handle_predict_request(user_input):
    if trained_model is None:
        return "Model not trained yet. Please train the model first."

    try:
        values = get_values(user_input, ','.join(parameters))
        user_data = dict(zip(parameters, values))
        prediction = trainer.predict_sales(user_data, trained_model, parameters, preprocessor, poly)
        return f"Prediction for {target_variable}: {prediction}"
    except Exception as e:
        return f"Failed to make prediction: {str(e)}"


def handle_get_parameters_request(user_input):
    if parameters is None:
        return "Model not trained yet. Please train the model first."
    return f"Parameters: {parameters}, Target variable: {target_variable}, All parameters: {all_parameters}, " \
           f"Relevant parameters: {relevant_parameters}"


def handle_get_all_parameters_request(user_input):
    input_file = extract_drive_link(user_input)

    if not input_file:
        return "No Google Drive link found in the input. Please provide a link to the dataset."

    try:
        input_file = download_file_from_drive(input_file)
        all_params = get_all_parameters(input_file)
        return f"All parameters for {input_file}: {all_params}"
    except Exception as e:
        return f"Failed to get all parameters: {str(e)}"


def handle_get_relevant_parameters_request(user_input):
    input_file = extract_drive_link(user_input)

    if not input_file:
        return "No Google Drive link found in the input. Please provide a link to the dataset."

    # Extract target variable from user input (this is a simplification)
    target_var = user_input.split("target variable")[-1].strip()

    try:
        input_file = download_file_from_drive(input_file)
        relevant_params = get_all_relevant_parameters(input_file, target_var)
        return f"Relevant parameters for {input_file} with target {target_var}: {relevant_params}"
    except Exception as e:
        return f"Failed to get relevant parameters: {str(e)}"


def handle_get_user_parameters_request(user_input):
    input_file = extract_drive_link(user_input)

    if not input_file:
        return "No Google Drive link found in the input. Please provide a link to the dataset."

    relevant_params = get_all_relevant_parameters(input_file, target_variable)

    try:
        user_params = get_user_parameters(user_input, relevant_params)
        return f"User parameters: {user_params}"
    except Exception as e:
        return f"Failed to get user parameters: {str(e)}"


def handle_help_request(user_input):
    help_prompt = f"""
    The user has asked for help with using the ML model training and prediction system. Please provide a concise guide on how to:
    1. Train a model (including how to provide a Google Drive link for the dataset)
    2. Make predictions using the trained model
    3. Get information about model parameters
    4. Get all parameters from a dataset
    5. Get relevant parameters for a specific target
    6. Get user-accessible parameters

    User input: {user_input}

    Help Guide:
    """

    help_response = model.generate_content(help_prompt)
    return help_response.text.strip()


def generate_response(user_input):
    try:
        prompt = f"User: {user_input}\nAI:"
        option = filter_chat(user_input)
        if option == '0':
            target_variable, parameters, best_split, best_degree, mae, mse, r2, cv_scores,model, preprocessor, poly = trainer.train_model(user_input, 'coffee.csv')
            return trainer.summarize_training_process()
        elif option == '1':
            user_values = get_values(user_input, parameters)
            trainer.predict(user_values, trained_model, parameters, preprocessor, poly)
            
        elif option == '2':
            response = chat.send_message(prompt)
            # Log the response for debugging
            logging.info(f"Full response: {response}")

            ai_response = response.parts[0].text if response.parts and len(response.parts) > 0 else "No response from AI"
            return ai_response
        
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        return f"An error occurred: {str(e)}"


def initialize_app():
    # If you need to do any initialization, put it here
    # For example:
    # all_parameters = get_all_parameters('your_input_file.csv')
    # relevant_parameters = get_all_relevant_parameters('your_input_file.csv', 'your_target_variable')
    print("Initializing application...")
    # Add any other initialization code here


if __name__ == '__main__':
    initialize_app()
    app.run(host='0.0.0.0', port=5001, debug=True)


# def generate_response(user_input):
#     try:
#         prompt = f"User: {user_input}\nAI:"
#         response = chat.send_message(prompt)
#
#         # Log the response for debugging
#         logging.info(f"Full response: {response}")
#
#         ai_response = response.parts[0].text if response.parts and len(response.parts) > 0 else "No response from AI"
#         return ai_response
#     except Exception as e:
#         logging.error("An error occurred: {e}")
#         return "An error occurred: {e}"
#
# @app.route('/predict', methods=['POST'])
# def predict():
#     if trained_model is None:
#         return jsonify({"error": "Model not trained yet"}), 400
#
#     data = request.get_json()
#     user_input = {param: data.get(param) for param in parameters}
#
#     try:
#         prediction = trainer.predict_sales(user_input, trained_model, parameters, preprocessor, poly)
#         return jsonify({target_variable: prediction})
#     except Exception as e:
#         logging.error(f"A prediction error occurred: {str(e)}")
#         return jsonify({"error": f"A prediction error occurred: {str(e)}"}), 400
