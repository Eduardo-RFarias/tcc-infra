#!/bin/bash

# Load environment variables
set -a
source .env
set +a

echo "🚀 Deploying TCC Application..."

# Pull latest images
echo "📥 Pulling latest images from Docker Hub..."
docker compose pull

# Start services
echo "📦 Starting all services..."
docker compose --env-file .env up -d

# Wait for nginx to be ready
echo "⏳ Waiting for nginx to be ready..."
sleep 10

# Check if SSL certificates exist and re-enable SSL configuration
if [ -d "./certbot/conf/live/$DOMAIN" ]; then
    echo "🔐 Re-enabling SSL configuration..."
    docker compose exec nginx cp /opt/bitnami/nginx/conf/server_blocks/ssl.conf.template /opt/bitnami/nginx/conf/server_blocks/ssl.conf
    docker compose exec nginx nginx -s reload
    echo "✅ SSL configuration restored!"
else
    echo "⚠️  No SSL certificates found. Run ./init-letsencrypt.sh to set up SSL."
fi

echo "✅ Deployment complete!"
echo ""
echo "Your app is running at:"
if [ -d "./certbot/conf/live/$DOMAIN" ]; then
    echo "   🔒 https://$DOMAIN (HTTPS - Secure)"
    echo "   🔒 https://www.$DOMAIN (HTTPS - Secure)"
    echo "   📊 https://$DOMAIN/api/docs (API Documentation)"
else
    echo "   http://$DOMAIN (HTTP - Setup SSL with ./init-letsencrypt.sh)"
fi 