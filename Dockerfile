FROM alpine:3.12

RUN apk add --no-cache curl jq docker

RUN mkdir /lnd/ /secrets/ /statuses/

COPY switch.sh /usr/local/bin/switch
RUN chmod +x   /usr/local/bin/switch

STOPSIGNAL SIGINT

ENTRYPOINT ["/usr/local/bin/switch"]
