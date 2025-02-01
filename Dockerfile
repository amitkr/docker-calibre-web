# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/unrar:latest AS unrar

FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CALIBREWEB_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="notdriz"

COPY kepubify-linux-64bit /tmp/kepubify
# COPY covergen-linux-64bit /tmp/covergen
# COPY seriesmeta-linux-64bit /tmp/seriesmeta
COPY calibreweb-src-0.6.24.tar.gz /tmp/calibre-web.tar.gz

RUN \
  echo "**** install build packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    libldap2-dev \
    libsasl2-dev \
    python3-dev && \
  echo "**** install runtime packages ****" && \
  apt-get install -y --no-install-recommends \
    imagemagick \
    ghostscript \
    libldap2 \
    libmagic1t64 \
    libsasl2-2 \
    libxi6 \
    libxslt1.1 \
    python3-venv \
    sqlite3 \
    xdg-utils && \
  echo "**** install calibre-web ****" && \
  if [ -z ${CALIBREWEB_RELEASE+x} ]; then \
    CALIBREWEB_RELEASE=$(curl -sX GET "https://api.github.com/repos/janeczku/calibre-web/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  CALIBREWEB_TAR_URL="https://codeload.github.com/janeczku/calibre-web/tar.gz/refs/tags/${CALIBREWEB_RELEASE}" && \
  CALIBREWEB_TMP_TAR="/tmp/calibre-web.tar.gz" && \
  if [ ! -f ${CALIBREWEB_TMP_TAR} ]; then \
    curl -o "${CALIBREWEB_TMP_TAR}" -L "${CALIBREWEB_TAR_URL}" ; \
  fi && \
  mkdir -p /app/calibre-web && \
  tar zxf \
    "${CALIBREWEB_TMP_TAR}" -C \
    /app/calibre-web --strip-components=1 && \
  cd /app/calibre-web && \
  python3 -m venv /lsiopy && \
  python3 -m pip install -U --no-cache-dir pip wheel && \
  python3 -m pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/ubuntu/ \
    -r requirements.txt \
    -r optional-requirements.txt && \
  cd - && \
  echo "***install kepubify" && \
  KEPUBIFY_TMP="/tmp/kepubify" && \
  KEPUBIFY_DEST="/usr/bin/kepubify" && \
  if [ -f "${KEPUBIFY_TMP}" ]; then \
    cp "${KEPUBIFY_TMP}" "${KEPUBIFY_DEST}" && \
    chmod +x "${KEPUBIFY_DEST}" ; \
  fi && \
  if [ -z ${KEPUBIFY_RELEASE+x} ]; then \
    KEPUBIFY_RELEASE=$(curl -sX GET "https://api.github.com/repos/pgaskin/kepubify/releases/latest" \
      | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /usr/bin/kepubify -L \
    https://github.com/pgaskin/kepubify/releases/download/${KEPUBIFY_RELEASE}/kepubify-linux-64bit && \
  echo "**** cleanup ****" && \
  apt-get -y purge \
    build-essential \
    libldap2-dev \
    libsasl2-dev \
    python3-dev && \
  apt-get -y autoremove && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /root/.cache

# add local files
COPY root/ /

# add unrar
COPY --from=unrar /usr/bin/unrar-ubuntu /usr/bin/unrar

# ports and volumes
EXPOSE 8083
VOLUME /config
