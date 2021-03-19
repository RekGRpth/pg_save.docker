#!/bin/sh -ex

docker network create --attachable --opt com.docker.network.bridge.name=docker docker || echo $?
#docker volume create pg_arclog
docker volume create pg_save3
docker stop pg_save3 || echo $?
docker rm pg_save3 || echo $?
docker run \
    --detach \
    --env CLUSTER_NAME=save \
    --env ETCD=http://etcd.docker:2379/v3 \
    --env GROUP_ID="$(id -g)" \
    --env LANG=ru_RU.UTF-8 \
    --env TZ=Asia/Yekaterinburg \
    --env USER_ID="$(id -u)" \
    --hostname pg_save3.docker \
    --mount type=bind,source=/etc/certs,destination=/etc/certs,readonly \
    --mount type=volume,source=pg_save3,destination=/var/lib/postgresql \
    --name pg_save3 \
    --network name=docker \
    --restart always \
    rekgrpth/pg_save runsvdir /etc/service
#    --mount type=volume,source=pg_arclog,destination=/var/lib/postgresql/pg_arclog \
