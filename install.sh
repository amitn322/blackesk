#!/bin/bash

NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'


echo -e ${CYAN}
cat << "EOF"


                                                                                            
,-----.  ,--.     ,---.   ,-----.,--. ,--.    ,------. ,---.  ,--. ,--.     ,--.     ,--.   
|  |) /_ |  |    /  O  \ '  .--./|  .'   /    |  .---''   .-' |  .'   /    /   |    /    \  
|  .-.  \|  |   |  .-.  ||  |    |  .   '     |  `--, `.  `-. |  .   '     `|  |   |  ()  | 
|  '--' /|  '--.|  | |  |'  '--'\|  |\   \    |  `---..-'    ||  |\   \     |  |.--.\    /  
`------' `-----'`--' `--' `-----'`--' '--'    `------'`-----' `--' '--'     `--''--' `--'   
                                                                                            
EOF
echo -e "\n${NOCOLOR} Welcome to ESK Installer echo ${GREEN} V 1.0! ${NOCOLOR}"
echo -e "\n${ORANGE}Enjoy Coffee while I do this for you :) ${NOCOLOR}"

echo -e "\n${PURPLE}You can also buy me coffee at ${YELLOW}https://www.buymeacoffee.com/akn ${NOCOLOR}"

echo -e "${RED}"

cat << "EOF2"
                      (
                        )     (
                 ___...(-------)-....___
             .-""       )    (          ""-.
       .-'``'|-._             )         _.-|
      /  .--.|   `""---...........---""`   |
     /  /    |                             |
     |  |    |                             |
      \  \   |                             |
       `\ `\ |                             |
         `\ `|                             |
         _/ /\                             /
        (__/  \                           /
     _..---""` \                         /`""---.._
  .-'           \                       /          '-.
 :               `-.__             __.-'              :
 :                  ) ""---...---"" (                 :
  '._               `"--...___...--"`              _.'
   \""--..__                              __..--""/
     '._     """----.....______.....----"""     _.'
        `""--..,,_____            _____,,..--""`
                      `"""----"""`                                                                         
EOF2



echo -e ${NOCOLOR}


function info()
{
	if [ "$2" == "sameline" ];then 
		echo -ne "${LIGHTGREEN}${1}${NOCOLOR}\r"
	else 
		echo -e ${LIGHTGREEN}${1}${NOCOLOR} 
	fi
}

function ok()
{
	if [ "$2" == "sameline" ];then 
		echo -ne "${GREEN}${1}${NOCOLOR}\r"
	else 
		echo -e ${GREEN}${1}${NOCOLOR} 
	fi
}
function warn()
{
	if [ "$2" == "sameline" ];then 
		echo -ne "${YELLOW}${1}${NOCOLOR}\r"
	else 
		echo -e ${YELLOW}${1}${NOCOLOR} 
	fi
}
function fail()
{
	if [ "$2" == "sameline" ];then 
		echo -ne "${RED}${1}${NOCOLOR}\r"
	else 
		echo -e ${RED}${1}${NOCOLOR} 
	fi
}
if [ -z $1 ];then
    fail "Usage $0 <single-node|multi-node>"
    fail "Example: sh $0 single-node"
    exit;
fi


function genRandomPassword()
{
	password=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 `
	echo $password
}

sudo sysctl -w vm.max_map_count=280530

if [ "$1" == 'single-node' ];then
    COMPOSE_FILE="docker-compose-singlenode.yml"
    cat << "EOF" > instances.yml 
instances:
  - name: syslog01
    dns:
      - syslog01 
      - localhost
    ip:
      - 127.0.0.1
  - name: es01
    dns:
      - es01
      - localhost
    ip:
      - 127.0.0.1
  - name: 'kib01'
    dns:
      - kib01
      - localhost
EOF
elif [ "$1" == 'multi-node' ];then 
    COMPOSE_FILE="docker-compose-multinode.yml"
cat << "EOF" > instances.yml 
instances:
  - name: syslog01
    dns:
      - syslog01 
      - localhost
    ip:
      - 127.0.0.1     
  - name: es01
    dns:
      - es01
      - localhost
    ip:
      - 127.0.0.1
  - name: es02
    dns:
      - es02
      - localhost
    ip:
      - 127.0.0.1
  - name: es03
    dns:
      - es03
      - localhost
    ip:
      - 127.0.0.1
  - name: 'kib01'
    dns:
      - kib01
      - localhost
EOF


else
    fail "Invalid Option,Aborting..."
    exit 255
fi

info "Creating Certificates for the cluster"
docker-compose -f create-certs.yml run --rm create_certs
info "Certificates Created, Now Creating Instances for ESK Stack"
#docker-compose up -d --force-recreate --build

docker-compose -f ${COMPOSE_FILE} up -d 
info "Waiting for Elasticsearch to be ready..."
SECONDS=0
while true; do 
	sleep 10
	warn " Still waiting for Elasticsearch to be ready , $SECONDS seconds elapsed" "sameline"
	#timeout 1 sh -c 'docker exec es01 cat < /dev/null > /dev/tcp/127.0.0.1/9200' &>> /dev/null
	curl -s -k  https://localhost:9200/_security/_authenticate?pretty | grep -i '"status" : 401' &> /dev/null
	if [ $? -eq 0 ];then
		echo ""
		ok "Elasticsearch is now ready, moving on !"
		
		break
	fi 
