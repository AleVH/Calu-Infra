# Node.js + BullMQ Redis Worker
# Use Node image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files and install
COPY package*.json ./
RUN npm install

# Copy source files and compile
COPY . .
RUN npm run build

# Run the worker
CMD ["node", "dist/index.js"]