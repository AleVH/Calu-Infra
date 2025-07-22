# NestJS Auth Service
FROM node:20-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy only dependency metadata files for install step
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Do not copy source code — Mutagen will handle that

# Start the service in dev mode once code is synced
CMD ["npm", "run", "start:dev"]