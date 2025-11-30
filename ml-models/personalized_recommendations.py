# Personalized Financial Recommendations for FinSathi Users

import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity

# Placeholder for data loading - in a real scenario, this would connect to FinSathi database
def load_user_data():
    # Simulated data: Replace with actual data loading logic
    data = {
        'user_id': range(1, 11),
        'monthly_income': np.random.normal(5000, 1000, 10).tolist(),
        'monthly_expenses': np.random.normal(3000, 800, 10).tolist(),
        'savings_goal': np.random.normal(1000, 300, 10).tolist(),
        'risk_tolerance': np.random.choice(['Low', 'Medium', 'High'], 10).tolist()
    }
    df = pd.DataFrame(data)
    return df

def load_recommendation_items():
    # Simulated recommendation items
    items = {
        'item_id': range(1, 6),
        'item_name': ['Savings Plan A', 'Investment Fund B', 'Budget Tool C', 'Insurance D', 'Credit Card E'],
        'risk_level': ['Low', 'High', 'Low', 'Medium', 'Medium'],
        'cost': [0, 500, 10, 200, 0],
        'potential_benefit': [200, 1000, 50, 500, 300]
    }
    return pd.DataFrame(items)

# Generate personalized recommendations
def generate_recommendations():
    user_data = load_user_data()
    items_data = load_recommendation_items()
    
    # Create user profile vectors based on financial behavior
    user_profiles = user_data[['monthly_income', 'monthly_expenses', 'savings_goal']].values
    
    # Create item vectors (simplified for demonstration)
    item_profiles = items_data[['cost', 'potential_benefit']].values
    
    # Calculate similarity between users and items
    similarity_matrix = cosine_similarity(user_profiles, item_profiles)
    
    recommendations = []
    for user_idx, user_id in enumerate(user_data['user_id']):
        user_risk = user_data.loc[user_idx, 'risk_tolerance']
        sim_scores = similarity_matrix[user_idx]
        
        # Filter items based on risk tolerance
        suitable_items = items_data[items_data['risk_level'] == user_risk]
        if not suitable_items.empty:
            item_indices = suitable_items.index
            filtered_scores = sim_scores[item_indices]
            top_item_idx = item_indices[np.argmax(filtered_scores)]
            recommended_item = items_data.loc[top_item_idx, 'item_name']
            recommendations.append({
                'user_id': user_id,
                'recommended_item': recommended_item,
                'similarity_score': max(filtered_scores)
            })
        else:
            recommendations.append({
                'user_id': user_id,
                'recommended_item': 'No suitable item found',
                'similarity_score': 0
            })
    
    recommendations_df = pd.DataFrame(recommendations)
    print('Personalized Recommendations:')
    print(recommendations_df)
    return recommendations_df

if __name__ == '__main__':
    generate_recommendations()
