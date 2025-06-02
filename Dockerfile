FROM node:18-alpine

WORKDIR /app

# No dependencies needed for ultra-minimal server

# Copy only the ultra-minimal server
COPY ultra-minimal.js ./

# Set environment variables
ENV NODE_ENV=production
ENV PORT=5000

# Expose the port the app runs on
EXPOSE 5000

# Start the ultra-minimal server
CMD ["node", "ultra-minimal.js"]
