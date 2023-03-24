FROM alpine:3.15

ENV GUAC_VER=1.4.0 \
    GUACAMOLE_HOME=/app/guacamole \
    POSTGRES_USER=guacamole \
    POSTGRES_DB=guacamole_db \
    TOMCAT_VERSION=9.0.54-r0 \
    S6_VERSION=2.2.0.3 \
    POSTGRES_VERSION=13.4-r0

# Install dependencies
RUN apk add --update --no-cache \
        bash \
        curl \
        freerdp \
        ghostscript \
        gnu-libiconv \
        libc-dev \
        libjpeg-turbo-dev \
        libossp-uuid-dev \
        libpq \
        libressl-dev \
        libssh2 \
        libtelnet-dev \
        libvncserver \
        libwebp-dev \
        libwebsockets-dev \
        musl-dev \
        openjdk8-jre \
        postgresql-client=${POSTGRES_VERSION} \
        postgresql-dev=${POSTGRES_VERSION} \
        pulseaudio \
        pulseaudio-dev \
        ttf-dejavu \
        ttf-droid \
        ttf-liberation \
        ttf-ubuntu-font-family \
    && rm -rf /var/cache/apk/*

# Download and install S6 Overlay
RUN curl -sSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-amd64.tar.gz | tar xz -C /

# Install Guacamole Server
RUN apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        build-base \
        cairo-dev \
        ffmpeg-dev \
        freerdp-dev \
        glib-dev \
        jpeg-dev \
        libogg-dev \
        libpng-dev \
        libpulse-dev \
        libsodium-dev \
        libvorbis-dev \
        libwebp-dev \
        libwebsockets-dev \
        mariadb-dev \
        openssl-dev \
        pango-dev \
        sdl2-dev \
        tiff-dev \
        uuid-dev \
        x264-dev \
        zlib-dev \
    && curl -sSL http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz | tar zx \
    && cd guacamole-server-${GUAC_VER} \
    && ./configure --with-init-dir=/etc/init.d --with-systemd-dir=/etc/systemd/system --disable-ldap --disable-ssh --disable-smartcard --disable-cliprdr --disable-pulseaudio --disable-pango --enable-vnc --enable-openssl --enable-webp --enable-websockets --enable-extensions --prefix=${GUACAMOLE_HOME} \
    && make \
    && make install \
    && cd .. \
    && rm -rf guacamole-server-${GUAC_VER} \
    && apk del .build-deps

# Install Guacamole Client
RUN apk add --no-cache \
        apache-tomcat=${TOMCAT_VERSION} \
        apache-tomcat-lib \
        postgresql-jdbc \
        ttf-dejavu \
    && mkdir -p ${GUACAMOLE_HOME} \
        ${GUACAMOLE_HOME}/lib \
        ${GUACAMOLE_HOME}/extensions-available \
        ${GUACAMOLE_HOME}/extensions \
    && curl -sSL http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war -o ${GUACAMOLE_HOME}/guacamole.war
&& unzip ${GUACAMOLE_HOME}/guacamole.war -d ${GUACAMOLE_HOME}/guacamole
&& rm ${GUACAMOLE_HOME}/guacamole.war
&& rm -rf ${CATALINA_HOME}/webapps/*
&& ln -s ${GUACAMOLE_HOME}/guacamole/ ${CATALINA_HOME}/webapps/ROOT
&& curl -sSL http://jdbc.postgresql.org/download/postgresql-42.3.1.jar -o ${GUACAMOLE_HOME}/lib/postgresql.jar
&& curl -sSL http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-jdbc-${GUAC_VER}.tar.gz | tar xz --strip-components=1 -C ${GUACAMOLE_HOME}/extensions-available guacamole-auth-jdbc-${GUAC_VER}/postgresql/guacamole-auth-jdbc-postgresql-${GUAC_VER}.jar guacamole-auth-jdbc-${GUAC_VER}/postgresql/schema
&& curl -sSL http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-header-${GUAC_VER}.tar.gz | tar xz -C ${GUACAMOLE_HOME}/extensions-available guacamole-auth-header-${GUAC_VER}/guacamole-auth-header-${GUAC_VER}.jar
&& curl -sSL http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-duo-${GUAC_VER}.tar.gz | tar xz -C ${GUACAMOLE_HOME}/extensions-available guacamole-auth-duo-${GUAC_VER}/guacamole-auth-duo-${GUAC_VER}.jar
&& curl -sSL http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-totp-${GUAC_VER}.tar.gz | tar xz -C ${GUACAMOLE_HOME}/extensions-available guacamole-auth-totp-${GUAC_VER}/guacamole-auth-totp-${GUAC_VER}.jar
&& apk del apache-tomcat-lib

# Add Guacamole config and scripts
COPY config ${GUACAMOLE_HOME}/config
COPY scripts ${GUACAMOLE_HOME}/scripts

# Set permissions
RUN chown -R nobody:nogroup ${GUACAMOLE_HOME}
&& chmod +x ${GUACAMOLE_HOME}/scripts/*.sh

Expose Guacamole HTTP port
EXPOSE 8080

# Define container init command
ENTRYPOINT ["/init"]

Copy S6 init scripts
COPY init /etc/cont-init.d/00-s6-init

Copy S6 services
COPY services.d /etc/services.d

Copy S6 run scripts
COPY cont-finish.d /etc/cont-finish.d

Copy S6 finish scripts
COPY cont-finish.d /etc/cont-finish.d

Copy S6 Overlay binaries
COPY s6-binaries /usr/local/bin

Copy S6 Overlay libraries
COPY s6-libraries /usr/local/lib
