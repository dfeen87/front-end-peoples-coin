FROM nginx:alpine

# Remove default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy the built frontend files into nginx html folder
COPY dist/ /usr/share/nginx/html/

# Copy your custom nginx config to override default settings (make sure the path matches your project)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 8080 as per your nginx config and Firebase environment
EXPOSE 8080

# Run nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]

