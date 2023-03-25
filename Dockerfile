# Base image
FROM ubuntu:20.04

# Install required dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk-headless \
    libcairo2-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libossp-uuid-dev \
    libfreerdp-dev \
    libpango1.0-dev \
    libssh2-1-dev \
    libtelnet-dev \
    libvncserver-dev \
    libpulse-dev \
    curl \
    postgresql \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ARG GUAC_VER=1.4.0
ENV GUACAMOLE_HOME=/config/guacamole
ENV POSTGRES_USER=guacamole
ENV POSTGRES_PASSWORD=mysecretpassword
ENV POSTGRES_DB=guacamole_db

# Install Guacamole server and client
WORKDIR /usr/local/src
RUN curl -SLO "https://downloads.apache.org/guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz" \
    && tar xzf guacamole-server-${GUAC_VER}.tar.gz \
    && rm guacamole-server-${GUAC_VER}.tar.gz \
    && cd guacamole-server-${GUAC_VER} \
    && ./configure --with-init-dir=/etc/init.d \
    && make \
    && make install \
    && ldconfig \
    && cd .. \
    && curl -SLO "https://downloads.apache.org/guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war" \
    && mkdir -p /usr/share/tomcat8/.guacamole \
    && ln -s /usr/local/src/guacamole-${GUAC_VER}.war /usr/share/tomcat8/.guacamole/guacamole.war

# Install PostgreSQL authentication module
RUN curl -SLO "https://downloads.apache.org/guacamole/${GUAC_VER}/binary/guacamole-auth-jdbc-${GUAC_VER}.tar.gz" \
    && tar xzf guacamole-auth-jdbc-${GUAC_VER}.tar.gz \
    && rm guacamole-auth-jdbc-${GUAC_VER}.tar.gz \
    && cp guacamole-auth-jdbc-${GUAC_VER}/postgresql/guacamole-auth-jdbc-postgresql-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions \
    && rm -rf guacamole-auth-jdbc-${GUAC_VER}

# Copy init script
COPY init /usr/local/bin/
RUN chmod +x /usr/local/bin/init

# Expose ports
EXPOSE 8080

# Start Guacamole server
ENTRYPOINT ["/usr/local/bin/init"]
CMD ["guacd"]
