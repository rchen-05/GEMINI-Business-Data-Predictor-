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
from csvToString import convert_csv_to_string, get_all_parameters
from getTargetVariable import get_target_variable 
from getRegressor import get_regressor
from getParameters import get_parameters


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
    target_variable = get_target_variable(input_text, str(get_all_parameters(convert_csv_to_string(input_file))))
    parameters = get_parameters(input_file, target_variable).split(',')
    X = df[parameters]
    y = df[target_variable]
    return X, y, parameters, target_variable


def preprocess_data(X, categorical_columns):
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
    predictions = model.predict(X_test)
    mae = mean_absolute_error(y_test, predictions)
    mse = mean_squared_error(y_test, predictions)
    r2 = r2_score(y_test, predictions)
    print("Mean Absolute Error:", mae)
    print("Mean Squared Error:", mse)
    print("R-squared:", r2)
    return predictions


def cross_validate_model(model, X, y, best_degree=None):
    if best_degree is not None:
        poly = PolynomialFeatures(degree=best_degree)
        X_poly = poly.fit_transform(X)
        cv_scores = cross_val_score(model, X_poly, y, cv=5)
    else:
        cv_scores = cross_val_score(model, X, y, cv=5)
    return cv_scores


def predict_sales(data, model, parameters, preprocessor, poly=None):
    df = pd.DataFrame([data], columns=parameters)
    df_encoded = preprocessor.transform(df)
    if poly is not None:
        df_encoded = poly.transform(df_encoded)
    prediction = model.predict(df_encoded)
    return prediction[0]


def main(input_text, input_file):
    df = load_data(input_file)
    X, y, parameters, target_variable = select_target_and_features(input_text, df, input_file)
    categorical_columns = X.select_dtypes(include=['object']).columns
    X_encoded, feature_names, preprocessor = preprocess_data(X, categorical_columns)
    X_encoded = pd.DataFrame(X_encoded, columns=feature_names)

    suggested_model = get_regressor(input_file)
    print("Suggested model:", suggested_model)
    model = initialize_model(suggested_model)

    best_split, best_degree = find_best_split_and_degree(X_encoded, y, model, suggested_model)
    print("Best split ratio:", best_split)
    if best_degree is not None:
        print("Best degree for Polynomial Regression:", best_degree)

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

    evaluate_model(model, X_test, y_test)
    cv_scores = cross_validate_model(model, X_encoded, y, best_degree)
    print("Cross Validation Score:", cv_scores)

    user_data = {param: input(f"Enter value for {param}: ") for param in parameters}
    predicted_sales = predict_sales(user_data, model, parameters, preprocessor, poly)
    print("Predicted target:", predicted_sales)


if __name__ == "__main__":
    main("i wanna know the average amount of coffee consumed a year", 'coffee.csv')
