import firebase_admin.auth
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
from firebase_admin import credentials, firestore, auth
import pickle
import requests
import os
import io
from trainer import predict
import firebase_admin.auth
target_variable, parameters, best_split, best_degree, mae, mse, r2, cv_scores, model, preprocessor, poly = None, None, \
                                                                    None, None, None, None, None, None, None, None, None

# Initialize Firebase
# Path to service account key JSON file
cred = credentials.Certificate('ServiceAccountKey.json')

# Initialize the firebase app
firebase_admin.initialize_app(cred)
# Get a Firestore client
db = firestore.client()

app = Flask(__name__)
CORS(app)  # Enable CORS

# Configure logging
logging.basicConfig(level=logging.INFO)

# Daniel API key dont remove just make another one 
from dotenv import load_dotenv
load_dotenv()
api_key = os.getenv('API_KEY')

genai.configure(api_key=api_key)

conversationID = None
userID = None
messages = []

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




def format_messages_for_gemini(messages):
    formatted_messages = []
    for message in messages:
        # Extract 'text' and 'sender' from each message
        text = message.get('text', '')
        sender = message.get('sender', 'unknown')
        
        # Map sender to role as required by Gemini
        if sender == 'user':
            role = 'user'
        else:
            role = 'system'  # Assuming non-user messages are system messages

        # Append formatted message to the list
        formatted_messages.append({
            'role': role,
            'content': text
        })
    
    return formatted_messages
# get the chat history from firebase
messages_ref = db.collection('users').document(userID).collection('conversations').document(conversationID).collection('messages')
#get the text and sender from each message

messages_query = messages_ref.order_by('createdAt', direction=firestore.Query.DESCENDING).stream()
for doc in messages_query:
    data = doc.to_dict()
    # Extract 'text' and 'sender', defaulting to empty string or 'unknown' if not present
    text = data.get('text', '')
    sender = data.get('sender', 'unknown')
    messages.append({'text': text, 'sender': sender})
gemini_history = format_messages_for_gemini(messages)
chat = model.start_chat(history = gemini_history)


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


@app.route('/upload_file', methods=['POST'])
def upload_file():
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

            return jsonify({"message": "File downloaded successfully"})
        else:
            return jsonify({"error": "Failed to download file"}), 400
    except Exception as e:
        logging.error(f"An error occurred during file upload: {e}")
        return jsonify({"error": f"An error occurred: {str(e)}"}), 400



def train_and_save_model(input_text, file_uploaded):
    global trained_model, preprocessor, poly, parameters, target_variable

    try:
        if not file_uploaded:
            raise ValueError("No file uploaded. Please upload a file first")

        logging.info(f"Starting model training with input_text: {input_text} and input_file: {file_uploaded}")

        # Directly use the train_model function from trainer.py
        target_variable, parameters, best_split, best_degree, mae, mse, r2, cv_scores, trained_model, preprocessor, poly = trainer.train_model(input_text, file_uploaded)

        logging.info("Model trained successfully")

        model_data = {
            "model": pickle.dumps(trained_model),
            "preprocessor": pickle.dumps(preprocessor),
            "poly": pickle.dumps(poly),
            "parameters": parameters,
            "target_variable": target_variable,
            "metrics": {
                "best_split": best_split,
                "best_degree": best_degree,
                "mae": mae,
                "mse": mse,
                "r2": r2,
                "cv_scores": cv_scores.tolist() if cv_scores is not None else None
            }
        }

        # Save the trained model to Firebase
        db.collection('models').document('trained_model').set(model_data)
        logging.info("Model saved to Firebase successfully")

        print("Model trained and stored in Firebase.")
        print("Target variable:", target_variable)
        print("Parameters:", parameters)

        return {
            "message": "Model trained and saved successfully",
            "target_variable": target_variable,
            "parameters": parameters,
        }

    except Exception as e:
        logging.error(f"An error in train_and_save_model: {str(e)}", exc_info=True)
        raise Exception(f"An error occurred during training: {str(e)}")


@app.route('/train', methods=['POST'])
def train_model():
    data = request.get_json()
    input_text = data.get('input_test')
    input_file = data.get('input_file')

    if not input_text or not input_file:
        return jsonify({"error": "Missing required parameters"}), 400

    try:
        train_and_save_model(input_text, input_file)
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


@app.route('/chat', methods=['POST'])
def chat_route():
    global conversationID, userID
    data = request.get_json()
    user_input = data.get('message')
    userID = data.get('userID')
    conversationID = data.get('conversationID')
    if not user_input:
        return jsonify({"error": "No message provided"}), 400
    
    response = generate_response(user_input)
    return jsonify({"response": response})


def format_messages_for_gemini(messages):
    formatted_messages = []
    
    # Define the role mappings for the messages
    role_mapping = {
        'user': 'user',
        'bot': 'model',  # Assuming 'bot' role should be mapped to 'model'
        'system': 'system'  # If you have any system messages, add appropriate mapping
    }
    
    for message in messages:
        # Extract 'text' and 'sender' from each message
        text = message.get('text', '')
        sender = message.get('sender', 'unknown')
        
        # Map sender to role as required by Gemini
        role = role_mapping.get(sender, 'system')  # Default to 'system' if sender is unknown

        # Append formatted message to the list with the specified format
        formatted_messages.append({
            'role': role,
            'parts': [
                {
                    'text': text
                }
            ]
        })
    
    return {'contents': formatted_messages}


def generate_response(user_input):

    global trained_model, preprocessor, poly, parameters, target_variable, file_uploaded, uploaded_file_path, messages

    messages_ref = db.collection('users').document(userID).collection('conversations').document(conversationID).collection('messages')
    #get the text and sender from each message
    messages = []
    messages_query = messages_ref.order_by('createdAt', direction=firestore.Query.DESCENDING).stream()
    for doc in messages_query:
        data = doc.to_dict()
        # Extract 'text' and 'sender', defaulting to empty string or 'unknown' if not present
        text = data.get('text', '')
        sender = data.get('sender', 'unknown')
        messages.append({'text': text, 'sender': sender})


    try:
        prompt = f"User: {user_input}\nAI:"
        option = filter_chat(user_input)

        # check if file has been uploaded
        if file_uploaded == False:
            return "Please upload a file first. Then, tell me the target variable you want to predict and the parameters you have access to. Once model is trained, give me the values of the indepedent variables. I will then predict the target variable for you."
        print(uploaded_file_path)

        
        if option == '0':
            # change coffee.csv      ------- ERROR HERE - NEED TO PASS IN CORRECT FILE UPLOADED BY USER -------
            print("Choosing option 0")
            target_variable, parameters, best_split, best_degree, mae, mse, r2, cv_scores, trained_model, preprocessor, poly = trainer.train_model(user_input, uploaded_file_path)
            # parameters = train_model("I want to predict the global prices. i have access to the rank, name, platform, year, genre, publisher sales and eu sales", "synthetic_vgsales_50.csv")
            return trainer.summarize_training_process()
        elif option == '1':
            print("Choosing option 1")
            user_values = get_values(user_input, parameters)
            print("User values are: ", user_values)
            prediction = predict(user_values, trained_model, parameters, preprocessor, poly)
            return f"Prediction: {prediction}"
        elif option == '2':
            print("Choosing option 2")
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


