FROM node:18-alpine

WORKDIR /app

# Install dependencies first (for better caching)
COPY package*.json ./

RUN npm install --legacy-peer-deps

# Copy the rest of the application
COPY . .

# Set environment variables
ENV NODE_ENV=production
ENV PORT=5000

# Create necessary directories
RUN mkdir -p ./public/uploads

# Expose the port the app runs on
EXPOSE 5000

# Start the application with proper error logging
CMD ["node", "-e", "try { require('./server.js') } catch (e) { console.error('Server failed to start:', e); process.exit(1); }"]
