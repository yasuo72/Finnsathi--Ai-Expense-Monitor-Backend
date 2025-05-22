// Custom error handler middleware
const errorHandler = (err, req, res, next) => {
  // Log error for debugging
  console.error(err.stack);

  // Default error values
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Server Error';
  let errors = [];

  // Handle Mongoose validation errors
  if (err.name === 'ValidationError') {
    statusCode = 400;
    message = 'Validation Error';
    errors = Object.values(err.errors).map(val => val.message);
  }

  // Handle Mongoose duplicate key errors
  if (err.code === 11000) {
    statusCode = 400;
    message = 'Duplicate Field Value Entered';
    
    // Extract the field causing the duplicate key error
    const field = Object.keys(err.keyValue)[0];
    errors.push(`${field.charAt(0).toUpperCase() + field.slice(1)} already exists`);
  }

  // Handle Mongoose cast errors (e.g., invalid ObjectId)
  if (err.name === 'CastError') {
    statusCode = 400;
    message = 'Invalid ID Format';
    errors.push(`Invalid ${err.path}`);
  }

  // Handle JWT errors
  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Invalid Token';
    errors.push('Please login again');
  }

  // Handle expired JWT errors
  if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Token Expired';
    errors.push('Please login again');
  }

  // Sanitize error response for production
  const errorResponse = {
    success: false,
    message,
    errors: errors.length > 0 ? errors : undefined
  };
  
  // Only include stack trace in development
  if (process.env.NODE_ENV === 'development') {
    errorResponse.stack = err.stack;
    console.error('Full error:', err);
  }
  
  // Return error response
  res.status(statusCode).json(errorResponse);
};

module.exports = errorHandler;
