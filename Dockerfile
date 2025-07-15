# Use nginx to serve the static files
FROM nginx:alpine

# Clean nginx default html
RUN rm -rf /usr/share/nginx/html/*

# Copy the build folder
COPY build/ /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Run nginx
CMD ["nginx", "-g", "daemon off;"]

