#!/bin/bash

set -e

cd /var/www/html

echo "Waiting for MariaDB..."
until mariadb -h"$DB_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" > /dev/null 2>&1
do
    sleep 2
done
echo "MariaDB is ready!"

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Downloading WordPress core..."
    wp core download --allow-root

    echo "Creating wp-config.php..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${DB_HOST}" \
        --allow-root

    echo "Installing WordPress..."
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "Creating secondary user..."
    wp user create \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    echo "WordPress installed successfully."
fi

chown -R www-data:www-data /var/www/html

exec /usr/sbin/php-fpm8.2 -F