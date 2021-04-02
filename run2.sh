#!/bin/sh -ex

docker network create --attachable --opt com.docker.network.bridge.name=docker docker || echo $?
docker volume create pg_arclog
docker volume create pg_save2
docker stop pg_save2 || echo $?
docker rm pg_save2 || echo $?
docker run \
    --detach \
    --env CLUSTER_NAME=save \
    --env GROUP_ID="$(id -g)" \
    --env LANG=ru_RU.UTF-8 \
    --env PRIMARY_CONNINFO="host=pg_save1.docker,pg_save2.docker,pg_save3.docker application_name=pg_save2.docker target_session_attrs=read-write" \
    --env TZ=Asia/Yekaterinburg \
    --env USER_ID="$(id -u)" \
    --hostname pg_save2.docker \
    --mount type=bind,source=/etc/certs,destination=/etc/certs,readonly \
    --mount type=volume,source=pg_arclog,destination=/var/lib/postgresql/arclog \
    --mount type=volume,source=pg_save2,destination=/var/lib/postgresql \
    --name pg_save2 \
    --network name=docker \
    --restart always \
    rekgrpth/pg_save runsvdir /etc/service
