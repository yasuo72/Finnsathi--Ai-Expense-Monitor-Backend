@echo off
@echo Running all ML Models for FinSathi
python linear_regression.py
python trend_analysis.py
python anomaly_detection.py
python personalized_recommendations.py
python time_series_forecasting.py
python user_segmentation.py
@echo Model execution complete. Check above for results.
pause
