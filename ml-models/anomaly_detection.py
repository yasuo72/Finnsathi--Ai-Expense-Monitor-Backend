# Anomaly Detection for Financial Transactions in FinSathi

import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

# Placeholder for data loading - in a real scenario, this would connect to FinSathi database
def load_transaction_data():
    # Simulated data: Replace with actual data loading logic
    data = {
        'transaction_id': range(1, 101),
        'amount': np.random.normal(100, 50, 100).tolist(),
        'timestamp': pd.date_range(start='2023-01-01', periods=100, freq='H'),
        'category': np.random.choice(['Food', 'Transport', 'Entertainment', 'Bills', 'Other'], 100).tolist()
    }
    # Introduce some anomalies
    data['amount'][5] = 1000  # Unusually high transaction
    data['amount'][20] = -200  # Unusual negative transaction
    df = pd.DataFrame(data)
    return df

# Detect anomalies in transactions
def detect_anomalies():
    df = load_transaction_data()
    
    # Feature engineering
    features = df[['amount']]
    scaler = StandardScaler()
    scaled_features = scaler.fit_transform(features)
    
    # Train Isolation Forest model for anomaly detection
    model = IsolationForest(contamination=0.1, random_state=42)
    model.fit(scaled_features)
    
    # Predict anomalies (-1 for anomaly, 1 for normal)
    df['anomaly'] = model.predict(scaled_features)
    anomalies = df[df['anomaly'] == -1]
    
    print(f'Detected {len(anomalies)} anomalies in the dataset.')
    print(anomalies[['transaction_id', 'amount', 'category', 'timestamp']])
    
    return model, anomalies

# Function to check if a new transaction is anomalous
def check_new_transaction(model, transaction_amount):
    scaled_amount = StandardScaler().fit_transform([[transaction_amount]])
    prediction = model.predict(scaled_amount)
    return prediction[0] == -1

if __name__ == '__main__':
    model, anomalies = detect_anomalies()
    # Example of checking a new transaction
    new_transaction_amount = 800
    is_anomalous = check_new_transaction(model, new_transaction_amount)
    print(f'Is new transaction of ${new_transaction_amount} anomalous? {is_anomalous}')
