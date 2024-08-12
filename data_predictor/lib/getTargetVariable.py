from flask import Flask, request, jsonify
from flask_cors import CORS  # Add this import
import os
import google.generativeai as genai
from csvToString import convert_csv_to_string, get_smaller_sample
from getParameters import get_all_parameters

from dotenv import load_dotenv
load_dotenv()
api_key = os.getenv('API_KEY')

genai.configure(api_key=api_key)

generation_config = {
    "temperature": 0.50,
    "top_p": 1,
    "top_k": 0,
    "max_output_tokens": 2048,
    "response_mime_type": "text/plain",
}


def get_target_variable(inputText, availableParameters):
    print("Getting target variable")
    model = genai.GenerativeModel(
        model_name="gemini-1.0-pro",
        generation_config=generation_config,
    )

    # csv_string = convert_csv_to_string(input_csv)
    # smaller_sample = get_smaller_sample(csv_string)

    prompt = f"""
        "From the input text given by the user, I want you to decide what target variable the user wants to predict. The output you give should be included in the list of parameters I give you.",
        "input: Input text: \"I want to know my global sales for 2005\"\nAvailable parameters: [Rank,Name,Platform,Year,Genre,Publisher,NA_Sales,EU_Sales,JP_Sales,Other_Sales,Global_Sales]",
        "output: Global_Sales",
        "input: Input text: \"Help me predict the average amount of coffee consumed every year\"\nAvailable parameters:\n[Country,Year,Coffee Consumption (kg per capita per year),Average Coffee Price (USD per kg),Type of Coffee Consumed,Population (millions)]",
        "output: Coffee Consumption (kg per capita per year)",
        "input: Input text: \"I want to predict the prices of products before discount\"\nAvailable parameters:\n[product_id,product_name,category,discounted_price,actual_price,discount_percentage,rating,rating_count,about_product,user_id,user_name,review_id,review_title,review_content,img_link,product_link]",
        "output: actual_price",

        "input: Input text: \{inputText}\nAvailable parameters:\n{availableParameters}",
        "output: ",
        """

    response = model.generate_content([prompt])
    targetVariable = str(response.parts[0])[7:-2]
    print("Target Variable: " + targetVariable)
    return targetVariable

