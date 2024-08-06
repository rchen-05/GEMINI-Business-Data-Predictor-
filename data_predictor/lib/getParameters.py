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


def get_all_parameters(input_file):  # get a smaller sample from the database
    lines = convert_csv_to_string(input_file).split("\\n")
    parameters = lines[:1]
    return parameters


def get_all_relevant_parameters(input_file, target_variable):
    print("Getting X values")
    model = genai.GenerativeModel(
        model_name="gemini-1.0-pro",
        generation_config=generation_config,
    )

    # csv_string = convert_csv_to_string(input_csv)
    # smaller_sample = get_smaller_sample(csv_string)
    available_parameters = str(get_all_parameters((input_file)))

    prompt = f"""
        "There will be a target variable input, representing what the user wants to predict. There will also be a list of parameters you could choose from to be included in the feature matrix, which will be fed into the machine learning model. \n\nFor example, the itarget variable could be: \"gross income\".\n\n\nAnd the available parameters could be: Invoice ID,Branch,City,Customer type,Gender,Product line,Unit price,Quantity,Tax 5%,Total,Date,Time,Payment,cogs,gross margin percentage,gross income,Rating\n\nYou should respond with the relevant features to predict the target variable gross income, like \"Branch,City,Customer type,Gender,Product line,Unit price,Quantity,Tax 5%,Total,Date,Time,Payment,cogs,gross margin percentage,Rating\"\n\n\nDon't include irrelevant parameters. For example, if I'm trying to predict employee salary, employee ID should not matter as there will never be any correlation between employee salary and employee ID.\n\n\nAs you can see, the parameter Invoice ID is not included, as it is not relevant to predicting the target variable gross income. The parameter gross income itself is also not included in the output, as that is the target variable itself.\n\nI don't want any spaces at the front or back of the string. Make sure to include all the necessary features for the model to make accurate predictions.",
        "Don't exclude string attributes as they might be important for prediction (as we can use OneHotEncoding, for example, to transform these variables into meaningful data).",
        "input: Target variable: Price (USD)\nAvailable parameters: Make,Model,Year,Engine Size (L),Fuel Type,Price (USD)",
        "output: Make,Model,Year,Engine Size (L),Fuel Type",
        "input: Target variable: Average Coffee Price (USD per kg)\nAvailable parameters: Country,Year,Coffee Consumption (kg per capita per year),Average Coffee Price (USD per kg),Type of Coffee Consumed,Population (millions)",
        "output: Country,Year,Coffee Consumption (kg per capita per year),Type of Coffee Consumed,Population (millions)",
        "input: Target variable: Total Sales\nAvailable parameters: StoreID,ProductID,ProductCategory,QuantitySold,UnitPrice,Discount,Date,Time,PaymentMethod,Region,CustomerID,CustomerAge,CustomerGender,Total Sales",
        "output: StoreID,ProductID,ProductCategory,QuantitySold,UnitPrice,Discount,Date,Time,PaymentMethod,Region,CustomerAge,CustomerGender",
        "input: Target variable: Employee Salary\nAvailable parameters: \nEmployeeID,Department,JobTitle,YearsOfExperience,EducationLevel,PerformanceScore,Employee Salary,Gender,Age,Region,MaritalStatus",
        "output: Department,JobTitle,YearsOfExperience,EducationLevel,PerformanceScore,Gender,Age,Region,MaritalStatus",
        "input: Target Variable: CarResaleValue\nAvailable parameters: CarID,Make,Model,Year,EngineSize,Transmission,FuelType,Mileage,Color,Condition,CarResaleValue,NumberOfOwners,AccidentHistory,ServiceHistory,MarketDemand",
        "output: Make,Model,Year,EngineSize,Transmission,FuelType,Mileage,Color,Condition,NumberOfOwners,AccidentHistory,ServiceHistory,MarketDemand",

        "input: Target Variable: {target_variable}\nAvailable parameters: {available_parameters}",
        "output: ",
        """

    response = model.generate_content([prompt])
    all_relevant_parameters = str(response.parts[0])[7:-2]
    return all_relevant_parameters


def get_user_parameters(user_input, all_relevant_parameters):
    print("Getting user parameters")
    model = genai.GenerativeModel(
        model_name="gemini-1.0-pro",
        generation_config=generation_config,
    )

    prompt = f"""
        "Based on the input text, select the parameters the user has access to from the given list. The parameters that you give should ONLY be from the list of available parameters, so if the user gives a parameter but that parameter is not included in the list, do NOT include it. Your output should only be a string consisting of each parameter separated by a comma, for example \"x,y,z\".",
        "input: User input: \"I have data for the make, model, type of transmission and the car's condition\"\nAvailable parameters: Make,Model,Year,EngineSize,Transmission,FuelType,Mileage,Color,Condition,NumberOfOwners,AccidentHistory,ServiceHistory,MarketDemand",
        "output: Make,Model,Transmission,Condition",
        "input: User input: \"department, job title, level of education, whether theyre married or not, retirement status\nAvailable parameters: \nDepartment,JobTitle,YearsOfExperience,EducationLevel,PerformanceScore,Gender,Age,Region,MaritalStatus",
        "output: Deparment,JobTitle,EducationLevel,MaritalStatus",
        "input: User input: \"I have platform, year, genre, type of game, and console\"\nAvailable parameters:\nRank,Name,Platform,Year,Genre,Publisher,NA_Sales,EU_Sales,JP_Sales,Other_Sales,Global_Sales",
        "output: Platform,Year,Genre",
        "input: User input: \"The only thing I don't have access to is the type of coffee consumed. I have everything else though.\"\nAvailable parameters:\nCountry,Year,Coffee Consumption (kg per capita per year),Type of Coffee Consumed,Population (millions)",
        "output: Country,Year,Coffee Consumption (kg per capita per year),Population (millions)",
        "input: User input: \{user_input}\nAvailable parameters: {all_relevant_parameters}",
        "output: ",
        """

    response = model.generate_content([prompt])
    user_parameters = str(response.parts[0])[7:-2]
    return user_parameters


print(get_user_parameters("i have rank, name platform and year",
                          get_all_relevant_parameters('vgsales.csv', 'global_sales')))
