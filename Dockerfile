FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Create uploads directory if it doesn't exist
RUN mkdir -p ./public/uploads

# Set environment variables
ENV NODE_ENV=production
ENV PORT=5000

# Expose the port
EXPOSE 5000

# Make sure stdout is unbuffered for proper logging
ENV NODE_OPTIONS="--unhandled-rejections=strict"

# Start the application with proper error handling
CMD ["node", "-e", "try { console.log('Starting server...'); require('./server.js'); } catch (e) { console.error('Server startup error:', e); process.exit(1); }"]
