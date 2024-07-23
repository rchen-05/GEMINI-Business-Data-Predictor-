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


# Load the data
vgsales = pd.read_csv('vgsales.csv')

# Prepare the features and target variable
X = vgsales[['NA_Sales', 'EU_Sales', 'JP_Sales', 'Other_Sales']]
y = vgsales['Global_Sales']

# Split the data into training and testing sets (80% training, 20% testing)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Initialize the model
# suggestedModel = get_regressor("vgsales.csv")
suggestedModel = "Linear"
print("Suggested model: " + suggestedModel)

# Mapping suggested models to their respective classes
model_mapping = {
    "Linear": LinearRegression(),
    "DecisionTree": DecisionTreeRegressor(),
    "RandomForest": RandomForestRegressor(random_state=42),
}

if suggestedModel in model_mapping:
    model = model_mapping[suggestedModel]
elif suggestedModel == "Polynomial":
    poly = PolynomialFeatures(degree=2)  # can test with other degrees, e.g., 3, 4, 5
    X_train = poly.fit_transform(X_train)
    X_test = poly.transform(X_test)
    model = LinearRegression()
else:
    raise ValueError("Unsupported model type: " + suggestedModel)

# Train the model
model.fit(X_train, y_train)

# Make predictions
predictions = model.predict(X_test)

# Calculate the cross validation score
cv_score = cross_val_score(model, X, y, cv=5)
print("Cross Validation Score:", cv_score)

# Evaluate the model using Mean Absolute Error
mae = mean_absolute_error(y_test, predictions)
print("Mean Absolute Error:", mae)

# Evaluate the model using Mean Squared Error
mse = mean_squared_error(y_test, predictions)
print("Mean Squared Error:", mse)

# Evaluate the model using R-squared
r2 = r2_score(y_test, predictions)
print("R-squared:", r2)
