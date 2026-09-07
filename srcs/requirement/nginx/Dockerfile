FROM debian:bullseye

RUN apt update && apt install -y \
    nginx openssl

RUN mkdir -p /etc/nignx/ssl
RUN mkdir -p /var/run/nginx

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY tools/nginx.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/nginx.sh

EXPOSE 443

ENTRYPOINT [ "/usr/local/bin/nginx.sh" ]

CMD [ "nginx", "-g", "daemon off;" ]