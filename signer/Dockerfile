FROM alpine:3.19

#RUN echo "/zones IN_MOVED_TO,IN_CLOSE_WRITE /bin/echo $@/$# $%" > signer

RUN apk add --no-cache bash bind-dnssec-tools inotify-tools

COPY entrypoint.sh /
CMD ["/entrypoint.sh"]
