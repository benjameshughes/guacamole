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
    && rm -rf /var/lib/apt/lists/*

ARG GUAC_VER=1.4.0
ENV GUACAMOLE_HOME=/config/guacamole
ENV POSTGRES_USER=guacamole
ENV POSTGRES_PASSWORD=mysecretpassword
ENV POSTGRES_DB=guacamole_db

# Install Guacamole client and PostgreSQL auth adapter
RUN mkdir -p ${GUACAMOLE_HOME}/lib \
    && curl -SLo ${GUACAMOLE_HOME}/lib/guacamole-client.jar \
        "https://downloads.apache.org/guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war" \
    && curl -SLo ${GUACAMOLE_HOME}/lib/postgresql.jar \
        "https://jdbc.postgresql.org/download/postgresql-42.3.0.jar" \
    && chmod 444 ${GUACAMOLE_HOME}/lib/*.jar

# Install optional extensions
RUN mkdir -p ${GUACAMOLE_HOME}/extensions-available \
    && for i in auth-ldap auth-duo auth-header auth-cas auth-openid auth-quickconnect auth-totp; do \
        curl -SLo ${GUACAMOLE_HOME}/extensions-available/guacamole-${i}.jar \
            "https://downloads.apache.org/guacamole/${GUAC_VER}/binary/guacamole-${i}-${!i/_/-}-${!i/VER/_VER}.tar.gz" \
        && tar -xzf ${GUACAMOLE_HOME}/extensions-available/guacamole-${i}.jar -C ${GUACAMOLE_HOME}/extensions-available \
        && rm ${GUACAMOLE_HOME}/extensions-available/guacamole-${i}.jar \
    ;done

# Copy init script
COPY init /usr/local/bin/
RUN chmod +x /usr/local/bin/init

# Expose port 8080
EXPOSE 8080

# Run Guacamole on startup
ENTRYPOINT ["/usr/local/bin/init"]
CMD ["guacd"]
