#!/bin/bash

if [ ! -f /etc/nginx/ssl/inception.crt]; then

echo "Generating SSL certificate..."

openssl req -x509 -nodes -days 365 \
    -out /etc/nginx/ssl/inception.crt \
    -keyout /etc/nginx/ssl/inception.key \
    -subj "/C=MA/ST=Morocco/L=BenGuerir/O=1337/OU=42/CN=$DOMAIN_NAME/UID=$LOGIN"

echo "SSL certificate generated."
fi

exec "$@"