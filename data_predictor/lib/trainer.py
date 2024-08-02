import pandas as pd
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.svm import SVR
from sklearn.neighbors import KNeighborsRegressor
from sklearn.linear_model import Ridge, Lasso, LinearRegression
from sklearn.preprocessing import PolynomialFeatures
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from getRegressor import get_regressor
from getParameters import get_parameters
from sklearn.preprocessing import LabelEncoder, OneHotEncoder
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer


def print_evaluation_metrics(y_test, predictions):
    mae = mean_absolute_error(y_test, predictions)
    mse = mean_squared_error(y_test, predictions)
    r2 = r2_score(y_test, predictions)
    print("Mean Absolute Error:", mae)
    print("Mean Squared Error:", mse)
    print("R-squared:", r2)


def find_best_split_and_degree(X, y, model, suggestedModel):
    best_score = float('-inf')
    best_split = None
    best_degree = None

    if suggestedModel == "Polynomial":
        degrees = [2, 3, 4, 5]
    else:
        degrees = [None]

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


def predict_sales(data, model, parameters, preprocessor, poly=None):
    df = pd.DataFrame([data], columns=parameters)
    df_encoded = preprocessor.transform(df)
    if poly is not None:
        df_encoded = poly.transform(df_encoded)
    prediction = model.predict(df_encoded)
    return prediction[0]


def preprocess_data(X, categorical_columns):
    categorical_transformer = Pipeline(steps=[
        ('onehot', OneHotEncoder(handle_unknown='ignore', sparse=False))
    ])

    preprocessor = ColumnTransformer(
        transformers=[
            ('cat', categorical_transformer, categorical_columns)
        ],
        remainder='passthrough'
    )

    X_encoded = preprocessor.fit_transform(X)

    onehot_columns = preprocessor.named_transformers_['cat'].named_steps['onehot'].get_feature_names(categorical_columns)
    feature_names = list(onehot_columns) + list(X.columns.drop(categorical_columns))

    return X_encoded, feature_names, preprocessor


def main(input_file):
    # Load the data
    df = pd.read_csv(input_file)

    if 'Global_Sales' not in df.columns:
        raise ValueError("Target variable 'Global_Sales' not found in the dataset.")

    # Detect features and target variable
    parameters = get_parameters(input_file, 'Global_Sales').split(',')
    print("Selected parameters:", parameters)
    X = df[parameters]
    y = df['Global_Sales']

    categorical_columns = X.select_dtypes(include=['object']).columns

    # Preprocess the data
    X_encoded, feature_names, preprocessor = preprocess_data(X, categorical_columns)

    # Convert X_encoded to a DataFrame
    X_encoded = pd.DataFrame(X_encoded, columns=feature_names)

    # Initialize the model - get suggested model from the API
    suggested_model = get_regressor(input_file)
    print("Suggested model: " + suggested_model)

    # Mapping suggested models to their respective classes
    model_mapping = {
        "Linear": LinearRegression(),
        "DecisionTree": DecisionTreeRegressor(),
        "RandomForest": RandomForestRegressor(random_state=42),
        "GradientBoosting": GradientBoostingRegressor(random_state=42),
        "SupportVector": SVR(),
        "KNearestNeighbours": KNeighborsRegressor(),
        "Ridge": Ridge(),
        "Lasso": Lasso()
    }

    if suggested_model in model_mapping:
        model = model_mapping[suggested_model]
    elif suggested_model == "Polynomial":
        model = LinearRegression()
    else:
        raise ValueError("Unsupported model type: " + suggested_model)

    # Find the best split ratio
    best_split, best_degree = find_best_split_and_degree(X_encoded, y, model, suggested_model)
    print("Best split ratio:", best_split)
    if best_degree is not None:
        print("Best degree for Polynomial Regression:", best_degree)

    # Split the data into training and testing sets using the best split ratio
    X_train, X_test, y_train, y_test = train_test_split(X_encoded, y, test_size=best_split, random_state=42)

    if best_degree is not None:
        poly = PolynomialFeatures(degree=best_degree)
        X_train = poly.fit_transform(X_train)
        X_test = poly.transform(X_test)

    # Train the model
    model.fit(X_train, y_train)

    # Make predictions
    predictions = model.predict(X_test)

    # Calculate the cross-validation score
    if best_degree is not None:
        X_poly = poly.fit_transform(X_encoded)
        cv_scores = cross_val_score(model, X_poly, y, cv=5)
    else:
        cv_scores = cross_val_score(model, X_encoded, y, cv=5)

    print("Cross Validation Score:", cv_scores)

    # Evaluate the model and print the metrics
    print_evaluation_metrics(y_test, predictions)

    # Collect user input for prediction
    user_data = {}
    for param in parameters:
        while True:
            value = input(f"Enter value for {param}: ")
            try:
                user_data[param] = type(X[param].iloc[0])(value)  # Convert to the correct type
                break
            except ValueError:
                print("Invalid input. Please try again.")

        # value = input(f"Enter value for {param}: ")
        # user_data[param] = type(X[param].iloc[0])(value)  # Convert to the correct type

    # Predict sales for the given user data
    predicted_sales = predict_sales(user_data, model, parameters, preprocessor, poly if best_degree is not None else None)
    print("Predicted global sales:", predicted_sales)

# Call the main function with the input CSV file
main('vgsales.csv')
