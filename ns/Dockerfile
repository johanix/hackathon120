FROM alpine:3.19

RUN apk add --no-cache bind bind-tools

WORKDIR /var/tmp/

EXPOSE 53/tcp 53/udp

COPY ./entrypoint.sh /
CMD ["/entrypoint.sh"]
