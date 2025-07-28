# Production stage with Bitnami nginx
FROM bitnami/nginx:latest

# Copy nginx configurations
# Use SSL configuration as the primary config
COPY config/nginx/nginx-ssl.conf /opt/bitnami/nginx/conf/server_blocks/ssl.conf

# Copy Angular build files from published image
COPY --from=eduardorfarias/tcc-web:latest /app/dist/claucia-web /app

# Create uploads directory for serving uploaded files
USER root
RUN mkdir -p /app/uploads
RUN chown -R 1001:1001 /app
USER 1001

# Expose ports 8080 (HTTP) and 8443 (HTTPS)
EXPOSE 8080 8443 