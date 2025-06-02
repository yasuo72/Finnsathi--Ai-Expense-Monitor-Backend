const express = require('express');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

// Initialize Express app
const app = express();

// Health check endpoint for Railway
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Root route
app.get('/', (req, res) => {
  res.json({ 
    message: 'FinSathi API Diagnostic Server',
    env: {
      NODE_ENV: process.env.NODE_ENV,
      PORT: process.env.PORT,
      // Don't include sensitive info like MONGODB_URI or JWT_SECRET
      CORS_ORIGIN: process.env.CORS_ORIGIN
    }
  });
});

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Diagnostic server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
