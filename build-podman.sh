CALIBREWEB_RELEASE=$(curl -sX GET "https://api.github.com/repos/janeczku/calibre-web/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]')
podman build \
	--build-arg BUILD_DATE=$(date '+%4Y-%m-%d') \
	--build-arg CALIBREWEB_RELEASE=$CALIBREWEB_RELEASE \
	-f Dockerfile -t docker.io/amitkr/calibre-web:v$CALIBREWEB_RELEASE .

