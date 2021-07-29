#!/bin/sh -eux

docker pull ghcr.io/rekgrpth/pg_save.docker
NAME=pg_save2
NETWORK=docker
docker network create --attachable --opt "com.docker.network.bridge.name=$NETWORK" "$NETWORK" || echo $?
docker volume create pg_arclog
docker volume create "$NAME"
docker stop "$NAME" || echo $?
docker rm "$NAME" || echo $?
docker run \
    --detach \
    --env CLUSTER_NAME=save \
    --env GROUP_ID="$(id -g)" \
    --env LANG=ru_RU.UTF-8 \
    --env PRIMARY_CONNINFO="host=pg_save1.$NETWORK,pg_save2.$NETWORK,pg_save3.$NETWORK application_name=$NAME.$NETWORK target_session_attrs=read-write" \
    --env SYNCHRONOUS_STANDBY_NAMES="FIRST 1 (\"pg_save1.$NETWORK\", \"pg_save2.$NETWORK\", \"pg_save3.$NETWORK\")" \
    --env TZ=Asia/Yekaterinburg \
    --env USER_ID="$(id -u)" \
    --hostname "$NAME.$NETWORK" \
    --mount type=bind,source=/etc/certs,destination=/etc/certs,readonly \
    --mount type=volume,source=pg_arclog,destination=/var/lib/postgresql/arclog \
    --mount type="volume,source=$NAME,destination=/var/lib/postgresql" \
    --name "$NAME" \
    --network name="$NETWORK" \
    --restart always \
    ghcr.io/rekgrpth/pg_save.docker runsvdir /etc/service
