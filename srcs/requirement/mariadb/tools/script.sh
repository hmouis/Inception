#!/bin/bash
set -e

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

# Start the real server process in the background - this stays running
mysqld_safe --datadir=/var/lib/mysql &

until mariadb-admin ping --silent 2>/dev/null; do
    sleep 1
done
echo "MariaDB started"

if [ ! -f "/var/lib/mysql/.db_init_done" ]; then
    mariadb -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
    touch /var/lib/mysql/.db_init_done
    echo "DB init done"
fi

# Keep the already-running mariadbd process as the container's foreground process
wait