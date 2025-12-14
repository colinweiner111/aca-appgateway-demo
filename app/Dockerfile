FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application files
COPY server.js ./

# Expose port
EXPOSE 3000

# Set environment variable
ENV PORT=3000

# Run as non-root user
USER node

# Start the application
CMD ["node", "server.js"]
