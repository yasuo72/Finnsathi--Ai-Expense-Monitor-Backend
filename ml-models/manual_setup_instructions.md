# Manual Setup Instructions for ML Models

Due to potential issues with automated command execution, please follow these manual steps to set up and run the machine learning models for FinSathi:

1. **Ensure Python is Installed**: Make sure you have Python installed on your system. You can download it from [python.org](https://www.python.org/downloads/).

2. **Install Dependencies**: Open a terminal or command prompt, navigate to the `ml-models` directory, and run the following command to install the required libraries:
   ```
   pip install -r requirements.txt
   ```

3. **Run the Models**: After installing the dependencies, you can run each model individually with these commands:
   - For Linear Regression (Expense Prediction):
     ```
     python linear_regression.py
     ```
   - For Trend Analysis (Income, Expenses, Savings):
     ```
     python trend_analysis.py
     ```
   Alternatively, use the batch file to run all models at once:
   ```
   run_all_models.bat
   ```

4. **Check Output**: The scripts will print prediction results to the console. Review these outputs to ensure the models are functioning as expected.

5. **Integration**: Refer to `integration_notes.md` for steps on connecting these models to the FinSathi app backend and frontend.

If you encounter any errors during setup or execution, note the error messages and consider checking Python's installation or seeking assistance with the specific error.
