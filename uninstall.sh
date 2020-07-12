#!/bin/bash
docker-compose -f docker-compose-multinode.yml down && docker volume rm es_certs es_data01 es_data02 es_data03

