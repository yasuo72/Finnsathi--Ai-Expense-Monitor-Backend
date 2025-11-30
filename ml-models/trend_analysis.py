# Trend Analysis Models for FinSathi

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error

# Placeholder for data loading - in a real scenario, this would connect to FinSathi database
def load_data():
    # Simulated data: Replace with actual data loading logic
    data = {
        'month': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        'income': [5000, 5200, 5100, 5300, 5400, 5500, 5600, 5700, 5800, 5900, 6000, 6100],
        'expenses': [2000, 2200, 2100, 2400, 2300, 2500, 2600, 2700, 2800, 2900, 3000, 3100],
        'savings': [3000, 3000, 3000, 2900, 3100, 3000, 3000, 3000, 3000, 3000, 3000, 3000]
    }
    df = pd.DataFrame(data)
    return df

# Train a Random Forest model for trend analysis
def train_trend_model():
    df = load_data()
    X = df[['month']]
    y_expenses = df['expenses']
    y_income = df['income']
    y_savings = df['savings']
    
    # Train separate models for expenses, income, and savings
    models = {}
    for target, y in [('expenses', y_expenses), ('income', y_income), ('savings', y_savings)]:
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        model = RandomForestRegressor(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)
        predictions = model.predict(X_test)
        mse = mean_squared_error(y_test, predictions)
        print(f'Mean Squared Error for {target}: {mse}')
        models[target] = model
    
    return models

# Predict future trends
def predict_trends(models, future_months):
    future_data = np.array(future_months).reshape(-1, 1)
    predictions = {}
    for target, model in models.items():
        predictions[target] = model.predict(future_data)
    return predictions

if __name__ == '__main__':
    models = train_trend_model()
    future_months = [13, 14, 15]
    future_predictions = predict_trends(models, future_months)
    for target, preds in future_predictions.items():
        print(f'Predicted {target} for future months {future_months}: {preds}')