done 

docker exec es01 /bin/bash -c "bin/elasticsearch-setup-passwords auto --batch --url https://es01:9200" > /tmp/creds.txt
if [ $? -ne 0 ];then
   fail "Couldn't Set Passwords, Aborting..."
   exit 255
fi
KIBANA_USER=`grep KIBANA_USER .env | awk -F'=' {'print $2'}`
kibana_password=`grep -i "${KIBANA_USER} =" /tmp/creds.txt | awk {'print $4'}`
elastic_password=`grep "PASSWORD elastic =" /tmp/creds.txt | awk {'print $4'}`
mv /tmp/creds.txt .creds.txt
sed -i "s/^ELASTICSEARCH_USERNAME=.*/ELASTICSEARCH_USERNAME=${KIBANA_USER}/" .env 
sed -i "s/^ELASTICSEARCH_PASSWORD=.*/ELASTICSEARCH_PASSWORD=${kibana_password}/" .env 
docker-compose -f ${COMPOSE_FILE} up -d
SECONDS=0
ok "Waiting for Elasticsearch to be ready"
while true; do 
	sleep 10
	warn " Still waiting for Elasticsearch to be ready, $SECONDS seconds elapsed" "sameline"
	#timeout 1 sh -c 'docker exec es01 cat < /dev/null > /dev/tcp/127.0.0.1/9200' &>> /dev/null
	curl -s -k  https://localhost:9200/_security/_authenticate?pretty | grep -i '"status" : 401' &> /dev/null
	if [ $? -eq 0 ];then
		echo ""
		ok "Elasticsearch is now ready, moving on !"
		info "Creating Syslog-ng Role"
		SYSLOG_USER=`grep SYSLOG_USER .env | awk -F'=' {'print $2'}`
		SYSLOG_PASSWORD=`genRandomPassword`
		sed -i "s/@define elasticUser.*/@define elasticUser \"${SYSLOG_USER}\"/" syslog-ng/conf/syslog-ng.conf
		sed -i "s/@define elasticPass.*/@define elasticPass \"${SYSLOG_PASSWORD}\"/" syslog-ng/conf/syslog-ng.conf
		echo "SYSLOG_PASSWORD=${SYSLOG_PASSWORD}" >> .creds.txt 
		docker exec syslog01 syslog-ng-ctl reload
		timeout 5 curl -k -XPOST -u elastic:${elastic_password} 'https://localhost:9200/_security/role/syslog-ng' -H 'Content-Type: application/json' -d '{"indices" : [{"names" : [ "syslog-ng*","wazuh-*","windows_*" ],  "privileges" : [ "create","create_index", "write" ]}]}'
		echo ""
		info "Creating Syslog-ng User"
		timeout 5 curl -k -X POST -u elastic:${elastic_password} "https://localhost:9200/_security/user/${SYSLOG_USER}?pretty" -H 'Content-Type: application/json' -d'{"password" : "'"${SYSLOG_PASSWORD}"'","roles" : [ "syslog-ng" ],"full_name" : "Syslog NG"}'
		break
	fi 
done 
info "Waiting for Kibana to be ready"
SECONDS=0 
while true;do 
	sleep 3
	warn " Still waiting on Kibana to be ready, $SECONDS seconds elapsed" "sameline" 
	curl -s -k -X GET -u elastic:${elastic_password} "https://localhost:5601/api/saved_objects/index-pattern/syslog-ng" -H 'kbn-xsrf: true' | grep -i syslog-ng &> /dev/null 
	if [ $? -eq 0 ];then 
		echo ""
		info "Creating Index Pattern for Syslog-ng"
		timeout 5 curl -k -XPOST -u elastic:${elastic_password} "https://localhost:5601/api/saved_objects/index-pattern/syslog-ng" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d'{"attributes": {"title":"syslog-ng_*","timeFieldName": "ISODATE"}}'
		info "Setting Syslog-ng_* as the Default Pattern.."
		curl -k -XPOST -u elastic:${elastic_password} "https://localhost:5601/api/kibana/settings" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d'{"changes": {"defaultIndex": "syslog-ng_*"}}' 	
		
		break
	fi 
done 
echo ""
info "Setting up GeoPoint Index Mapping for syslog-ng"
curl -k -XPUT -u elastic:${elastic_password} "https://localhost:9200/_template/syslog-ng" -H 'Content-Type: application/json' -d'{"index_patterns": ["syslog-ng_*"], "mappings" : { "properties" : { "geopoint" : { "type" : "geo_point" }} } }'
info "Generating Some Fake Logs, you can delete the index and start over.."
/bin/bash ./extras/loggen.sh 10
	
info "Everything should have been completed, please login to https://ipaddress:5601 with following user:"
info "--------------------------------------------------"
ok "Username: elastic"
ok "Password: ${elastic_password}"
info "--------------------------------------------------"
info "The initial set of credentials are stored in .creds.txt in the current Directory"
warn "Don't forget to change the default credentials, please create an issue on github for any issues."
