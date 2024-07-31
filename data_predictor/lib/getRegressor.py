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

# Set your API key here
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
        logging.error(f"An error occurred: {e}")
        return f"An error occurred: {e}"

@app.route('/chat', methods=['POST'])
def chat_route():
    data = request.get_json()
    user_input = data.get('message')
    if not user_input:
        return jsonify({"error": "No message provided"}), 400
    
    response = generate_response(user_input)
    return jsonify({"response": response})



def get_regressor(input_csv):
    print("Getting regressor")
    try:
        model = genai.GenerativeModel(
            model_name="gemini-1.0-pro",
            generation_config=generation_config,
        )

        csv_string = convert_csv_to_string(input_csv)
        smaller_sample = get_smaller_sample(csv_string)

        prompt = f"""
        There are 7 main regression models: linear regression, decision tree regressor, random forest regressor, gradient boosting regressor, support vector regressor, k-nearest neighbours regressor, ridge and lasso regressor. Based on the data input, pick the most appropriate regression model for the dataset, based on accuracy, time, performance, flexibility. Just give me the name of the regression model without any extra elaboration or explanation.

        For Linear Regression, respond with Linear.
        For Decision Tree Regression, respond with DecisionTree.
        For Random Forest Regression, respond with RandomForest.
        For Gradient Boosting Regression, respond with GradientBoosting.
        For Support Vector Regression, respond with SupportVector.
        For k-nearest Neighbours Regression, respond with KNearestNeighbours.
        For Ridge and Lasso Regression, respond with RidgeAndLasso.
        For Polynomial Regression, respond with Polynomial.

        The only possible responses you should give are Linear, DecisionTree, Polynomial, RandomForest, GradientBoosting, SupportVector, KNearestNeighbours, RidgeAndLasso, and Polynomial.

        I only want ONE model.

        input: {smaller_sample}
        output: 
        """

        response = model.generate_content([prompt])
        suggested_model = str(response.parts[0])[7:-2]
        return suggested_model
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        return f"An error occurred: {e}", 500
@app.route('/get_regressor', methods=['POST'])

def get_regressor_route():
    data = request.get_json()
    csv_content = data.get('csv_content')
    if not csv_content:
        return jsonify({"error": "No CSV content provided"}), 400
    
    model = get_regressor(csv_content)
    return jsonify({"model": model})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
