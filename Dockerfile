FROM tomcat:9.0.62-jre8-openjdk-slim-buster

ENV ARCH=amd64 \
  S6_VER=v2.2.0.2 \
  GUAC_VER=1.4.0 \
  GUACAMOLE_HOME=/app/guacamole \
  PG_MAJOR=13 \
  PGDATA=/config/postgres \
  POSTGRES_USER=guacamole \
  POSTGRES_DB=guacamole_db

RUN apt-get update && apt-get install -y \
  apt-transport-https

RUN apt-get install -y \
  curl

# Apply the s6-overlay
RUN curl -SLO "https://github.com/just-containers/s6-overlay/releases/download/${S6_VER}/s6-overlay-${ARCH}.tar.gz" \
  && tar -xzf s6-overlay-${ARCH}.tar.gz -C / \
  && tar -xzf s6-overlay-${ARCH}.tar.gz -C /usr ./bin \
  && rm -rf s6-overlay-${ARCH}.tar.gz \
  && mkdir -p ${GUACAMOLE_HOME} \
    ${GUACAMOLE_HOME}/lib \
    ${GUACAMOLE_HOME}/extensions

WORKDIR ${GUACAMOLE_HOME}

# Install dependencies
RUN apt-get update && apt-get install -y \
  libcairo2-dev libjpeg62-turbo-dev libpng-dev \
  libossp-uuid-dev libavcodec-dev libavutil-dev \
  libswscale-dev freerdp2-dev libfreerdp-client2-2 libpango1.0-dev \
  libssh2-1-dev libtelnet-dev libvncserver-dev \
  libpulse-dev libssl-dev libvorbis-dev libwebp-dev libwebsockets-dev \
  ghostscript postgresql-${PG_MAJOR} \
  && rm -rf /var/lib/apt/lists/*

# Link FreeRDP to where guac expects it to be
RUN [ "$ARCH" = "armhf" ] && ln -s /usr/local/lib/freerdp /usr/lib/arm-linux-gnueabihf/freerdp || exit 0
RUN [ "$ARCH" = "amd64" ] && ln -s /usr/local/lib/freerdp /usr/lib/x86_64-linux-gnu/freerdp || exit 0

# Install guacamole-server
RUN curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-server-${GUAC_VER}.tar.gz \
  && cd guacamole-server-${GUAC_VER} \
  && ./configure --enable-allow-freerdp-snapshots \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && cd .. \
  && rm -rf guacamole-server-${GUAC_VER}.tar.gz guacamole-server-${GUAC_VER} \
  && ldconfig

# Install guacamole-client and postgres auth adapter
RUN set -x \
  && rm -rf ${CATALINA_HOME}/webapps/ROOT \
  && curl -SLo ${CATALINA_HOME}/webapps/ROOT.war "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war" \
  && curl -SLo ${GUACAMOLE_HOME}/lib/postgresql-42.1.4.jar "https://jdbc.postgresql.org/download/postgresql-42.1.4.jar" \
  && curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-jdbc-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-auth-jdbc-${GUAC_VER}.tar.gz \
  && cp -R guacamole-auth-jdbc-${GUAC_VER}/postgresql/guacamole-auth-jdbc-postgresql-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions/ \
  && cp -R guacamole-auth-jdbc-${GUAC_VER}/postgresql/schema ${GUACAMOLE_HOME}/ \
  && rm -rf guacamole-auth-jdbc-${GUAC_VER} guacamole-auth-jdbc-${GUAC_VER}.tar.gz

# Add optional extensions
RUN set -xe \
  && mkdir ${GUACAMOLE_HOME}/extensions-available \
  && for i in auth-ldap auth-duo auth-header auth-cas auth-openid auth-quickconnect auth-totp; do \
    echo "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && tar -xzf guacamole-${i}-${GUAC_VER}.tar.gz \
    && cp guacamole-${i}-${GUAC_VER}/guacamole-${i}-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
    && rm -rf guacamole-${i}-${GUAC_VER} guacamole-${i}-${GUAC_VER}.tar.gz \
  ;done

# Remove un-needed dependencies due to using a slim distro
RUN apt-get update && apt-get remove -y \
  curl \
  tar \
  build-essential

# Final clean up
RUN apt-get autoremove -y

ENV PATH=/usr/lib/postgresql/${PG_MAJOR}/bin:$PATH
ENV GUACAMOLE_HOME=/config/guacamole

WORKDIR /config

COPY root /

EXPOSE 8080

ENTRYPOINT [ "/init" ]
