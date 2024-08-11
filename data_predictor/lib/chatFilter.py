from flask import Flask, request, jsonify
from flask_cors import CORS  # Add this import
import os
import google.generativeai as genai
from csvToString import convert_csv_to_string, get_smaller_sample

# Check environment variable
# api_key = "AIzaSyCZkAAwGcd-TEIOuOOvYsZjXJWzduKY6qI"
api_key = "AIzaSyAw0O3QQZalaBbdhwaSpYREwBut_kP3wkw"

genai.configure(api_key=api_key)

generation_config = {
    "temperature": 0.15,
    "top_p": 1,
    "top_k": 0,
    "max_output_tokens": 2048,
    "response_mime_type": "text/plain",
}

def filter_chat(user_input):
    print("Filtering user input")
    model = genai.GenerativeModel(
        model_name="gemini-1.0-pro",
        generation_config=generation_config,
    )

    prompt = f"""
        "Analyse the input from the user. If the user is asking to train the model so it can predict some values later, return 0. If the user is giving the values for prediction return 1. If it is neither of these scenarios, return 2.\n\nYour output can either be 0,1, or 2. Nothing else.",
        "input: \"I want you to train the model.\"",
        "output: 0",
        "input: \"I want to know how many chicken breasts I need to order for next month.\"",
        "output: 0",
        
        "input: \"I wanna predict the sales for the next year.\"",
        "output: 1",
        "input: \"The rank is 4, name is Ryan. I think the year is 2007, and the platform is Tetra.\"",
        "output: 1",
        "input: \"The value for global sales is 500 and the temperature is 30.\"",
        "output: 1",
        "input: \"Rank is '2', Name is 'Game A', Platform is 'Switch', Year is '2026', Genre is 'Shooter', Publisher is 'Sony', NA_Sales is '7.43', EU_Sales is '8.64', 'JP_Sales' is 1.3. Predict the 'Global_Sales' for me\""
        "output: 1",
        
        "input: \"I want to make a sandwich\"",
        "output: 2",
        "input: \"What do you do for a living?\"",
        "output: 2",
        "input: \"I wanna predict something.\"",
        "output: 2",
        "input: {user_input}",
        "output: ",
        """

    response = model.generate_content([prompt])
    option = str(response.parts[0])[7:-2]

    return option

