FROM alpine:3.8

COPY assets/ /opt/resource

RUN apk add --no-cache bash jq curl