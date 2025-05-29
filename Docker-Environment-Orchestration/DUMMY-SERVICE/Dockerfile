# Use a lightweight Node.js image
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install only what's needed
RUN npm install --silent

# Copy the remaining source code
COPY . .

# Expose the internal port the service runs on
EXPOSE 3002

# Start the service using the defined script
CMD [ "npm", "start" ]