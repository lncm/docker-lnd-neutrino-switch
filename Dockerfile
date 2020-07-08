FROM alpine:3.12

RUN apk add --no-cache curl jq

RUN mkdir /lnd/ /secrets/ /statuses/

COPY switch.sh /usr/local/bin/switch
RUN chmod +x   /usr/local/bin/switch

ENTRYPOINT ["/usr/local/bin/switch"]
