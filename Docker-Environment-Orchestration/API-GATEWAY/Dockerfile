# NestJS API Gateway
FROM node:20-alpine

WORKDIR /app
COPY . .

# If code is empty, fallback to dummy index.js
RUN if [ ! -f package.json ]; then \
        npm init -y --silent && \
        npm install --silent && \
        echo 'console.log("API-Gateway Service ready.");' > index.js ; \
    else \
        npm install -g @nestjs/cli --silent && \
        npm install --silent && \
        npm run build ; \
    fi

EXPOSE 4000
CMD [ "npm", "run", "start:dev" ]