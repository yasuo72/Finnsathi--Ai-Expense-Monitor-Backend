# Linear Regression Model for Expense Prediction

import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
import pandas as pd

# Placeholder for data loading - in a real scenario, this would connect to FinSathi database
def load_data():
    # Simulated data: Replace with actual data loading logic
    data = {
        'month': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        'expenses': [200, 220, 210, 240, 230, 250, 260, 270, 280, 290, 300, 310]
    }
    df = pd.DataFrame(data)
    return df

# Train the linear regression model
def train_model():
    df = load_data()
    X = df[['month']]
    y = df['expenses']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    model = LinearRegression()
    model.fit(X_train, y_train)
    
    predictions = model.predict(X_test)
    mse = mean_squared_error(y_test, predictions)
    print(f'Mean Squared Error: {mse}')
    
    return model

# Predict future expenses
def predict_expenses(model, future_months):
    future_data = np.array(future_months).reshape(-1, 1)
    predictions = model.predict(future_data)
    return predictions

if __name__ == '__main__':
    model = train_model()
    future_months = [13, 14, 15]
    future_predictions = predict_expenses(model, future_months)
    print(f'Predicted expenses for future months {future_months}: {future_predictions}')
