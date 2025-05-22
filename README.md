# FinSathi Backend API

This is the backend API for the FinSathi expense tracking and financial management application.

## Setup Instructions

### Prerequisites
- Node.js (v14 or higher)
- MongoDB (local installation or MongoDB Atlas account)

### Installation

1. Clone the repository
2. Navigate to the backend directory:
   ```
   cd backend
   ```
3. Install dependencies:
   ```
   npm install
   ```
4. Create a `.env` file based on `.env.example` and configure your environment variables:
   ```
   cp .env.example .env
   ```
5. Edit the `.env` file with your specific configuration

### Running the Server

#### Development Mode
```
npm run dev
```

#### Production Mode
```
npm start
```

## API Endpoints

### Authentication
- POST `/api/auth/register` - Register a new user
- POST `/api/auth/login` - Login existing user
- POST `/api/auth/verify` - Verify OTP
- POST `/api/auth/forgot-password` - Request password reset
- POST `/api/auth/reset-password` - Reset password
- GET `/api/auth/me` - Get current user profile (protected)

### Transactions
- GET `/api/transactions` - Get all transactions
- POST `/api/transactions` - Create a new transaction
- GET `/api/transactions/:id` - Get a specific transaction
- PUT `/api/transactions/:id` - Update a transaction
- DELETE `/api/transactions/:id` - Delete a transaction
- GET `/api/transactions/stats` - Get transaction statistics
- GET `/api/transactions/trends` - Get transaction trends

### Budgets
- GET `/api/budgets` - Get all budgets
- POST `/api/budgets` - Create a new budget
- GET `/api/budgets/:id` - Get a specific budget
- PUT `/api/budgets/:id` - Update a budget
- DELETE `/api/budgets/:id` - Delete a budget

### Savings Goals
- GET `/api/savings-goals` - Get all savings goals
- POST `/api/savings-goals` - Create a new savings goal
- GET `/api/savings-goals/:id` - Get a specific savings goal
- PUT `/api/savings-goals/:id` - Update a savings goal
- DELETE `/api/savings-goals/:id` - Delete a savings goal

### File Uploads
- POST `/api/upload` - Upload a file
- DELETE `/api/upload/:fileName` - Delete a file

## Frontend Integration

To connect the Flutter frontend to this backend:

1. Ensure the backend server is running
2. Configure the frontend's `.env` file with the correct backend URL:
   - For Android emulator: `BACKEND_BASE_URL=http://10.0.2.2:5000`
   - For iOS simulator: `BACKEND_BASE_URL=http://localhost:5000`
   - For physical devices: Use the actual IP address or domain where your backend is hosted

3. Make sure the `useMockData` flag in the frontend is set to `false` to use the real API instead of mock data.

## Notes

- The API uses JWT for authentication. Include the token in the Authorization header as `Bearer <token>` for protected routes.
- All API responses follow a standard format with `success`, `message`, and `data` fields.
- File uploads are stored in the `public/uploads` directory and can be accessed at `/uploads/{userId}/{fileName}`.
