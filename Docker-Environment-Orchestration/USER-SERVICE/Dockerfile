# NestJS User Service
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy existing code from Code-Base
COPY . .

# If no package.json exists, scaffold a minimal NestJS project
RUN if [ ! -f package.json ]; then \
        npm install -g @nestjs/cli && \
        nest new tmp-app --package-manager npm --skip-git --skip-install && \
        mv tmp-app/* tmp-app/.* . 2>/dev/null || true && \
        rm -rf tmp-app ; \
    fi

# Install dependencies
RUN npm install

# If no main.ts exists, create a basic bootstrap file
RUN if [ ! -f src/main.ts ]; then \
        mkdir -p src && \
        echo "import { NestFactory } from '@nestjs/core';\n\
import { Module } from '@nestjs/common';\n\
import { Controller, Get } from '@nestjs/common';\n\
\n\
@Controller()\n\
class AppController {\n\
  @Get()\n\
  getRoot(): object {\n\
    return { message: 'User service is running' };\n\
  }\n\
}\n\
\n\
@Module({ controllers: [AppController] })\n\
class AppModule {}\n\
\n\
async function bootstrap() {\n\
  const app = await NestFactory.create(AppModule);\n\
  await app.listen(4001);\n\
}\n\
bootstrap();" > src/main.ts ; \
    fi

EXPOSE 4000
CMD [ "npm", "run", "start:dev" ]