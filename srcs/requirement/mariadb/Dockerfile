FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    mariadb-server 

COPY ./conf/mariadb.conf /etc/mysql/mariadb.conf.d/mariadb.conf

COPY ./tools/script.sh /usr/local/bin/script.sh

RUN chmod +x /usr/local/bin/script.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/script.sh"]