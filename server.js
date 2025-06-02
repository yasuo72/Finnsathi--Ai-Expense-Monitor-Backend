const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const bodyParser = require('body-parser');
const path = require('path');
const fileUpload = require('express-fileupload');

// Load environment variables
dotenv.config();

// Import routes
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const transactionRoutes = require('./routes/transaction.routes');
const budgetRoutes = require('./routes/budget.routes');
const savingsGoalRoutes = require('./routes/savingsGoal.routes');
const walletRoutes = require('./routes/wallet.routes');
const gamificationRoutes = require('./routes/gamification.routes');
const statisticsRoutes = require('./routes/statistics.routes');
const notificationRoutes = require('./routes/notification.routes');
const chatbotRoutes = require('./routes/chatbot.routes');
const predictionRoutes = require('./routes/prediction.routes');
const uploadRoutes = require('./routes/upload.routes');

// Initialize Express app
const app = express();

// Middleware
// Configure CORS
// Configure CORS based on environment
const corsOptions = {
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://finnsathi.vercel.app', /\.railway\.app$/] // Add your frontend domains
    : process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
};

app.use(cors(corsOptions));

// Body parser middleware
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// File upload middleware with environment-specific configuration
app.use(fileUpload({
  useTempFiles: process.env.NODE_ENV === 'production',
  tempFileDir: process.env.NODE_ENV === 'production' ? '/tmp/' : './tmp/',
  createParentPath: true,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max file size
  debug: process.env.NODE_ENV !== 'production'
}));

// Regular express.json() parser
app.use(express.json());

// Set up static file serving for uploads
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));

// Additional route to handle direct file access without user ID in path
app.get('/uploads/:filename', (req, res) => {
  const filename = req.params.filename;
  // Search for the file in all user directories
  const uploadsDir = path.join(__dirname, 'public/uploads');
  
  // Read all user directories
  fs.readdir(uploadsDir, (err, userDirs) => {
    if (err) {
      console.error('Error reading uploads directory:', err);
      return res.status(404).send('File not found');
    }
    
    // Try to find the file in each user directory
    let fileFound = false;
    
    // Function to check each directory
    const checkNextDir = (index) => {
      if (index >= userDirs.length) {
        // We've checked all directories and didn't find the file
        if (!fileFound) {
          return res.status(404).send('File not found');
        }
        return;
      }
      
      const userDir = userDirs[index];
      const filePath = path.join(uploadsDir, userDir, filename);
      
      // Check if file exists in this user directory
      fs.access(filePath, fs.constants.F_OK, (err) => {
        if (!err) {
          // File found, serve it
          fileFound = true;
          return res.sendFile(filePath);
        } else {
          // Try next directory
          checkNextDir(index + 1);
        }
      });
    };
    
    // Start checking directories
    checkNextDir(0);
  });
});

// Create uploads directory if it doesn't exist
const fs = require('fs');
const uploadDir = path.join(__dirname, 'public/uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Connect to MongoDB
// You can use an existing MongoDB URL by setting MONGODB_URI in your .env file
// For different apps using the same MongoDB instance, you can use different database names:
// Example: mongodb+srv://username:password@cluster.mongodb.net/finnsathi
// vs:      mongodb+srv://username:password@cluster.mongodb.net/other_app_name
const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URL || 'mongodb://localhost:27017/finnsathi';

// Optional: Extract database name from connection string for logging
let dbName = 'finnsathi';
try {
  // Try to extract database name from the connection string
  const urlParts = mongoUri.split('/');
  if (urlParts.length > 3) {
    dbName = urlParts[urlParts.length - 1].split('?')[0];
  }
} catch (e) {
  // Ignore parsing errors
}

mongoose.connect(mongoUri)
.then(() => console.log(`MongoDB connected to database: ${dbName}`))
.catch(err => console.error('MongoDB connection error:', err));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/savings-goals', savingsGoalRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/gamification', gamificationRoutes);
app.use('/api/statistics', statisticsRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/predictions', predictionRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to FinSathi API' });
});

// Health check endpoint for Railway
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Error handling middleware (must be after routes)
const errorHandler = require('./middleware/errorHandler');
app.use(errorHandler);

// 404 handler for routes not found
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found'
  });
});

// Start server
const PORT = process.env.PORT || 5000;

// Log startup information
console.log('=== FinSathi API Server Starting ===');
console.log('Current directory:', process.cwd());
console.log('Node version:', process.version);
console.log('Environment:', process.env.NODE_ENV || 'development');

// Log MongoDB connection string (without password for security)
const mongoUriSafe = (process.env.MONGODB_URI || '').replace(/:[^:@]*@/, ':****@');
console.log('MongoDB URI:', mongoUriSafe);

// Log all environment variables (except sensitive ones)
console.log('Environment variables:', {
  PORT: process.env.PORT,
  NODE_ENV: process.env.NODE_ENV,
  MONGODB_URI: mongoUriSafe ? 'Set' : 'Not set',
  JWT_SECRET: process.env.JWT_SECRET ? 'Set' : 'Not set'
});

try {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log('Health check endpoint available at: /health');
  });
} catch (error) {
  console.error('Failed to start server:', error);
  process.exit(1);
}
