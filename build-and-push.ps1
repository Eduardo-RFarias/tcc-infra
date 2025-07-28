# PowerShell script to build and push TCC application images to Docker Hub

param(
    [string]$Tag = "latest"
)

# Configuration
$DOCKERHUB_USERNAME = "eduardorfarias"

Write-Host "Building and pushing TCC application images to Docker Hub..." -ForegroundColor Green
Write-Host "Username: $DOCKERHUB_USERNAME" -ForegroundColor Yellow
Write-Host "Tag: $Tag" -ForegroundColor Yellow

# Build and push Angular web app
Write-Host "`nBuilding tcc-web..." -ForegroundColor Cyan
Set-Location "../tcc-web"
docker build -t "$DOCKERHUB_USERNAME/tcc-web:$Tag" .
docker push "$DOCKERHUB_USERNAME/tcc-web:$Tag"

# Build and push NestJS API
Write-Host "`nBuilding tcc-api..." -ForegroundColor Cyan
Set-Location "../tcc-api"
docker build -t "$DOCKERHUB_USERNAME/tcc-api:$Tag" .
docker push "$DOCKERHUB_USERNAME/tcc-api:$Tag"

# Build and push Nginx
Write-Host "`nBuilding tcc-nginx..." -ForegroundColor Cyan
Set-Location "../tcc-infra"
docker build -t "$DOCKERHUB_USERNAME/tcc-nginx:$Tag" .
docker push "$DOCKERHUB_USERNAME/tcc-nginx:$Tag"

Write-Host "`nAll images pushed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "To deploy:" -ForegroundColor Yellow
Write-Host "docker compose --env-file .env up -d" -ForegroundColor White 