FROM debian:12

RUN apt-get update && apt-get upgrade\
    && apt-get install -y mariadb-server 

RUN mkdir /script

COPY ./tools/mariadb.sh /script/mariadb.sh

RUN chmod +x /script/mariadb.sh

ENTRYPOINT [ "/script/mariadb.sh" ]