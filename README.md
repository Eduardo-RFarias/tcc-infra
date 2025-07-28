# TCC Application Deployment

This directory contains the infrastructure setup for deploying the TCC application stack in production.

## Architecture

The deployment consists of:

- **MySQL Database** (Bitnami MySQL 8.0)
- **NestJS API** (Node.js backend)
- **Angular Web App** (Frontend)
- **Nginx** (Reverse proxy and static file server)

## Prerequisites

- Docker and Docker Compose installed
- Domain name configured (claucia.com.br)

## Environment Setup

1. Copy the environment variables example:

```bash
cp .env.example .env
```

2. Edit `.env` file with secure values:

```bash
# Database Configuration
MYSQL_ROOT_PASSWORD=your_secure_root_password_here
MYSQL_PASSWORD=your_secure_user_password_here

# API Configuration
JWT_SECRET=your_super_secure_jwt_secret_minimum_256_bits
NODE_ENV=production

# Rate Limiting
THROTTLE_TTL=60
THROTTLE_LIMIT=10

# Domain Configuration
DOMAIN=claucia.com.br
```

## Deployment

### Build and Push Images to Docker Hub

```bash
# Windows
.\build-and-push.ps1

# Linux/Mac
./build-and-push.sh

# With specific version tag
.\build-and-push.ps1 v1.0.0
```

### Deploy

```bash
# Copy and configure environment
cp env.example .env
# Edit .env with your secure values

# Deploy using Docker Hub images
docker compose --env-file .env up -d
```

### Management

```bash
# View logs
docker compose logs -f

# Stop services
docker compose down

# Stop and remove volumes (WARNING: This will delete all data)
docker compose down -v

# Update to latest images
docker compose pull && docker compose up -d
```

## Service URLs

- **Frontend**: http://localhost (or http://claucia.com.br)
- **API**: http://localhost/api
- **Uploads**: http://localhost/uploads
- **Health Check**: http://localhost/health

## SSL/HTTPS Setup with Certbot

### Automatic Setup (Recommended)

1. **Configure your environment:**

```bash
cp env.example .env
# Edit .env with your domain and email
```

2. **Run the SSL setup script:**

```bash
# Linux/Mac
./init-ssl.sh

# Windows
.\init-ssl.ps1
```

This script will:

- Start your services without SSL
- Request certificates from Let's Encrypt
- Configure nginx for HTTPS
- Set up automatic renewal

### Manual Setup

If you prefer manual setup:

1. **Start services without SSL first:**

```bash
docker compose up -d mysql api nginx
```

2. **Request certificates:**

```bash
docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email your-email@example.com \
    --agree-tos \
    --no-eff-email \
    -d claucia.com.br \
    -d www.claucia.com.br
```

3. **Enable SSL configuration:**

```bash
docker compose exec nginx cp /opt/bitnami/nginx/conf/server_blocks/ssl.conf /opt/bitnami/nginx/conf/server_blocks/default.conf
docker compose exec nginx nginx -s reload
```

### Certificate Renewal

Certificates are automatically renewed. To test renewal:

```bash
./renew-certs.sh
```

## Monitoring

### Health Checks

All services include health checks:

- MySQL: Database connectivity
- API: HTTP health endpoint
- Nginx: HTTP health endpoint

### Logs

View service logs:

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f api
docker compose logs -f nginx
docker compose logs -f mysql
```

## Backup

### Database Backup

```bash
# Create backup
docker compose exec mysql mysqldump -u claucia -p claucia > backup.sql

# Restore backup
docker compose exec -T mysql mysql -u claucia -p claucia < backup.sql
```

### Uploads Backup

```bash
# Backup uploads volume
docker run --rm -v tcc-infra_uploads_data:/data -v $(pwd):/backup alpine tar czf /backup/uploads-backup.tar.gz -C /data .

# Restore uploads
docker run --rm -v tcc-infra_uploads_data:/data -v $(pwd):/backup alpine tar xzf /backup/uploads-backup.tar.gz -C /data
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: Change the port mapping in docker compose.yml
2. **Permission issues**: Check file permissions and Docker user
3. **Database connection**: Verify environment variables and network connectivity

### Debug Commands

```bash
# Check running containers
docker compose ps

# Inspect service
docker compose exec api sh
docker compose exec nginx sh

# Check networks
docker network ls
docker network inspect tcc-infra_tcc-network
```

## Security Considerations

- Change all default passwords
- Use strong JWT secrets
- Configure firewall rules
- Regular security updates
- Monitor logs for suspicious activity
- Use HTTPS in production

## Performance Tuning

- Adjust nginx worker processes
- Configure database connection pooling
- Enable gzip compression (already configured)
- Set appropriate cache headers (already configured)
- Monitor resource usage and scale as needed
