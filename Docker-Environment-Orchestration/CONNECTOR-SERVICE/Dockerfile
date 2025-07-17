# NestJS Connector Service
FROM node:20-alpine

WORKDIR /app
COPY . .

# Allow fallback for empty bind mounts during development
RUN if [ ! -f package.json ]; then \
        npm init -y --silent && \
        npm install --silent && \
        echo 'console.log("Connector Service ready.");' > index.js ; \
    else \
        npm install -g @nestjs/cli --silent && \
        npm install --silent && \
        npm run build ; \
    fi

EXPOSE 3000
CMD [ "npm", "run", "start:dev" ]
