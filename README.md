# TCC Application Deployment

This repository contains the complete infrastructure setup for deploying the TCC application stack in production with SSL certificates and secure configuration.

## 🏗️ Architecture

The deployment consists of:
- **MySQL Database** (Bitnami MySQL 8.0) - Data persistence
- **NestJS API** (Node.js backend) - RESTful API with Swagger documentation  
- **Angular Web App** (Frontend) - Single Page Application
- **Nginx** (Reverse proxy) - Load balancer, SSL termination, static file serving
- **Certbot** - Automatic SSL certificate management via Let's Encrypt

## 📋 Prerequisites

- Docker and Docker Compose installed
- Domain name configured and pointing to your server (e.g., claucia.com.br)
- Server with ports 80 and 443 accessible from the internet

## 🚀 Quick Start Deployment

### 1. Clone and Configure

```bash
git clone <your-repo-url>
cd tcc-infra
```

The `.env` file should already be configured with your credentials:

```bash
# Docker Hub Configuration
DOCKERHUB_USERNAME=eduardorfarias
TAG=latest

# Database Configuration
MYSQL_ROOT_PASSWORD=<your-secure-password>
MYSQL_PASSWORD=<your-secure-password>

# API Configuration  
JWT_SECRET=<your-super-secure-jwt-secret>
NODE_ENV=production

# Domain Configuration
DOMAIN=claucia.com.br
ADMIN_EMAIL=<your-email@domain.com>
```

### 2. Initial Deployment with SSL

**For first-time deployment with SSL certificates:**

```bash
# This script handles everything: dummy certificates, Let's Encrypt, and SSL configuration
./init-letsencrypt.sh
```

The script will:
- ✅ Download TLS security parameters
- ✅ Create dummy SSL certificates to allow nginx to start
- ✅ Start all services (MySQL, API, Nginx) 
- ✅ Request real Let's Encrypt certificates
- ✅ Enable SSL configuration and reload nginx
- ✅ Set up automatic certificate renewal

### 3. Regular Deployments

**For subsequent deployments (after SSL is already set up):**

```bash
# Simple deployment script for updates
./deploy.sh
```

## 🔧 Development Workflow

### Windows Development (Build & Push Images)

```powershell
# Build and push all images to Docker Hub
.\build-and-push.ps1

# With specific version tag
.\build-and-push.ps1 v1.0.0
```

### Linux Deployment

```bash
# Pull latest images and deploy
./deploy.sh

# Or manually:
docker compose pull
docker compose up -d
```

## 🌐 Service URLs

After successful deployment, your application will be available at:

- **🔒 HTTPS Frontend**: https://claucia.com.br
- **🔒 HTTPS API**: https://claucia.com.br/api
- **🔒 API Documentation**: https://claucia.com.br/api/docs
- **📁 File Uploads**: https://claucia.com.br/uploads
- **💚 Health Check**: https://claucia.com.br/health

*HTTP requests automatically redirect to HTTPS*

## 🗄️ Database Access

### For DBeaver/External Database Tools

The MySQL database is exposed on port 3306 for debugging:

**Connection Settings:**
- **Host:** `claucia.com.br`
- **Port:** `3306`
- **Database:** `claucia`
- **Username:** `claucia`
- **Password:** `<from .env file>`

**Root Access:**
- **Username:** `root`
- **Password:** `<MYSQL_ROOT_PASSWORD from .env>`

**🔒 Security:** Port 3306 is protected by IP-based firewall rules (whitelist only).

### Firewall Security

The database port 3306 is protected by IP-based firewall rules:
- Only whitelisted IPs can access MySQL
- SSH access (port 22) is also IP-restricted
- HTTP/HTTPS (ports 80/443) are open for public web access

To modify database access, update your firewall whitelist rather than changing the Docker configuration.

## 🔐 SSL Certificate Management

### Automatic Renewal

Certificates automatically renew. To set up cron job for renewal:

```bash
# Add to crontab (crontab -e):
0 12 * * * cd /opt/tcc-infra && docker compose run --rm certbot renew && docker compose exec nginx nginx -s reload
```

### Manual Certificate Renewal

