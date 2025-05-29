#!/bin/bash

echo "📦 Creating service folders inside Code-Base..."

services=(
  API-GATEWAY
  AUTH-SERVICE
  USER-SERVICE
  CARD-SERVICE
  PAYMENT-SERVICE
  FX-SERVICE
  KYC-SERVICE
  REDIS-WORKER
  RABBITMQ-WORKER
  DUMMY-SERVICE
  CONNECTOR-SERVICE
  UI-ADMIN
  UI-BUSINESS
  UI-CONSUMER
)

mkdir -p Code-Base

for service in "${services[@]}"; do
  folder="Code-Base/$service"
  mkdir -p "$folder"
  echo "# $service" > "$folder/README.md"
done

echo -e "\n✅ All service folders created with README.md files."

echo -e "\n🚀 Next steps:"
echo "1. Run ./bootstrap.sh to scaffold the dummy services"
echo "   OR"
echo "2. Pull real services into each folder with git pull commands"

echo -e "\n📁 You can now run docker-compose as usual."

