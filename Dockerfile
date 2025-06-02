FROM node:18-alpine

WORKDIR /app

# Install dependencies first (for better caching)
COPY package*.json ./

# Install dependencies with legacy-peer-deps flag
RUN npm install --legacy-peer-deps

# Copy the rest of the application
COPY . .

# Create necessary directories
RUN mkdir -p ./public/uploads

# Set environment variables
ENV NODE_ENV=production
ENV PORT=5000

# Expose the port the app runs on
EXPOSE 5000

# Start the application with explicit host binding
CMD ["node", "-e", "process.env.PORT=5000; process.env.HOST='0.0.0.0'; try { require('./server.js') } catch (e) { console.error('Server failed to start:', e); process.exit(1); }"]
