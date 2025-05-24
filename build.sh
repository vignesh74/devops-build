#!/bin/bash

# Variables
IMAGE_NAME="vigourousvig/react-devops-build"
TAG="latest"

echo "Building Docker image..."
docker build -t $IMAGE_NAME:$TAG .

echo "Logging in to Docker Hub..."
docker login

echo "Pushing image to Docker Hub..."
docker push $IMAGE_NAME:$TAG

echo "Build and push complete."

