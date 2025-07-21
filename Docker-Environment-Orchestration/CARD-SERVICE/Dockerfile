# NestJS Card Service
FROM node:20-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy only dependency metadata files for install step
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy the entrypoint script
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

# Do not copy source code — Mutagen will handle that

# Let Mutagen sync source files after container starts
CMD ["./entrypoint.sh"]