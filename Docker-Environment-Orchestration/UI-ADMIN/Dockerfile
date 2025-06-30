# React Web - Admin
# Use the official Node.js 18 or 20 Alpine image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files first (for better caching)
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy the rest of your app source code
COPY . .

# Expose Next.js default port
EXPOSE 3000

# Start Next.js development server (for dev, use "next start" for production)
CMD ["npm", "run", "dev"]