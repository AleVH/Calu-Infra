# Node.js + BullMQ Redis Worker
FROM node:18-alpine

# Create the working directory
WORKDIR /app

COPY . .

# If empty, bootstrap with dummy worker
RUN if [ ! -f package.json ]; then \
        npm init -y && \
        npm install bullmq ioredis && \
        echo 'console.log("Redis Worker ready.");' > index.js ; \
    else \
        npm install ; \
    fi

# Command to run the worker (this can be overridden)
CMD [ "node", "index.js" ]