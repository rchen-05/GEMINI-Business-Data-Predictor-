import csv

def convert_csv_to_string(input_file):
    output_string = ""
    
    with open(input_file, mode='r') as file:
        reader = csv.reader(file)
        for row in reader:
            output_string += ",".join(row) + "\\n"
    
    return output_string

def get_smaller_sample(csv_string): #get a smaller sample from the database
    lines = csv_string.split("\\n")
    smallerSample = lines[:100]  
    smallerSample = "\\n".join(smallerSample)
    return smallerSample



