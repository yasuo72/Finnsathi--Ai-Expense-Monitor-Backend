# User Segmentation and Behavior Analysis for FinSathi

import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

# Placeholder for data loading - in a real scenario, this would connect to FinSathi database
def load_user_behavior_data():
    # Simulated data: Replace with actual data loading logic
    data = {
        'user_id': range(1, 101),
        'monthly_spending': np.random.normal(2000, 500, 100).tolist(),
        'transaction_frequency': np.random.normal(15, 5, 100).tolist(),
        'average_transaction_amount': np.random.normal(100, 30, 100).tolist(),
        'savings_rate': np.random.normal(0.2, 0.1, 100).tolist()
    }
    df = pd.DataFrame(data)
    return df

# Perform user segmentation using K-Means clustering
def segment_users():
    df = load_user_behavior_data()
    
    # Select features for clustering
    features = df[['monthly_spending', 'transaction_frequency', 'average_transaction_amount', 'savings_rate']]
    
    # Standardize features
    scaler = StandardScaler()
    scaled_features = scaler.fit_transform(features)
    
    # Apply K-Means clustering
    kmeans = KMeans(n_clusters=4, random_state=42)
    df['cluster'] = kmeans.fit_predict(scaled_features)
    
    # Analyze clusters
    cluster_analysis = df.groupby('cluster').mean()
    print('Cluster Analysis:')
    print(cluster_analysis)
    
    # Provide descriptive labels based on analysis (simplified)
    cluster_labels = {
        0: 'Conservative Savers',
        1: 'Frequent Small Spenders',
        2: 'High Rollers',
        3: 'Balanced Users'
    }
    df['segment'] = df['cluster'].map(cluster_labels)
    
    print('\nUser Segmentation Results (first 10 users):')
    print(df[['user_id', 'cluster', 'segment']].head(10))
    
    return df, kmeans

if __name__ == '__main__':
    segmented_users, kmeans_model = segment_users()
