#!/bin/bash
echo "Deploying to EC2..."

ssh -i /Users/vignesh/Desktop/160525.pem ubuntu@13.127.193.148 << EOF
  echo "Pulling latest multi-arch image from Docker Hub..."
  docker pull vigourousvig/react-devops-build:latest

  echo "Stopping old container if exists..."
  docker stop react-devops-build-container || true
  docker rm react-devops-build-container || true

  echo "Running new container..."
  docker run -d --name react-devops-build-container -p 80:80 vigourousvig/react-devops-build:latest
EOF

echo "Deployment completed."

