# app.py
from flask import Flask, request, jsonify
import os
import google.generativeai as genai
from csvToString import convert_csv_to_string, get_smaller_sample

app = Flask(__name__)

# Configure the Google Generative AI model
def get_regressor(input_csv):
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        return "API key not found", 500

    genai.configure(api_key=api_key)

    generation_config = {
        "temperature": 0.15,
        "top_p": 1,
        "top_k": 0,
        "max_output_tokens": 2048,
        "response_mime_type": "text/plain",
    }

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

    try:
        response = model.generate_content([prompt])
        suggested_model = response.parts[0].strip()
        return suggested_model
    except Exception as e:
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
<<<<<<< Updated upstream
    app.run(debug=True)
=======
    app.run(debug=True,port=5001)
>>>>>>> Stashed changes
