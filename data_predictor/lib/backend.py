from flask import Flask, request, jsonify
from flask_cors import CORS # Add this import
import google.generativeai as genai
from csvToString import convert_csv_to_string
import logging
import trainer
from getTargetVariable import get_target_variable
from getParameters import get_all_relevant_parameters, get_user_parameters, get_all_parameters
from getValues import get_values
from chatFilter import filter_chat
import firebase_admin
from firebase_admin import credentials, firestore
import pickle
import requests
import io

target_variable, parameters, best_split, best_degree, mae, mse, r2, cv_scores, model, preprocessor, poly = None, None, \
                                                                    None, None, None, None, None, None, None, None, None

# Initialize Firebase
# Path to service account key JSON file
cred = credentials.Certificate("ServiceAccountKey.json")
# Initialize the firebase app
firebase_admin.initialize_app(cred)
# Get a Firestore client
db = firestore.client()

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
file_uploaded = False
uploaded_file_path = None


@app.route('/upload_and_train', methods=['POST'])
def upload_and_train():
    global file_uploaded, uploaded_file_path

    data = request.get_json()
    file_url = data.get('file_url')
    file_name = data.get('file_name')

    if not file_url or not file_name:
        return jsonify({"error": "Missing required parameters"}), 400
    try:
        # Download the file from firebase storage
        response = requests.get(file_url)
        if response.status_code == 200:
            # Save the file to the local file system
            uploaded_file_path = f"temp_{file_name}"
            with open(uploaded_file_path, 'wb') as f:
                f.write(response.content)

            file_uploaded = True

            train_and_save_model("Train a model using the uploaded file", uploaded_file_path)

            return jsonify({"message": "File uploaded and model trained successfully"})
        else:
            return jsonify({"error": "Failed to download file"}), 400
    except Exception as e:
        logging.error(f"An error occurred during file upload and training: {e}")
        return jsonify({"error": f"An error occurred: {str(e)}"}), 400


def train_and_save_model(input_text, input_file):
    global trained_model, preprocessor, poly, parameters, target_variable, all_parameters, relevant_parameters

    target_variable = get_target_variable(input_text, all_parameters)
    relevant_parameters = get_all_relevant_parameters(input_file, target_variable)
    parameters = get_user_parameters(input_text, relevant_parameters).split(',')

    trained_model, preprocessor, poly = trainer.train_model(input_text, input_file)

    model_data = {
        "model": pickle.dumps(trained_model),
        "preprocessor": pickle.dumps(preprocessor),
        "poly": pickle.dumps(poly),
        "parameters": parameters,
        "target_variable": target_variable
    }

    # Save the trained model to Firebase
    db.collection('models').document('trained_model').set(model_data)

    print("Model trained and stored in Firebase. Parameters:", parameters)
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
    data = request.get_json()
    user_input = data.get('user_input')

    if not user_input:
        return jsonify({"error": "No user input provided"}), 400
    # if trained_model is None:
    #     return jsonify({"error": "Model not trained yet"}), 400
    try:
        doc = db.collection('models').document('trained_model').get()
        if not doc.exists:
            return jsonify({"error": "No trained model has been found in firebase"}), 400

        model_data = doc.to_dict()
        trained_model = pickle.loads(model_data['model'])
        preprocessor = pickle.loads(model_data['preprocessor'])
        poly = pickle.loads(model_data['poly'])
        parameters = model_data['parameters']
        target_variable = model_data['target_variable']

        values = get_values(user_input, ','.join(parameters))
        user_data = dict(zip(parameters, values))
        prediction = trainer.predict(user_data, trained_model, parameters, preprocessor, poly)
        return jsonify({target_variable: prediction})
    except Exception as e:
        logging.error(f"A prediction error occurred: {str(e)}")
        return jsonify({"error": f"A prediction error occurred: {str(e)}"}), 400

    # try:
    #     values = get_values(user_input, ','.join(parameters))
    #     user_data = dict(zip(parameters, values))
    #     prediction = trainer.predict(user_data, trained_model, parameters, preprocessor, poly)
    #     return jsonify({target_variable: prediction})
    # except Exception as e:
    #     logging.error(f"A prediction error occurred: {str(e)}")
    #     return jsonify({"error": f"A prediction error occurred: {str(e)}"}), 400


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


def generate_response(user_input):
    global trained_model, preprocessor, poly, parameters, target_variable, file_uploaded, uploaded_file_path

    try:
        prompt = f"User: {user_input}\nAI:"
        option = filter_chat(user_input)

        # check if file has been uploaded
        if file_uploaded == False:
            return "Please upload a file first"
        
        if option == '0':
            # change coffee.csv      ------- ERROR HERE - NEED TO PASS IN CORRECT FILE UPLOADED BY USER -------
            target_variable, parameters, best_split, best_degree, mae, mse, r2, cv_scores,model, preprocessor, poly = trainer.train_model(user_input, uploaded_file_path)
            return trainer.summarize_training_process()
        elif option == '1':
            user_values = get_values(user_input, parameters)
            prediction = trainer.predict(user_values, trained_model, parameters, preprocessor, poly)
            return f"Prediction: {prediction}"
            
        elif option == '2':
            response = chat.send_message(prompt)
            # Log the response for debugging
            logging.info(f"Full response: {response}")

            ai_response = response.parts[0].text if response.parts and len(response.parts) > 0 else "No response from AI"
            return ai_response
        
    except Exception as e:
        logging.error("An error occurred: {}".format(e))
        return "An error occurred: {}".format(e)


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
