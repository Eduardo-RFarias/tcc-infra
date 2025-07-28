# PowerShell script for SSL setup on Windows

# Load environment variables from .env file
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}

$DOMAIN = $env:DOMAIN
$ADMIN_EMAIL = $env:ADMIN_EMAIL

Write-Host "🔐 Setting up SSL certificates for $DOMAIN..." -ForegroundColor Green

# Create directories for certbot
New-Item -ItemType Directory -Force -Path ".\certbot\www" | Out-Null
New-Item -ItemType Directory -Force -Path ".\certbot\conf" | Out-Null

# Start nginx without SSL first (for ACME challenge)
Write-Host "📦 Starting services without SSL..." -ForegroundColor Cyan
docker-compose up -d mysql api nginx

# Wait for nginx to be ready
Write-Host "⏳ Waiting for nginx to be ready..." -ForegroundColor Yellow
Start-Sleep 10

# Get initial certificates
Write-Host "🎫 Requesting SSL certificates from Let's Encrypt..." -ForegroundColor Cyan
$certbotResult = docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email $ADMIN_EMAIL --agree-tos --no-eff-email -d $DOMAIN -d www.$DOMAIN

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ SSL certificates obtained successfully!" -ForegroundColor Green
    
    # Update nginx to use SSL configuration
    Write-Host "🔄 Updating nginx configuration for SSL..." -ForegroundColor Cyan
    
    # Replace the nginx config to enable SSL
    docker-compose exec nginx cp /opt/bitnami/nginx/conf/server_blocks/ssl.conf /opt/bitnami/nginx/conf/server_blocks/default.conf
    docker-compose exec nginx nginx -s reload
    
    Write-Host "🎉 SSL setup complete! Your site is now available at:" -ForegroundColor Green
    Write-Host "   https://$DOMAIN" -ForegroundColor White
    Write-Host "   https://www.$DOMAIN" -ForegroundColor White
    
    Write-Host "⏰ For automatic renewal, set up a scheduled task to run:" -ForegroundColor Yellow
    Write-Host "   docker-compose run --rm certbot renew && docker-compose exec nginx nginx -s reload" -ForegroundColor White
    
} else {
    Write-Host "❌ Failed to obtain SSL certificates" -ForegroundColor Red
    Write-Host "Please check your domain DNS settings and try again" -ForegroundColor Yellow
    exit 1
} 