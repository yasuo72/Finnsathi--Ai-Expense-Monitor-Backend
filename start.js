// Wrapper script for server.js with enhanced error handling and logging
console.log('=== FinSathi API Server Startup ===');
console.log('Current directory:', process.cwd());
console.log('Node version:', process.version);
console.log('Environment:', process.env.NODE_ENV || 'development');

// Set critical environment variables if not already set
process.env.PORT = process.env.PORT || '5000';
process.env.HOST = '0.0.0.0'; // Force binding to all network interfaces
process.env.NODE_ENV = process.env.NODE_ENV || 'production';

// Log MongoDB connection string (without password)
const mongoUriSafe = (process.env.MONGODB_URI || '').replace(/:[^:@]*@/, ':****@');
console.log('MongoDB URI:', mongoUriSafe);

// Log all environment variables for debugging
console.log('Environment variables:', {
  PORT: process.env.PORT,
  NODE_ENV: process.env.NODE_ENV,
  HOST: process.env.HOST,
  // Don't log sensitive information
  MONGODB_URI: mongoUriSafe ? 'Set' : 'Not set',
  JWT_SECRET: process.env.JWT_SECRET ? 'Set' : 'Not set'
});

// Create a simple HTTP server to respond to health checks
// This will run in parallel with the main server
const http = require('http');
const healthServer = http.createServer((req, res) => {
  if (req.url === '/health') {
    console.log('Health check received');
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'healthy',
      timestamp: new Date().toISOString()
    }));
  } else {
    res.writeHead(404);
    res.end();
  }
});

// Start health check server on a different port
const HEALTH_PORT = 8080;
healthServer.listen(HEALTH_PORT, '0.0.0.0', () => {
  console.log(`Health check server running on 0.0.0.0:${HEALTH_PORT}`);
});

// Try to start the main server with error handling
try {
  console.log('Starting main server...');
  require('./server.js');
} catch (error) {
  console.error('Failed to start server:', error);
  process.exit(1);
}
