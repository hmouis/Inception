FROM debian:bookworm

RUN apt update && apt install -y \
    nginx openssl

RUN mkdir -p /etc/nginx/ssl
RUN mkdir -p /var/run/nginx

COPY conf/nginx.conf /etc/nginx/conf.d/default.conf
COPY tools/nginx.sh /usr/local/bin/nginx.sh

RUN chmod +x /usr/local/bin/nginx.sh

EXPOSE 443

ENTRYPOINT [ "/usr/local/bin/nginx.sh" ]

CMD [ "nginx", "-g", "daemon off;" ]