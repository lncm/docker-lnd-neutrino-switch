FROM alpine:3.10

RUN apk add --no-cache curl jq bash

RUN mkdir /lnd/
RUN mkdir /secrets/
RUN mkdir /statuses/

COPY switch.sh /bin/switch
RUN chmod +x /bin/switch

ENTRYPOINT ["switch"]
