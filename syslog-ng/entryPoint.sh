#!/bin/sh
cp /etc/syslog-ng-orig/scl.conf /etc/syslog-ng/scl.conf 
/sbin/syslog-ng -F -f /etc/syslog-ng/syslog-ng.conf
exec "$@"