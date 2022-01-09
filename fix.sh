#!/bin/bash
NODE="es01"
IFS=$'\n'
creds=elastic:nx9FOOpeCSAoVqXZZWew
for line in $(curl -u $creds -k -s 'https://localhost:9200/_cat/shards' | fgrep UNASSIGNED); do
  INDEX=$(echo $line | (awk '{print $1}'))
  SHARD=$(echo $line | (awk '{print $2}'))
  echo "Index: $INDEX"
  echo "SHARD: $SHARD"  

  curl -u $creds -k -H 'Content-Type: application/json'  -XPOST 'https://localhost:9200/_cluster/reroute' -d '{ 
	"commands": [ 
	{
            "allocate": {
                "index": "'$INDEX'",
                "shard": '$SHARD',
                "node": "'$NODE'",
                "allow_primary": true
          }
        }
    ]
  }'
done
