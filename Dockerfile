ARG BUILD_FROM
FROM golang:1.25-alpine as builder
ARG BUILD_ARCH

WORKDIR /go/src/etcdkeeper

RUN apk add --no-cache git bash

RUN set -ex; \
        case "$BUILD_ARCH" in \
                armv7) GOARCH=arm; GOARM=7 ;; \
                aarch64) GOARCH=arm64 ;; \
                x86_64) GOARCH=amd64 ;; \
                amd64) GOARCH=amd64 ;; \
                *) echo >&2 "error: unsupported architecture: $BUILD_ARCH"; exit 1 ;; \
        esac; \
        git clone https://github.com/pheelee/etcdkeeper . ; \
        mkdir -p dist ; \
        cd src/etcdkeeper ; \
        CGO_ENABLED=0 GOOS=linux GOARCH=$GOARCH GOARM=$GOARM go build -o ../../etcdkeeper ; \
        cd ../../ ; \
        tar cfz dist/etcdkeeper-linux-amd64.tar.gz etcdkeeper assets

WORKDIR /go/src/etcd

RUN set -ex; \
        case "$BUILD_ARCH" in \
                armv7) GOARCH=arm; GOARM=7 ;; \
                aarch64) GOARCH=arm64 ;; \
                x86_64) GOARCH=amd64 ;; \
                amd64) GOARCH=amd64 ;; \
                *) echo >&2 "error: unsupported architecture: $BUILD_ARCH"; exit 1 ;; \
        esac; \
        wget --quiet -O- "https://github.com/etcd-io/etcd/archive/v3.4.14.tar.gz" | tar xfz - --strip=1 -C . && \
        GOOS=linux GOARCH=$GOARCH GOARM=$GOARM ./build

FROM $BUILD_FROM

EXPOSE 2379
EXPOSE 2380

ENV LANG C.UTF-8

COPY --from=builder /go/src/etcdkeeper/dist/etcdkeeper-linux-amd64.tar.gz /tmp/etcdkeeper.tar.gz
COPY --from=builder /go/src/etcd/bin/etcd /go/src/etcd/bin/etcdctl /usr/local/bin/

# Get Etcd Release
RUN apk --no-cache add tzdata
RUN set -ex; \
        mkdir -p /var/local/etcdkeeper; \
        tar xfz /tmp/etcdkeeper.tar.gz -C /var/local/etcdkeeper && rm /tmp/etcdkeeper.tar.gz; \
        chmod +x /var/local/etcdkeeper/etcdkeeper;



WORKDIR /data

COPY rootfs /
