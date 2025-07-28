#!/bin/bash

# Bash script to build and push TCC application images to Docker Hub

# Parse command line arguments
TAG="latest"
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-t|--tag <tag>]"
            exit 1
            ;;
    esac
done

# Configuration
DOCKERHUB_USERNAME="eduardorfarias"

echo "🔨 Building and pushing TCC application images to Docker Hub..."
echo "👤 Username: $DOCKERHUB_USERNAME"
echo "🏷️  Tag: $TAG"

# Store original directory
ORIGINAL_DIR=$(pwd)

# Build and push Angular web app
echo ""
echo "🌐 Building tcc-web..."
cd "../tcc-web" || { echo "❌ Error: Could not change to tcc-web directory"; exit 1; }
docker build -t "$DOCKERHUB_USERNAME/tcc-web:$TAG" .
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to build tcc-web"
    exit 1
fi
docker push "$DOCKERHUB_USERNAME/tcc-web:$TAG"
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to push tcc-web"
    exit 1
fi

# Build and push NestJS API
echo ""
echo "🚀 Building tcc-api..."
cd "../tcc-api" || { echo "❌ Error: Could not change to tcc-api directory"; exit 1; }
docker build -t "$DOCKERHUB_USERNAME/tcc-api:$TAG" .
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to build tcc-api"
    exit 1
fi
docker push "$DOCKERHUB_USERNAME/tcc-api:$TAG"
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to push tcc-api"
    exit 1
fi

# Build and push Nginx
echo ""
echo "🌐 Building tcc-nginx..."
cd "../tcc-infra" || { echo "❌ Error: Could not change to tcc-infra directory"; exit 1; }
docker build -f config/Dockerfile -t "$DOCKERHUB_USERNAME/tcc-nginx:$TAG" .
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to build tcc-nginx"
    exit 1
fi
docker push "$DOCKERHUB_USERNAME/tcc-nginx:$TAG"
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to push tcc-nginx"
    exit 1
fi

# Return to original directory
cd "$ORIGINAL_DIR"

echo ""
echo "✅ All images pushed successfully!"
echo ""
echo "🚀 To deploy on Linux server:"
echo "   ./scripts/deploy.sh"
echo ""
echo "🔐 For first-time SSL setup:"
echo "   ./scripts/init-letsencrypt.sh" 