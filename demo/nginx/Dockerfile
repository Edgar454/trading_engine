FROM nginx:alpine

# Copy NiFi certs from Vault Agent mount or pre-generated files
RUN mkdir -p /certs/nginx && chmod 755 /certs/nginx

# Copy custom NGINX config
COPY ./nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
EXPOSE 90


CMD ["nginx", "-g", "daemon off;"]