FROM alpine
ARG SYSLOG_VERSION
ARG TIMEZONE
ADD ./syslog-ng/build.sh /build.sh
RUN echo "S: ${SYSLOG_VERSION}"
RUN /build.sh 
RUN mv /etc/syslog-ng/ /etc/syslog-ng-orig/
VOLUME ["/var/log/syslog-ng", "/var/run/syslog-ng"]
RUN apk add --no-cache tzdata
RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
ENV TZ ${TIMEZONE}
RUN TZ=${TIMEZONE}
COPY ./syslog-ng/entryPoint.sh /entryPoint.sh
RUN chmod 755 /entryPoint.sh
ENTRYPOINT ["/entryPoint.sh"]
CMD ["/sbin/syslog-ng -F -f /etc/syslog-ng/syslog-ng.conf"]
