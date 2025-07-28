# Nginx server with Angular app from Docker Hub
FROM bitnami/nginx:latest

# Copy nginx configurations
COPY nginx.conf /opt/bitnami/nginx/conf/server_blocks/default.conf
COPY nginx-ssl.conf /opt/bitnami/nginx/conf/server_blocks/ssl.conf

# Copy Angular build files from published image
COPY --from=eduardorfarias/tcc-web:latest /app/dist/claucia-web /app

# Create uploads directory for serving uploaded files
USER root
RUN mkdir -p /app/uploads
RUN chown -R 1001:1001 /app
USER 1001

# Expose port 8080 (default for Bitnami nginx)
EXPOSE 8080 