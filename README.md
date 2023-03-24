# 🥑 Guacamole Server and Client Docker Image 🐳

This Docker image provides a complete installation of the [Guacamole](https://guacamole.apache.org/) Server and Client, along with all available extensions. It is based on Alpine Linux to provide a lightweight and secure image.

## 🚀 Usage

To use this Docker image, you can use the following command:

```sh
docker run -d --name guacamole
-p 8080:8080
-v /path/to/guacamole:/config
-e POSTGRES_USER=guacamole
-e POSTGRES_PASSWORD=mysecretpassword
-e POSTGRES_DB=guacamole_db
benjameshughes/guacamole:latest
```

This will start a new container running the Guacamole Server and Client, with the PostgreSQL database configured with the specified username, password, and database name. You can access the Guacamole web interface by visiting `http://localhost:8080/guacamole/`.

## 🔧 Configuration

This Docker image includes sample configuration files for Guacamole, located in the `config` directory. You can modify these files as needed and mount them into the container using a volume, as shown in the usage example above.

The following environment variables can be used to configure the Guacamole installation:

- `POSTGRES_USER`: the username to use for the PostgreSQL database (default: `guacamole`).
- `POSTGRES_PASSWORD`: the password to use for the PostgreSQL database (default: `guacamole`).
- `POSTGRES_DB`: the name of the PostgreSQL database to use (default: `guacamole_db`).
- `GUACAMOLE_HOME`: the location of the Guacamole home directory (default: `/config/guacamole`).
- `GUACAMOLE_VERSION`: the version of Guacamole to install (default: `1.4.0`).
- `GUACAMOLE_EXT_DIR`: the location of the Guacamole extensions directory (default: `${GUACAMOLE_HOME}/extensions-available`).

## 📝 License

This Docker image is licensed under the Apache License 2.0. You can find a copy of the license in the `LICENSE` file.
