import pandas as pd
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.svm import SVR
from sklearn.neighbors import KNeighborsRegressor
from sklearn.linear_model import Ridge, Lasso
from sklearn.preprocessing import PolynomialFeatures
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from getRegressor import get_regressor


def print_evaluation_metrics(y_test, predictions):
    mae = mean_absolute_error(y_test, predictions)  # Evaluate the model using Mean Absolute Error
    mse = mean_squared_error(y_test, predictions)  # Evaluate the model using Mean Squared Error
    r2 = r2_score(y_test, predictions)  # Evaluate the model using R-squared
    print("Mean Absolute Error:", mae)
    print("Mean Squared Error:", mse)
    print("R-squared:", r2)


def find_best_split_and_degree(X, y, model, suggestedModel):
    best_score = float('-inf')  # Starts with negative infinity
    best_split = None
    best_degree = None

    if suggestedModel == "Polynomial":
        degrees = [2, 3, 4, 5]  # Degrees to try: 2, 3, 4, 5
    else:
        degrees = [None]

    for test_size in [0.1, 0.2, 0.3, 0.4]:  # Split sizes to try: 10%, 20%, 30%, 40%
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


# Load the data
vgsales = pd.read_csv('vgsales.csv')

# Prepare the features and target variable
X = vgsales[['NA_Sales', 'EU_Sales', 'JP_Sales', 'Other_Sales']]
y = vgsales['Global_Sales']

# Split the data into training and testing sets (80% training, 20% testing)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Initialize the model - get suggested model from the API
# suggestedModel = get_regressor("vgsales.csv")
suggestedModel = "Linear"
print("Suggested model: " + suggestedModel)

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

if suggestedModel in model_mapping:
    model = model_mapping[suggestedModel]
elif suggestedModel == "Polynomial":
    model = LinearRegression()
else:
    raise ValueError("Unsupported model type: " + suggestedModel)

# Find the best split ratio
best_split, best_degree = find_best_split_and_degree(X, y, model, suggestedModel)
print("Best split ratio:", best_split)
if best_degree is not None:
    print("Best degree for Polynomial Regression:", best_degree)

# Split the data into training and testing sets using the best split ratio
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=best_split, random_state=42)

if best_degree is not None:
    poly = PolynomialFeatures(degree=best_degree)
    X_train = poly.fit_transform(X_train)
    X_test = poly.transform(X_test)

# Train the model
model.fit(X_train, y_train)

# Make predictions
predictions = model.predict(X_test)

# Calculate the cross validation score
if best_degree is not None:
    X_poly = poly.fit_transform(X)
    cv_scores = cross_val_score(model, X_poly, y, cv=5)
else:
    cv_scores = cross_val_score(model, X, y, cv=5)

print("Cross Validation Score:", cv_scores)

# Evaluate the model and print the metrics
print_evaluation_metrics(y_test, predictions)
