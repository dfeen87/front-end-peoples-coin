FROM nginx:alpine

# Remove default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy build folder contents into nginx html folder
COPY build/ /usr/share/nginx/html/

# Replace default nginx.conf to listen on port 8080
RUN sed -i 's/listen       80;/listen       8080;/' /etc/nginx/conf.d/default.conf

# Expose port 8080 for Cloud Run
EXPOSE 8080

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]

