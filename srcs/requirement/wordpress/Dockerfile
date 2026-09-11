FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php \
    php-fpm \
    php8.2-fpm \
    php-mysql \
    php-curl \
    php-gd \
    php-xml \
    php-zip \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY tools/wordpress.sh /usr/local/bin/wordpress.sh
RUN sed -i 's#^listen = /run/php/php8.2-fpm.sock#listen = 0.0.0.0:9000#' /etc/php/8.2/fpm/pool.d/www.conf
RUN chmod +x /usr/local/bin/wordpress.sh

ENTRYPOINT ["/usr/local/bin/wordpress.sh"]