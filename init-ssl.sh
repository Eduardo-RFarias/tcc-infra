#!/bin/bash

# Load environment variables
set -a
source .env
set +a

echo "🔐 Setting up SSL certificates for $DOMAIN..."

# Pull latest images first
echo "📥 Pulling latest images from Docker Hub..."
docker compose pull

# Start nginx without SSL first (for ACME challenge)
echo "📦 Starting services without SSL..."
docker compose up -d mysql api nginx

# Wait for nginx to be ready
echo "⏳ Waiting for nginx to be ready..."
sleep 15

# Check if nginx is responding
if ! curl -f http://localhost/health >/dev/null 2>&1; then
    echo "❌ Nginx is not responding. Please check the logs:"
    echo "docker compose logs nginx"
    exit 1
fi

# Get initial certificates
echo "🎫 Requesting SSL certificates from Let's Encrypt..."
docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $ADMIN_EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    -d www.$DOMAIN

if [ $? -eq 0 ]; then
    echo "✅ SSL certificates obtained successfully!"
    
    # Update nginx to use SSL configuration
    echo "🔄 Updating nginx configuration for SSL..."
    
    # Replace the nginx config to enable SSL
    docker compose exec nginx cp /opt/bitnami/nginx/conf/server_blocks/ssl.conf /opt/bitnami/nginx/conf/server_blocks/default.conf
    docker compose exec nginx nginx -s reload
    
    echo "🎉 SSL setup complete! Your site is now available at:"
    echo "   https://$DOMAIN"
    echo "   https://www.$DOMAIN"
    
    echo "📅 To set up automatic renewal, add this to your crontab:"
    echo "0 12 * * * cd $(pwd) && docker compose run --rm certbot renew && docker compose exec nginx nginx -s reload"
    
else
    echo "❌ Failed to obtain SSL certificates"
    echo "Please check:"
    echo "1. Domain DNS points to this server"
    echo "2. Port 80 is open and accessible"
    echo "3. Domain is correctly set in .env file"
    exit 1
fi 