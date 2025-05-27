#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

echo "🚧 Starting Docker image build: vigourousvig/dev:latest"

docker build -t vigourousvig/dev:latest .

echo "✅ Docker image build completed successfully!"

