FROM alpine
RUN exec 2>&1 \
    && set -ex \
    && echo https://mirror.yandex.ru/mirrors/alpine/v3.13/main/ > /etc/apk/repositories \
    && echo https://mirror.yandex.ru/mirrors/alpine/v3.13/community/ >> /etc/apk/repositories \
    && apk add --no-cache --virtual .build-deps \
        gcc \
        git \
        libedit-dev \
        libunwind-dev \
        libxml2-dev \
        make \
        musl-dev \
        postgresql-dev \
        zlib-dev \
    && mkdir -p /usr/src \
    && cd /usr/src \
    && git clone --recursive https://github.com/RekGRpth/pg_backtrace.git \
    && git clone --recursive https://github.com/RekGRpth/pg_save.git \
    && cd / \
    && find /usr/src -maxdepth 1 -mindepth 1 -type d | sort -u | while read -r NAME; do echo "$NAME" && cd "$NAME" && make -j"$(nproc)" USE_PGXS=1 install || exit 1; done \
    && apk add --no-cache --virtual .postgresql-rundeps \
        busybox-extras \
        busybox-suid \
        ca-certificates \
        jq \
        musl-locales \
        postgresql \
        postgresql-contrib \
        procps \
        runit \
        sed \
        shadow \
        tzdata \
        $(scanelf --needed --nobanner --format '%n#p' --recursive /usr/lib/postgresql/pg_backtrace.so /usr/lib/postgresql/pg_save.so | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }') \
    && apk del --no-cache .build-deps \
    && rm -rf /usr/src /usr/share/doc /usr/share/man /usr/local/share/doc /usr/local/share/man \
    && echo done
ADD bin /usr/local/bin
ADD service /etc/service
CMD [ "/etc/service/postgres/run" ]
ENTRYPOINT [ "docker_entrypoint.sh" ]
ENV HOME=/var/lib/postgresql
ENV GROUP=postgres \
    PGDATA="${HOME}/pg_data" \
    USER=postgres
VOLUME "${HOME}"
WORKDIR "${HOME}"
RUN exec 2>&1 \
    && set -ex \
    && chmod -R 0755 /etc/service /usr/local/bin \
    && rm -f /var/spool/cron/crontabs/root \
    && echo done
