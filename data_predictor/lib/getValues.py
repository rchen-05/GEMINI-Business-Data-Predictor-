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

def try_convert(value):
    """Try to convert the value to an int or float if possible."""
    try:
        return int(value)
    except ValueError:
        try:
            return float(value)
        except ValueError:
            return value

def get_values(user_input, parameters):
    print("Getting values from user for prediction")
    model = genai.GenerativeModel(
        model_name="gemini-1.0-pro",
        generation_config=generation_config,
    )

    prompt = f"""
        "From the user input, provide the data in the order of the parameters given. Your output should be in a string form, with each value separated using a comma. For example, if I tell you y = 3, z = 1 and x = 2, and the parameters are given in the order of \"x,y,z\", then your output should be \"2,3,1\". Refrain from giving units.",
        "input: User input: \"The rank is 4, name is Ryan. I think the year is 2007, and the platform is Tetra\nParameters: Rank,Name,Platform,Year",
        "output: 4,Ryan,Tetra,2007",
        "input: User input: \"The country is Malaysia, this was in 2010. Coffee consumption is 60 and population is 70.\"\nParameters: Country,Year,Coffee Consumption (kg per capita per year),Population (millions)",
        "output: Malaysia,2010,60,70",
        "input: User input: \"Aisha is a  60kg female\"\nParameters: Name,Gender,Weight",
        "output: Aisha,female,60",

        "input: User input: {user_input}\nAvailable parameters:\n{parameters}",
        "output: ",
        """

    response = model.generate_content([prompt])
    values = str(response.parts[0])[7:-2].split(',')

    # Convert numerical values to int or float
    values = [try_convert(value.strip()) for value in values]

    return values


