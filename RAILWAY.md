# Deploying FinSathi Backend to Railway

This guide provides instructions for deploying the FinSathi backend API to Railway.

## Prerequisites

- A [Railway](https://railway.app/) account (you can sign up with GitHub)
- Your code pushed to a GitHub repository

## Deployment Steps

### 1. Push Your Code to GitHub

If you haven't already pushed your code to GitHub:

```bash
git add .
git commit -m "Prepare backend for Railway deployment"
git remote add origin https://github.com/yourusername/your-repo-name.git
git push -u origin main
```

### 2. Deploy to Railway

1. Go to [Railway](https://railway.app/) and sign in
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Choose your repository
5. Railway will automatically detect your Node.js app and start the deployment

### 3. Configure Environment Variables

In your Railway project dashboard:

1. Go to the "Variables" tab
2. Add the following variables:
   - `NODE_ENV` = `production`
   - `JWT_SECRET` = `[a-secure-random-string]`
   - `JWT_EXPIRE` = `30d`
   - `SYSTEM_API_KEY` = `[another-secure-random-string]`

### 4. Add MongoDB Database

1. In your Railway project, click "New"
2. Select "Database" → "MongoDB"
3. Railway will automatically create a MongoDB instance and set the connection variables

### 5. Verify Deployment

1. Once deployment is complete, Railway will provide you with a URL
2. Test the health endpoint: `https://your-app-name.up.railway.app/health`
3. Test your API endpoints using Postman with this URL

## Updating Your Frontend

Update your Flutter app's `.env` file with the new Railway URL:

```
BACKEND_BASE_URL=https://your-app-name.up.railway.app
API_VERSION=v1
APP_ENV=production
USE_MOCK_DATA=false
```

## Troubleshooting

If you encounter issues:

1. Check Railway logs in the dashboard
2. Verify your environment variables are set correctly
3. Make sure MongoDB is properly connected
4. Check the health endpoint for status information
