# Backend Connection Setup

This document explains how to connect the Flutter frontend with the Node.js backend.

## Environment Setup

1. Copy the `.env.example` file to a new file named `.env`:

```bash
cp .env.example .env
```

2. Edit the `.env` file to set the correct backend URL:

- For Android emulator: `BACKEND_BASE_URL=http://10.0.2.2:5000`
- For iOS simulator: `BACKEND_BASE_URL=http://localhost:5000`
- For physical devices: Use the actual IP address of your backend server

## API Service

The app uses the following services to connect with the backend:

1. `app_config.dart` - Contains configuration settings including the backend URL
2. `api_service.dart` - Provides HTTP methods to communicate with the backend
3. Individual service classes for specific API endpoints (auth, transactions, etc.)

## Switching to Real Backend

By default, the app is configured to use mock services for development. To use the real backend:

1. Make sure your backend server is running (default port: 5000)
2. In `auth_service.dart`, set `useMockService = false`
3. Ensure your `.env` file has the correct `BACKEND_BASE_URL` value

## API Endpoints

The backend provides the following API endpoints:

- Authentication: `/api/auth/*`
- Users: `/api/users/*`
- Transactions: `/api/transactions/*`
- Budgets: `/api/budgets/*`
- Savings Goals: `/api/savings-goals/*`
- Wallet: `/api/wallet/*`
- Gamification: `/api/gamification/*`
- Statistics: `/api/statistics/*`
- Notifications: `/api/notifications/*`
- Chatbot: `/api/chatbot/*`
- Predictions: `/api/predictions/*`

## Testing the Connection

To test if the backend connection is working:

1. Start the backend server
2. Set `useMockService = false` in the relevant service files
3. Run the Flutter app and try to login or register
4. Check the console logs for any connection errors
