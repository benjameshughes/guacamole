# Define build-time variables
ARG ALPINE_VER=3.15
ARG GUAC_VER=1.4.1
ARG GUAC_LDAP_VER=1.4.1
ARG POSTGRES_JDBC_VER=42.2.24

# Build stage
FROM alpine:${ALPINE_VER} AS build

RUN apk add --no-cache --virtual .build-deps \
    build-base \
    ca-certificates \
    freerdp-dev \
    g++ \
    jpeg-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libressl-dev \
    libtool \
    make \
    pango-dev \
    pulseaudio-dev \
    tar \
    uuid-dev \
    vncserver-dev \
    zlib-dev

WORKDIR /usr/local/src

RUN wget -q https://downloads.apache.org/guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz && \
    tar -zxf guacamole-server-${GUAC_VER}.tar.gz && \
    rm guacamole-server-${GUAC_VER}.tar.gz && \
    cd guacamole-server-${GUAC_VER} && \
    ./configure --with-init-dir=/etc/init.d && \
    make && \
    make install && \
    cd .. && \
    rm -rf guacamole-server-${GUAC_VER}

# Runtime stage
FROM alpine:${ALPINE_VER}

RUN apk add --no-cache \
    freerdp \
    ghostscript \
    imagemagick \
    libcairo \
    libjpeg-turbo \
    libpng \
    libressl \
    libuuid \
    pango \
    postgresql-client \
    pulseaudio \
    ttf-dejavu \
    vncserver \
    zlib

ENV GUACAMOLE_HOME=/config/guacamole \
    POSTGRES_USER=guacamole \
    POSTGRES_PASSWORD=guacamole \
    POSTGRES_DB=guacamole_db \
    GUAC_LDAP_VERSION=${GUAC_LDAP_VER} \
    POSTGRES_JDBC_VERSION=${POSTGRES_JDBC_VER} \
    PATH=$PATH:/usr/local/guacamole/bin

COPY --from=build /usr/local/lib/freerdp/* /usr/lib/freerdp/
COPY --from=build /usr/local/lib/* /usr/local/lib/
COPY --from=build /usr/local/guacamole /usr/local/guacamole
COPY guacamole-init /usr/local/guacamole/bin/guacamole-init
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN mkdir -p /config/guacamole/extensions \
    /config/guacamole/lib \
    /config/postgres && \
    addgroup guacd && \
    adduser -G guacd -D -s /sbin/nologin guacd && \
    chown -R guacd:guacd /usr/local/guacamole /config/guacamole /config/postgres && \
    chmod +x /usr/local/guacamole/bin/guacamole-init /usr/local/bin/docker-entrypoint.sh

USER guacd

EXPOSE 8080

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
