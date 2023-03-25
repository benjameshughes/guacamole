# Build environment
FROM maven:3.8.4-openjdk-17-slim AS build
COPY README.md /app/README.md
WORKDIR /app
COPY . .
RUN mvn package

# Production environment
FROM gcr.io/distroless/java:latest
ENV GUACAMOLE_HOME=/config/guacamole
ENV POSTGRES_USER=guacamole
ENV POSTGRES_PASSWORD=mysecretpassword
ENV POSTGRES_DB=guacamole_db

# Install dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Guacamole and extensions
COPY --from=build /app/guacamole-server/target/guacamole-server-* /app/guacamole-server/
COPY --from=build /app/extensions /app/guacamole-server/extensions

# Set version numbers
ARG GUAC_VER=1.4.0
ARG AUTH_LDAP_VER=${GUAC_VER}
ARG AUTH_DUO_VER=${GUAC_VER}
ARG AUTH_HEADER_VER=${GUAC_VER}
ARG AUTH_CAS_VER=${GUAC_VER}
ARG AUTH_OPENID_VER=${GUAC_VER}
ARG AUTH_QUICKCONNECT_VER=${GUAC_VER}
ARG AUTH_TOTP_VER=${GUAC_VER}

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

# Clean up dependencies
RUN apt-get purge -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Copy init script
COPY init /usr/local/bin/
RUN chmod +x /usr/local/bin/init

# Expose port 8080
EXPOSE 8080

# Run Guacamole on startup
ENTRYPOINT ["/usr/local/bin/init"]
CMD ["guacd"]
