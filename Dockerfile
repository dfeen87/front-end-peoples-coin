FROM nginx:alpine

# Remove default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy the *correct* built files into nginx html folder
COPY dist/ /usr/share/nginx/html/

# (Optional) If you customized nginx config:
# COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]

