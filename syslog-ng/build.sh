#!/bin/sh
set -e
export DOWNLOAD_URL="https://github.com/balabit/syslog-ng/releases/download/syslog-ng-${SYSLOG_VERSION}/syslog-ng-${SYSLOG_VERSION}.tar.gz"
apk update
apk add libressl-dev
#apk add openjdk8 
apk add glib pcre eventlog openssl #openssl-dev
apk add curl alpine-sdk glib-dev pcre-dev eventlog-dev
apk add libmaxminddb libmaxminddb-dev json-c json-c-dev curl-dev gradle
#export PATH=/usr/lib/jvm/java-1.8-openjdk/bin/:$PATH
cd /tmp
echo "Downloading Syslog-ng Version: ${SYSLOG_VERSION}"
curl -L "${DOWNLOAD_URL}" > "syslog-ng-${SYSLOG_VERSION}.tar.gz"
tar zxf "syslog-ng-${SYSLOG_VERSION}.tar.gz"
cd "syslog-ng-${SYSLOG_VERSION}"
./configure --enable-http  --enable-geoip2 --prefix=/ --sysconfdir=/etc/syslog-ng/ --enable-format-json --enable-json --disable-java
make
make install
cd ..
rm -rf "syslog-ng-${SYSLOG_VERSION}" "syslog-ng-${SYSLOG_VERSION}.tar.gz"
#ln -sf $(find / -name libjvm.so)  /usr/lib/libjvm.so
apk del curl alpine-sdk glib-dev pcre-dev eventlog-dev libmaxminddb-dev json-c-dev curl-dev libressl-dev