```bash
docker compose run --rm certbot renew
docker compose exec nginx nginx -s reload
```

## 📊 Monitoring & Management

### Check Service Status

```bash
# View all containers
docker compose ps

# Check logs
docker compose logs -f          # All services
docker compose logs -f nginx    # Specific service
docker compose logs -f api
docker compose logs -f mysql
```

### Health Checks

- **API Health**: `curl https://claucia.com.br/health`
- **Database**: All services include health checks
- **SSL Certificate**: Browser will show green lock icon

## 🛠️ Troubleshooting

### Common Issues & Solutions

1. **SSL Certificate Errors**
   ```bash
   # Check certificate status
   docker compose logs certbot
   
   # Restart SSL setup
   ./init-letsencrypt.sh
   ```

2. **Nginx Not Starting**
   ```bash
   # Check nginx logs
   docker compose logs nginx
   
   # Verify configuration
   docker compose exec nginx nginx -t
   ```

3. **API Documentation (Swagger) Not Loading**
   - Fixed in current configuration with `location ^~ /api/` priority
   - Swagger assets now properly proxy to API instead of serving as static files

4. **Angular App Shows Nginx Default Page**
   - Fixed in current configuration with `root /app/browser;`
   - Nginx now serves Angular app from correct directory

### Debug Commands

```bash
# Inspect running containers
docker compose exec nginx sh
docker compose exec api sh
docker compose exec mysql mysql -u claucia -p

# Check network connectivity
docker network inspect tcc-infra_tcc-network

# Test SSL certificates
openssl s_client -connect claucia.com.br:443 -servername claucia.com.br
```

## 💾 Backup & Recovery

### Database Backup

```bash
# Create backup
docker compose exec mysql mysqldump -u claucia -p claucia > backup-$(date +%Y%m%d).sql

# Restore backup
docker compose exec -T mysql mysql -u claucia -p claucia < backup-20240101.sql
```

### File Uploads Backup

```bash
# Backup uploads volume
docker run --rm -v tcc-infra_uploads_data:/data -v $(pwd):/backup alpine tar czf /backup/uploads-backup-$(date +%Y%m%d).tar.gz -C /data .

# Restore uploads
docker run --rm -v tcc-infra_uploads_data:/data -v $(pwd):/backup alpine tar xzf /backup/uploads-backup-20240101.tar.gz -C /data
```

## 🔒 Security Features

- ✅ **HTTPS Only** - All traffic encrypted with Let's Encrypt certificates
- ✅ **Security Headers** - HSTS, CSP, X-Frame-Options, etc.
- ✅ **Database Security** - Internal network isolation + strong passwords + IP-based firewall
- ✅ **SSH Protection** - IP whitelist access only
- ✅ **API Protection** - CORS, rate limiting, input validation
- ✅ **File Upload Security** - Secure file handling and serving

## 📁 Repository Structure

```
tcc-infra/
├── build-and-push.ps1      # Windows: Build & push Docker images
├── deploy.sh               # Linux: Regular deployment script  
├── init-letsencrypt.sh     # SSL setup script (first time only)
├── docker-compose.yml      # Main orchestration file
├── Dockerfile              # Nginx image definition
├── nginx.conf              # HTTP configuration (port 80)
├── nginx-ssl.conf          # HTTPS configuration (port 443)
├── .env                    # Environment variables
├── .env.example            # Template for environment variables
├── README.md               # This documentation
└── certbot/                # SSL certificates (auto-generated)
    ├── conf/               # Certificate files
    └── www/                # ACME challenge files
```

## 🚦 Deployment Workflow

1. **Development (Windows)**: Code → `build-and-push.ps1` → Docker Hub
2. **Production (Linux)**: `./init-letsencrypt.sh` (first time) or `./deploy.sh` (updates)
3. **Monitoring**: Check logs and health endpoints
4. **Database Access**: Use DBeaver with provided credentials (temporarily)

## 📝 Version History

- **v2.0** - SSL automation, nginx fixes, database access, comprehensive documentation
- **v1.0** - Initial Docker deployment setup

---

**🎯 Result**: Production-ready TCC application with automatic SSL, secure database access, and comprehensive monitoring at https://claucia.com.br**
