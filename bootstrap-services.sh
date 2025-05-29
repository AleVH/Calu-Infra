#!/bin/bash

set -e

BASE_DIR="./Code-Base"
FORCE=false

# Parse arguments
for arg in "$@"; do
    if [ "$arg" == "--force" ]; then
        FORCE=true
    fi
done

# Utility to check if directory has meaningful content
has_meaningful_content () {
    dir="$1"
    count=$(find "$dir" -type f ! -name '.DS_Store' ! -name '.gitkeep' ! -name 'README.md' | wc -l)
    [ "$count" -gt 0 ]
}

# NestJS generator with service name as project name
generate_nestjs () {
    service_path="$1"
    service_name="$2"
    echo "Generating NestJS scaffold in $service_path"
    npx --yes @nestjs/cli new "$service_path" --skip-git --package-manager npm --strict --directory "$service_path"
}

# FastAPI generator with realistic production-ready scaffold
generate_fastapi () {
    service_path="$1"
    echo "Generating FastAPI scaffold in $service_path"
    mkdir -p "$service_path/app"
    cat <<EOF > "$service_path/app/main.py"
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI"}
EOF

    cat <<EOF > "$service_path/requirements.txt"
fastapi
uvicorn[standard]
pydantic
python-dotenv
EOF

    cat <<EOF > "$service_path/app/__init__.py"
# FastAPI app module
EOF

    cat <<EOF > "$service_path/.env"
APP_ENV=development
EOF

    cat <<EOF > "$service_path/start.sh"
#!/bin/bash
uvicorn app.main:app --host 0.0.0.0 --port 4000 --reload
EOF
    chmod +x "$service_path/start.sh"
}

# React Native Web (Expo) generator using service name as project name
generate_react_native () {
    service_path="$1"
    service_name="$2"
    echo "Generating React Native Web scaffold in $service_path"

    # Ensure the directory is completely clean
    rm -rf "$service_path"/* "$service_path"/.* 2>/dev/null || true
    mkdir -p "$service_path"

    npx --yes create-expo-app "$service_path" --template blank
}

# Spring Boot full scaffold using Spring Initializr
generate_spring_boot () {
    service_path="$1"
    service_name="$2"
    echo "Generating Spring Boot scaffold in $service_path"

    mkdir -p "$service_path"
    curl https://start.spring.io/starter.zip \
        -d dependencies=web \
        -d type=maven-project \
        -d language=java \
        -d name="$service_name" \
        -d packageName=com.example."$(echo "$service_name" | tr '[:upper:]' '[:lower:]' | tr '-' '_')" \
        -o /tmp/"$service_name".zip

    unzip -q /tmp/"$service_name".zip -d "$service_path"
    rm /tmp/"$service_name".zip
}

# Dummy Node.js + Express service
generate_dummy_service () {
    service_path="$1"
    echo "Generating dummy Node.js + Express service in $service_path"
    mkdir -p "$service_path"
    
    cat <<EOF > "$service_path/package.json"
{
  "name": "dummy-service",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.4"
  }
}
EOF

    cat <<EOF > "$service_path/index.js"
const express = require('express');
const app = express();
const port = process.env.PORT || 3002;

app.get('/auth/status', (req, res) => {
  res.json({ status: 'auth-service dummy ready' });
});

app.listen(port, () => {
  console.log(\`Dummy service listening on port \${port}\`);
});
EOF
}

for dir in "$BASE_DIR"/*/; do
    service_name=$(basename "$dir")
    service_name_lc=$(echo "$service_name" | tr '[:upper:]' '[:lower:]')

    if has_meaningful_content "$dir"; then
        if [ "$FORCE" = true ]; then
            echo "$service_name has content but --force is used. Cleaning..."
            rm -rf "$dir"/*
        else
            echo "$service_name already has meaningful content. Skipping..."
            continue
        fi
    fi

    case "$service_name_lc" in
        api-gateway|auth-service|user-service|card-service|connector-service)
            generate_nestjs "$dir" "$service_name"
            ;;
        payment-service|fx-service)
            generate_fastapi "$dir"
            ;;
        kyc-service)
            generate_spring_boot "$dir" "$service_name"
            ;;
        ui-admin|ui-consumer|ui-business)
            generate_react_native "$dir" "$service_name"
            ;;
        dummy-service)
            generate_dummy_service "$dir"
            ;;
        redis-worker|rabbitmq-worker)
            echo "$service_name is a worker. No scaffold needed."
            ;;
        *)
            echo "Unknown service: $service_name. Skipping..."
            ;;
    esac

done

echo "✅ Bootstrap complete."
