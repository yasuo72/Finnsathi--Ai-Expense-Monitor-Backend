FROM node:18-alpine

WORKDIR /app

# Install only essential dependencies for diagnosis
COPY package.json ./

RUN npm install --no-package-lock express dotenv

# Copy only the minimal server and environment files
COPY minimal-server.js ./
COPY .env* ./

# Set environment variables
ENV NODE_ENV=production
ENV PORT=5000

# Expose the port the app runs on
EXPOSE 5000

# Start the minimal diagnostic server
CMD ["node", "minimal-server.js"]
