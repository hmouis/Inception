#!/bin/bash

set -e

if [ ! -d "/var/lib/mysql/mysql" ]; then

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    service mariadb start

    until mariadb-admin ping --silent; do
        sleep 1
    done

mariadb -u root << EOF
CREATE DATABASE IF NOT EXISTS MYdatabase;
CREATE USER IF NOT EXISTS 'HODAIFA'@'%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON MYdatabase.* TO 'HODAIFA'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '12345';
FLUSH PRIVILEGES;
EOF

mysqladmin -u root -p"" --socket=/run/mysqld/mysqld.sock shutdown
fi

exec mysqld_safe