#!/bin/bash

echo "📦 Creating service folders inside Code-Base..."

services=(
  api-gateway
  auth-service
  user-service
  card-service
  PAYMENT-SERVICE
  FX-SERVICE
  KYC-SERVICE
  redis-worker
  RABBITMQ-WORKER
  dummy-service
  connector-service
  ui-admin
  ui-business
  ui-consumer
)

# Services that require a .env file for Docker compatibility
env_services=(
  api-gateway
  connector-service
  card-service
  auth-service
)

mkdir -p Code-Base

for service in "${services[@]}"; do
  folder="Code-Base/$service"

  # Create the folder if it's missing
  if [ ! -d "$folder" ]; then
    mkdir -p "$folder"
    echo "📁 Created folder: $folder"
    echo "# $service" > "$folder/README.md"
  else
    echo "📂 Folder exists: $folder"
  fi
done

echo -e "\n🧪 Ensuring .env files exist where needed..."

for service in "${env_services[@]}"; do
  env_path="Code-Base/$service/.env"
  if [ ! -f "$env_path" ]; then
    echo "APP_ENV=development" > "$env_path"
    echo "🧾 Created .env file for $service"
  else
    echo "✅ .env already exists for $service"
  fi
done

echo -e "\n✅ Environment is ready. You can now run docker-compose safely."
