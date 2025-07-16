#!/bin/sh

# Substitute the PORT variable in the nginx config
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "Starting NGINX with the following config:"
cat /etc/nginx/conf.d/default.conf

# Start NGINX in the foreground
nginx -g 'daemon off;'

