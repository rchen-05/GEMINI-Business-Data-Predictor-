from flask import Flask, request, jsonify
from flask_cors import CORS  # Add this import
import os
import google.generativeai as genai
from csvToString import convert_csv_to_string, get_smaller_sample

# Check environment variable
api_key = "AIzaSyCZkAAwGcd-TEIOuOOvYsZjXJWzduKY6qI"

genai.configure(api_key=api_key)

generation_config = {
    "temperature": 0.15,
    "top_p": 1,
    "top_k": 0,
    "max_output_tokens": 2048,
    "response_mime_type": "text/plain",
}

def get_parameters(input_csv):
    print("Getting X values")
    model = genai.GenerativeModel(
        model_name="gemini-1.0-pro",
        generation_config=generation_config,
    )

    csv_string = convert_csv_to_string(input_csv)
    smaller_sample = get_smaller_sample(csv_string)

    prompt = f"""
        Based on the data input, I want you to decide the appropriate parameters for the feature matrix. List the parameters separated by commas. For example, your output should look like this:

        "Feature_X,Feature_Y,Feature_Z"

        I don't want any spaces at the front or back of the string. Make sure to include all the necessary features for the model to make accurate predictions.

        "input: Rank,Name,Platform,Year,Genre,Publisher,NA_Sales,EU_Sales,JP_Sales,Other_Sales,Global_Sales
        1,Wii Sports,Wii,2006,Sports,Nintendo,41.49,29.02,3.77,8.46,82.74
        2,Super Mario Bros.,NES,1985,Platform,Nintendo,29.08,3.58,6.81,0.77,40.24
        3,Mario Kart Wii,Wii,2008,Racing,Nintendo,15.85,12.88,3.79,3.31,35.82
        4,Wii Sports Resort,Wii,2009,Sports,Nintendo,15.75,11.01,3.28,2.96,33.00
        5,Pokemon Red/Pokemon Blue,GB,1996,Role-Playing,Nintendo,11.27,8.89,10.22,1.00,31.37
        6,Tetris,GB,1989,Puzzle,Nintendo,23.2,2.26,4.22,0.58,30.26
        7,New Super Mario Bros.,DS,2006,Platform,Nintendo,11.38,9.23,6.5,2.9,30.01
        8,Wii Play,Wii,2006,Misc,Nintendo,14.03,9.2,2.93,2.85,29.02
        9,New Super Mario Bros. Wii,Wii,2009,Platform,Nintendo,14.59,7.06,4.7,2.26,28.62
        10,Duck Hunt,NES,1984,Shooter,Nintendo,26.93,0.63,0.28,0.47,28.31
        11,Nintendogs,DS,2005,Simulation,Nintendo,9.07,11,1.93,2.75,24.76
        12,Mario Kart DS,DS,2005,Racing,Nintendo,9.81,7.57,4.13,1.92,23.42
        13,Pokemon Gold/Pokemon Silver,GB,1999,Role-Playing,Nintendo,9,6.18,7.2,0.71,23.11
        14,Wii Fit,Wii,2007,Sports,Nintendo,8.94,8.03,3.6,2.15,22.72
        15,Wii Fit Plus,Wii,2009,Sports,Nintendo,9.09,8.59,2.53,1.79,22.00
        16,Kinect Adventures!,X360,2010,Misc,Microsoft Game Studios,14.97,4.94,0.24,1.67,21.82
        17,Grand Theft Auto V,PS3,2013,Action,Take-Two Interactive,7.01,9.27,0.97,4.14,21.4",
        "output: NA_Sales,EU_Sales,JP_Sales,Other_Sales",

        input: Country,Year,Coffee Consumption (kg per capita per year),Average Coffee Price (USD per kg),Type of Coffee Consumed,Population (millions)
        Country_39,2023,9.25393898058043,6.467453002363636,Americano,65.92947787799916
        Country_29,2011,9.981202707003789,4.346744038378242,Mocha,82.4566803256807
        Country_15,2020,3.3129155167663225,8.76749607084824,Latte,110.93886185508133
        Country_43,2005,2.436180471026238,11.748750027123549,Espresso,43.13720708676692
        Country_8,2019,4.637848857169699,8.999098575256165,Mocha,65.48426225398772
        Country_21,2004,5.693273446091323,9.059761448623924,Latte,119.11865996978378
        Country_39,2022,3.638569976606836,11.367855453621516,Latte,138.46090217862474
        Country_19,2008,4.411399294388468,6.798276891113539,Mocha,133.80712298443183
        Country_23,2015,3.6069658855332616,12.270787708061752,Latte,72.16701186201222
        Country_11,2021,8.19408454745961,5.684248839963068,Mocha,78.60900375331319
        Country_11,2013,7.700623545978086,8.353256658145865,Latte,79.83671088067175
        Country_24,2021,7.079612126087854,11.216089193180098,Latte,130.43861988641524
        Country_36,2007,5.097742856633638,13.112059079532175,Latte,126.15098653376212
        Country_40,2019,9.272327530513888,12.706841782815609,Mocha,47.418346753256415
        Country_24,2018,9.75626033228016,11.938541592384677,Latte,25.264603723883255
        Country_3,2013,3.389114501003296,7.950060218900301,Americano,57.46720966232314
        Country_22,2006,3.7841011312950243,5.345347479230963,Americano,43.97255110416077
        Country_2,2004,6.205048224002957,6.3851763946228965,Americano,142.66632799742152
        Country_24,2017,2.7300045542579623,13.513171960341335,Americano,40.62143623635909
        Country_44,2001,5.4915871905849025,13.430645071459255,Americano,27.999795577313396",
        "output: Country,Year,Coffee Consumption (kg per capita per year),Average Coffee Price (USD per kg),Population (millions)",

        input: Make,Model,Year,Engine Size (L),Fuel Type,Price (USD)
        Volkswagen,Jetta,2010,4.2,Petrol,54073.09
        Honda,Pilot,2017,4.2,Hybrid,44924.91
        Nissan,Murano,2011,4.2,Hybrid,76963.44
        Toyota,RAV4,2010,2.4,Petrol,30871.25
        Nissan,Altima,2010,3.6,Petrol,72037.65
        Ford,Focus,2011,2.6,Petrol,64616.84
        Ford,Explorer,2016,2.0,Petrol,39159.35
        BMW,7 Series,2018,4.0,Diesel,21455.06
        Hyundai,Kona,2017,2.0,Electric,44998.91
        Chevrolet,Impala,2016,1.6,Petrol,59598.11
        BMW,3 Series,2013,2.9,Electric,58034.53
        Nissan,Sentra,2019,4.6,Diesel,60734.86
        Honda,Pilot,2014,1.2,Hybrid,65585.78
        Chevrolet,Impala,2016,2.6,Electric,19645.8
        Toyota,Corolla,2015,2.4,Petrol,41643.48
        Chevrolet,Malibu,2017,4.5,Diesel,41910.6
        Volkswagen,Tiguan,2019,1.4,Hybrid,63094.04
        BMW,3 Series,2020,4.9,Hybrid,16680.51
        Toyota,Camry,2018,1.7,Petrol,70906.11
        Ford,Focus,2016,2.3,Petrol,56343.74",
        "output: Make,Model,Year,Engine Size (L),Fuel Type,Price (USD)",

        input: {smaller_sample}
        output: 
        """

    response = model.generate_content([prompt])
    parameters = str(response.parts[0])[7:-2]
    print("paramt:" + parameters)
    return parameters
    
    