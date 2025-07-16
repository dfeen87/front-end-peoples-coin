FROM nginx:alpine

# Remove default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy built frontend files
COPY dist/ /usr/share/nginx/html/

# Copy nginx config template
COPY nginx.conf.template /etc/nginx/conf.d/default.conf.template

# Copy startup script
COPY run.sh /run.sh

# Make script executable
RUN chmod +x /run.sh

# Expose 8080
EXPOSE 8080

# Run nginx via run.sh
CMD ["/run.sh"]

