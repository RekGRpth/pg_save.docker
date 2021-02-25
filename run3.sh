#!/bin/sh -ex

docker network create --attachable --opt com.docker.network.bridge.name=docker docker || echo $?
docker volume create pg_save3
docker stop pg_save3 || echo $?
docker rm pg_save3 || echo $?
docker run \
    --detach \
    --env CLUSTER_NAME=save \
    --env ETCD_ADVERTISE_CLIENT_URLS=http://pg_save3:2379 \
    --env ETCD_DATA_DIR=/var/lib/postgresql/pg_save \
    --env ETCD_INITIAL_ADVERTISE_PEER_URLS=http://pg_save3:2380 \
    --env ETCD_INITIAL_CLUSTER=pg_save1=http://pg_save1:2380,pg_save2=http://pg_save2:2380,pg_save3=http://pg_save3:2380 \
    --env ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379 \
    --env ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380 \
    --env ETCD_NAME=pg_save3 \
    --env GROUP_ID="$(id -g)" \
    --env LANG=ru_RU.UTF-8 \
    --env TZ=Asia/Yekaterinburg \
    --env USER_ID="$(id -u)" \
    --hostname pg_save3 \
    --mount type=bind,source=/etc/certs,destination=/etc/certs,readonly \
    --mount type=volume,source=pg_save3,destination=/var/lib/postgresql \
    --name pg_save3 \
    --network name=docker \
    --restart always \
    rekgrpth/pg_save
#    --env ETCD_CERT_FILE=file \
#    --env ETCD_INITIAL_CLUSTER_STATE=new \
#    --env ETCD_INITIAL_CLUSTER_TOKEN=pg_save_token \
#    --env ETCD_KEY_FILE=file \
#    --env ETCD_PEER_CERT_FILE=file \
#    --env ETCD_PEER_KEY_FILE=file \
#    --env ETCD_PEER_TRUSTED_CA_FILE=file \
#    --env ETCD_TRUSTED_CA_FILE=file \
