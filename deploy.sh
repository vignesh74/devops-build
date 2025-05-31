#!/bin/bash
set -e

SERVER_IP="13.233.247.23"
SSH_USER="ubuntu"
SSH_KEY_PATH="$SSH_KEY"
DOCKER_COMPOSE_PATH="/home/ubuntu/docker-compose.yml"

echo "🚀 Deploying via Docker Compose to $SERVER_IP..."

# Copy docker-compose.yml to the server
scp -i "$SSH_KEY_PATH" docker-compose.yml $SSH_USER@$SERVER_IP:$DOCKER_COMPOSE_PATH

# Connect to server and deploy
ssh -o ConnectTimeout=10 -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" bash -s << 'EOF'
  cd /home/ubuntu

  echo "✅ Pulling the latest Docker image..."
  docker pull vigourousvig/dev:latest

  echo "🧹 Stopping existing containers (if any)..."
  docker compose down || true

  echo "🚀 Starting containers using docker-compose......"
  docker compose up -d

  echo "✅ Docker Compose deployment complete!"
EOF

