FROM eclipse-temurin:17-jre-alpine-3.22

ENV ZOO_CONF_DIR=/conf \
    ZOO_DATA_DIR=/data \
    ZOO_DATA_LOG_DIR=/datalog \
    ZOO_LOG_DIR=/logs \
    ZOO_TICK_TIME=2000 \
    ZOO_INIT_LIMIT=5 \
    ZOO_SYNC_LIMIT=2 \
    ZOO_AUTOPURGE_PURGEINTERVAL=0 \
    ZOO_AUTOPURGE_SNAPRETAINCOUNT=3 \
    ZOO_MAX_CLIENT_CNXNS=60 \
    ZOO_STANDALONE_ENABLED=true \
    ZOO_ADMINSERVER_ENABLED=true

# Add a user with an explicit UID/GID and create necessary directories
RUN set -eux && \
    addgroup -S -g 1000 zookeeper && \
    adduser -S -G zookeeper -u 1000 zookeeper && \
    mkdir -p "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_LOG_DIR" && \
    chown zookeeper:zookeeper "$ZOO_DATA_LOG_DIR" "$ZOO_DATA_DIR" "$ZOO_CONF_DIR" "$ZOO_LOG_DIR"

# Upgrade existing packages and install dependencies
# run multiple apk in one RUN, use cache
# we want the latest package, so no pinning
# hadolint ignore=DL3018,DL3019
RUN apk --update upgrade && \
    apk --update add \
        bash \
        ca-certificates \
        netcat-openbsd \
        gpg \
        tar \
        wget &&\
    rm -rf /var/cache/apk

ARG PACKET_HASH=3F7A1D16FA4217B1DC75E1C9FFE35B7F15DFA1BA

ARG SHORT_DISTRO_NAME=zookeeper-3.8.5
ARG DISTRO_NAME=apache-zookeeper-3.8.5-bin

# Download Apache Zookeeper, verify its PGP signature, untar and clean up
# use inline ddist to reduce complexity
# hadolint ignore=SC2155
RUN set -eux; \
    ddist() { \
        local f="$1"; shift; \
        local distFile="$1"; shift; \
        local success=; \
        local distUrl=; \
        for distUrl in \
            'https://www.apache.org/dyn/closer.cgi?action=download&filename=' \
            https://www-us.apache.org/dist/ \
            https://www.apache.org/dist/ \
            https://archive.apache.org/dist/ \
        ; do \
            if wget -q -O "$f" "$distUrl$distFile" && [ -s "$f" ]; then \
                success=1; \
                break; \
            fi; \
        done; \
        [ -n "$success" ]; \
    }; \
    ddist "$DISTRO_NAME.tar.gz" "zookeeper/$SHORT_DISTRO_NAME/$DISTRO_NAME.tar.gz"; \
    ddist "$DISTRO_NAME.tar.gz.asc" "zookeeper/$SHORT_DISTRO_NAME/$DISTRO_NAME.tar.gz.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --keyserver hkps://keyserver.pgp.com --recv-key "$PACKET_HASH" || \
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$PACKET_HASH" || \
    gpg --keyserver hkps://pgp.mit.edu --recv-keys "$PACKET_HASH"; \
    gpg --batch --verify "$DISTRO_NAME.tar.gz.asc" "$DISTRO_NAME.tar.gz"; \
    tar -zxf "$DISTRO_NAME.tar.gz"; \
    mv "$DISTRO_NAME/conf/"* "$ZOO_CONF_DIR"; \
    rm -rf "$GNUPGHOME" "$DISTRO_NAME.tar.gz" "$DISTRO_NAME.tar.gz.asc"; \
    chown -R zookeeper:zookeeper "/$DISTRO_NAME"

COPY docker-entrypoint.sh /

USER zookeeper
WORKDIR /$DISTRO_NAME

VOLUME ["$ZOO_DATA_DIR", "$ZOO_DATA_LOG_DIR", "$ZOO_LOG_DIR"]

EXPOSE 2181 2888 3888 8080

ENV PATH=$PATH:/$DISTRO_NAME/bin \
    ZOOCFGDIR=$ZOO_CONF_DIR

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["zkServer.sh", "start-foreground"]
