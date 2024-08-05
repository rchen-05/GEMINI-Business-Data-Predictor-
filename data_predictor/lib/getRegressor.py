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

        "input: Date,NA_Sales,EU_Sales,JP_Sales,Other_Sales,Global_Sales\n2022-01-01,0.34,0.20,0.05,0.10,0.69\n2022-01-02,0.30,0.25,0.07,0.12,0.74\n2022-01-03,0.40,0.22,0.06,0.15,0.83\n2022-01-04,0.33,0.24,0.05,0.11,0.73\n2022-01-05,0.35,0.21,0.08,0.10,0.74\n2022-01-06,0.32,0.23,0.07,0.13,0.75\n2022-01-07,0.38,0.26,0.09,0.14,0.87\n2022-01-08,0.31,0.27,0.10,0.12,0.80\n2022-01-09,0.36,0.25,0.08,0.13,0.82\n2022-01-10,0.34,0.28,0.09,0.14,0.85",
        "output: RandomForest",
        "input: X,Y\n1,2\n2,4\n3,6\n4,8\n5,10\n6,12\n7,14\n8,16\n9,18\n10,20",
        "output: Linear",
        "input: Feature1,Feature2,Feature3,Target\n0.5,0.2,0.1,1.4\n0.6,0.1,0.3,1.2\n0.8,0.4,0.2,1.8\n1.0,0.5,0.3,2.1\n1.2,0.3,0.4,2.0\n1.4,0.6,0.5,2.5\n1.6,0.7,0.6,2.8\n1.8,0.4,0.7,2.9\n2.0,0.9,0.8,3.4\n2.2,0.8,0.9,3.6",
        "output: RandomForest",
        "input: X,Y\n1,1\n2,4\n3,9\n4,16\n5,25\n6,36\n7,49\n8,64\n9,81\n10,100",
        "output: Polynomial",
        "input: Feature1,Feature2,Feature3,Target\n1.1,0.3,0.4,3.4\n1.5,0.4,0.5,4.1\n1.8,0.2,0.2,4.6\n2.2,0.5,0.6,5.2\n2.6,0.6,0.7,6.1\n3.1,0.8,0.5,6.7\n3.5,0.7,0.6,7.4\n3.9,0.3,0.8,8.2\n4.2,0.9,0.7,9.1\n4.5,0.2,0.3,9.4",
        "output: DecisionTree",

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
