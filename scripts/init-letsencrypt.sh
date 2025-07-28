#!/bin/bash

# Load environment variables
set -a
source .env
set +a

echo "🔐 Setting up SSL certificates for $DOMAIN using the updated nginx image..."

domains=($DOMAIN www.$DOMAIN)
rsa_key_size=4096
data_path="./certbot"
email="${ADMIN_EMAIL}"
staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits

if [ -d "$data_path" ]; then
    read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
    if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
        exit
    fi
fi

echo "### Downloading recommended TLS parameters ..."
mkdir -p "$data_path/conf"
if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
    echo "✅ TLS parameters downloaded"
fi

echo "### Creating dummy certificate for $DOMAIN ..."
path="/etc/letsencrypt/live/$DOMAIN"
mkdir -p "$data_path/conf/live/$DOMAIN"

# Create dummy certificate using certbot container
docker compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot

echo "✅ Dummy certificate created"

echo "### Starting all services with HTTP-only configuration..."
docker compose up -d

echo "⏳ Waiting for services to be ready..."
sleep 15

# Check if nginx is responding
if ! curl -f http://localhost/health >/dev/null 2>&1; then
    echo "❌ Nginx is not responding. Please check the logs:"
    echo "docker compose logs nginx"
    exit 1
fi

echo "✅ Nginx is running with HTTP-only configuration"

echo "### Deleting dummy certificate for $DOMAIN ..."
docker compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$DOMAIN && \
  rm -Rf /etc/letsencrypt/archive/$DOMAIN && \
  rm -Rf /etc/letsencrypt/renewal/$DOMAIN.conf" certbot

echo "### Requesting Let's Encrypt certificate for $DOMAIN ..."

# Join domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
    domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
"") email_arg="--register-unsafely-without-email" ;;
*) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal" certbot

if [ $? -eq 0 ]; then
    echo "✅ SSL certificates obtained successfully!"
    
    echo "🔧 Fixing certificate permissions..."
    # Fix certificate permissions for nginx (runs as user 1001)
    chmod -R 644 "$data_path/conf/live/"*"/fullchain.pem" "$data_path/conf/live/"*"/chain.pem" 2>/dev/null || true
    chmod -R 600 "$data_path/conf/live/"*"/privkey.pem" 2>/dev/null || true
    chown -R 1001:1001 "$data_path/conf/live/" "$data_path/conf/archive/" 2>/dev/null || true
    
    echo "🔄 Enabling SSL configuration..."
    # Copy the SSL template to become the active SSL configuration
    docker compose exec nginx cp /opt/bitnami/nginx/conf/server_blocks/ssl.conf.template /opt/bitnami/nginx/conf/server_blocks/ssl.conf
    
    echo "🔄 Reloading nginx to use SSL configuration..."
    docker compose exec nginx nginx -s reload
    
    echo "🎉 SSL setup complete! Your site is now available at:"
    echo "   https://$DOMAIN"
    echo "   https://www.$DOMAIN"
    echo "   http://$DOMAIN (redirects to HTTPS)"
    
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