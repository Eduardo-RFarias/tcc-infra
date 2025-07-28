#!/bin/bash

# Load environment variables
set -a
source .env
set +a

echo "🚀 Deploying TCC Application..."

# Pull latest images
echo "📥 Pulling latest images from Docker Hub..."
docker-compose pull

# Start services
echo "📦 Starting all services..."
docker-compose --env-file .env up -d

echo "✅ Deployment complete!"
echo ""
echo "Your app is running at:"
echo "   http://$DOMAIN (HTTP)"
echo ""
echo "To set up SSL, run: ./init-ssl.sh" 