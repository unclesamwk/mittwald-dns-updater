FROM alpine:3.20
RUN apk add --no-cache curl bind-tools jq
COPY dnsupdater.sh /usr/local/bin/dnsupdater
ENTRYPOINT ["sh", "/usr/local/bin/dnsupdater"]

