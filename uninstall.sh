#!/bin/bash
docker ps | grep -i 'es02\|es03'
if [ $? -eq 0 ];then
        echo "Multi node setup detected. Uninstalling.."
        docker-compose -f docker-compose-multinode.yml down && docker volume rm es_certs es_data01 es_data02 es_data03
else
        echo "Single Node setup detected, Uninstalling.."
        docker-compose -f docker-compose-singlenode.yml down && docker volume rm es_certs es_data01
fi
echo "(-) Removing Syslog ng image"
docker rmi es_syslog-ng
echo "(-) Removing Creds file"
rm .creds.txt
echo "Uninstall Complete"
