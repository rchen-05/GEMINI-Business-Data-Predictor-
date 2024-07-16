import pandas as pd
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.svm import SVR
from sklearn.neighbors import KNeighborsRegressor
from sklearn.linear_model import Ridge, Lasso
from sklearn.preprocessing import PolynomialFeatures
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from getRegressor import get_regressor


# Load the data
vgsales = pd.read_csv('vgsales.csv')

# Prepare the features and target variable
X = vgsales[['NA_Sales', 'EU_Sales', 'JP_Sales', 'Other_Sales']]
y = vgsales['Global_Sales']

# Split the data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Get the model that is suggested by the AI as a string output
suggestedModel = get_regressor("vgsales.csv")

# Model that will be used to train the data
model = None

if suggestedModel == "Linear":
    model = LinearRegression()
elif suggestedModel == "DecisionTree":
    model = DecisionTreeRegressor()
elif suggestedModel == "Polynomial":
    model = PolynomialFeatures(degree=2)
elif suggestedModel == "RandomForest":
    model = RandomForestRegressor(random_state=42)

# Train the model
model.fit(X_train, y_train)

# Make predictions
predictions = model.predict(X_test)

# Evaluate the model using Mean Absolute Error
mae = mean_absolute_error(y_test, predictions)
print("Mean Absolute Error:", mae)

# Evaluate the model using Mean Squared Error
mse = mean_squared_error(y_test, predictions)
print("Mean Squared Error:", mse)

# Evaluate the model using R-squared
r2 = r2_score(y_test, predictions)
print("R-squared:", r2)
