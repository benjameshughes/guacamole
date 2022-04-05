# guacamole docker image
## This is a repo for the gauacamole server and client in one image. Most of the work was originally done by Oznu

Docker image for Apache Guacamole.

Apache Guacamole is a clientless remote desktop gateway. It supports standard protocols like VNC, RDP, and SSH.

We call it clientless because no plugins or client software are required.

Thanks to HTML5, once Guacamole is installed on a server, all you need to access your desktops is a web browser.

[Oznu original Docker Image](https://hub.docker.com/r/oznu/guacamole/)

# How to use
` docker run -d \
  --name=guacamole \
  -p 8080:8080
  -v <path/to/config>:/config
  benjameshughes/guacamole
`
This will run the latest version of the image and guacamole. If you'd like to use a different version please change the tag.
