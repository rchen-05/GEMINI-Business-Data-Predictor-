import pandas as pd
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.svm import SVR
from sklearn.neighbors import KNeighborsRegressor
from sklearn.linear_model import Ridge, Lasso, LinearRegression
from sklearn.preprocessing import PolynomialFeatures
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.preprocessing import OneHotEncoder, LabelEncoder
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
import joblib
import sys
from csvToString import convert_csv_to_string
from getTargetVariable import get_target_variable 
from getRegressor import get_regressor
from getParameters import get_user_parameters, get_all_parameters, get_all_relevant_parameters
from getValues import get_values

# Declare global variables
target_variable, parameters, best_split, best_degree, mae, mse, r2, cv_scores = None, None, None, None, None, None, None, None
model, preprocessor, poly = None, None, None

def load_data(input_file):
    try:
        df = pd.read_csv(input_file)
        return df
    except FileNotFoundError:
        print("Error: The file was not found.")
        sys.exit(1)
    except pd.errors.EmptyDataError:
        print("Error: The file is empty.")
        sys.exit(1)
    except pd.errors.ParserError:
        print("Error: The file could not be parsed.")
        sys.exit(1)

def select_target_and_features(input_text, df, input_file):
    global target_variable, parameters
    all_parameters = str(get_all_parameters(input_file)) #this gets all the parameters from the csv file
    target_variable = get_target_variable(input_text, all_parameters) #this gets the target variable from the input text
    relevant_parameters = get_all_relevant_parameters(input_file, target_variable) #this gets the parameters that are relevant to the prediction
    parameters = get_user_parameters(input_text, relevant_parameters).split(',') #this gets the parameters that the user has access to
    print('helo ryanL' + str(parameters))
    X = df[parameters]
    y = df[target_variable]
    return X, y, parameters, target_variable

def preprocess_data(X, categorical_columns):
    global preprocessor
    try:
        numeric_columns = X.select_dtypes(include=['int64', 'float64']).columns
        numeric_transformer = Pipeline(steps=[
            ('imputer', SimpleImputer(strategy='mean')),
        ])

        categorical_transformer = Pipeline(steps=[
            ('imputer', SimpleImputer(strategy='constant', fill_value='missing')),
            ('onehot', OneHotEncoder(handle_unknown='ignore', sparse_output=False))
        ])

        preprocessor = ColumnTransformer(
            transformers=[
                ('num', numeric_transformer, numeric_columns),
                ('cat', categorical_transformer, categorical_columns)
            ],
            remainder='passthrough'
        )

        X_encoded = preprocessor.fit_transform(X)

        onehot_columns = preprocessor.named_transformers_['cat'].named_steps['onehot'].get_feature_names_out(categorical_columns)
        feature_names = list(onehot_columns) + list(numeric_columns)

        return X_encoded, feature_names, preprocessor

    except Exception as e:
        print("Error during preprocessing:", e)
        sys.exit(1)

def initialize_model(suggested_model):
    model_mapping = {
        "Linear": LinearRegression(),
        "DecisionTree": DecisionTreeRegressor(),
        "RandomForest": RandomForestRegressor(n_estimators=100, max_depth=10, n_jobs=-1, random_state=42),
        "GradientBoosting": GradientBoostingRegressor(random_state=42),
        "SupportVector": SVR(),
        "KNearestNeighbours": KNeighborsRegressor(),
        "Ridge": Ridge(),
        "Lasso": Lasso()
    }

    if suggested_model in model_mapping:
        return model_mapping[suggested_model]
    elif suggested_model == "Polynomial":
        return LinearRegression()
    else:
        raise ValueError("Unsupported model type: " + suggested_model)

def find_best_split_and_degree(X, y, model, suggested_model):
    global best_split, best_degree
    best_score = float('-inf')
    best_split = None
    best_degree = None

    degrees = [2, 3, 4, 5] if suggested_model == "Polynomial" else [None]

    for test_size in [0.1, 0.2, 0.3, 0.4]:
        for degree in degrees:
            X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=test_size, random_state=42)

            if degree is not None:
                poly = PolynomialFeatures(degree=degree)
                X_train = poly.fit_transform(X_train)
                X_test = poly.transform(X_test)

            model.fit(X_train, y_train)
            predictions = model.predict(X_test)
            r2 = r2_score(y_test, predictions)

            if r2 > best_score:
                best_score = r2
                best_split = test_size
                best_degree = degree

    return best_split, best_degree

def evaluate_model(model, X_test, y_test):
    global mae, mse, r2
    predictions = model.predict(X_test)
    mae = mean_absolute_error(y_test, predictions)
    mse = mean_squared_error(y_test, predictions)
    r2 = r2_score(y_test, predictions)
    return mae, mse, r2

def cross_validate_model(model, X, y, best_degree=None):
    global cv_scores
    if best_degree is not None:
        poly = PolynomialFeatures(degree=best_degree)
        X_poly = poly.fit_transform(X)
        cv_scores = cross_val_score(model, X_poly, y, cv=5)
    else:
        cv_scores = cross_val_score(model, X, y, cv=5)
    return cv_scores

def predict(data, model, parameters, preprocessor, poly=None):
    df = pd.DataFrame([data], columns=parameters)
    df_encoded = preprocessor.transform(df)
    if poly is not None:
        df_encoded = poly.transform(df_encoded)
    prediction = model.predict(df_encoded)
    return prediction[0]

def summarize_training_process():
    summary = (
        f"Training Summary:\n"
        f"Target Variable: {target_variable}\n"
        f"Parameters Used: {', '.join(parameters)}\n"
        f"Best Split Ratio: {best_split}\n"
        f"Best Degree for Polynomial Regression: {best_degree if best_degree is not None else 'N/A'}\n"
        f"Mean Absolute Error: {mae}\n"
        f"Mean Squared Error: {mse}\n"
        f"R-squared: {r2}\n"
        f"Cross Validation Scores: {cv_scores}\n"
    )
    return summary

def train(input_text, input_file):
    global model, preprocessor, poly
    df = load_data(input_file)
    X, y, parameters, target_variable = select_target_and_features(input_text, df, input_file)
    categorical_columns = X.select_dtypes(include=['object']).columns
    X_encoded, feature_names, preprocessor = preprocess_data(X, categorical_columns)
    X_encoded = pd.DataFrame(X_encoded, columns=feature_names)

    suggested_model = get_regressor(input_file)
    model = initialize_model(suggested_model)

    best_split, best_degree = find_best_split_and_degree(X_encoded, y, model, suggested_model)

    X_train, X_test, y_train, y_test = train_test_split(X_encoded, y, test_size=best_split, random_state=42)
    poly = None
    if best_degree is not None:
        poly = PolynomialFeatures(degree=best_degree)
        X_train = poly.fit_transform(X_train)
        X_test = poly.transform(X_test)

    model.fit(X_train, y_train)
    model_filename = 'trained_model.pkl'
    joblib.dump(model, model_filename)
    print("Model saved as:", model_filename)

    mae, mse, r2 = evaluate_model(model, X_test, y_test)
    cv_scores = cross_validate_model(model, X_encoded, y, best_degree)

train("I want to predict the global prices. i have access to the rank, name, platform,year, genre, publisherna sales and eu sales", "synthetic_vgsales_50.csv")
print(summarize_training_process())
