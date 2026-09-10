#!/bin/bash

cd /var/www/html

if [ ! -f /var/www/html/index.php ]; then
    echo "Downloading WordPress..."

    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz --strip-components=1
    rm latest.tar.gz

    echo "WordPress downloaded successfully."
fi

echo "Waiting for MariaDB..."

until mariadb -h"$DB_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" > /dev/null 2>&1
do
    sleep 2
done

echo "MariaDB is ready!"

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Creating wp-config.php..."

    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

    sed -i "s/database_name_here/$MYSQL_DATABASE/" /var/www/html/wp-config.php
    sed -i "s/username_here/$MYSQL_USER/" /var/www/html/wp-config.php
    sed -i "s/password_here/$MYSQL_PASSWORD/" /var/www/html/wp-config.php
    sed -i "s/localhost/$DB_HOST/" /var/www/html/wp-config.php

    echo "wp-config.php created."
fi

chown -R www-data:www-data /var/www/html

exec php8.2-fpm -F