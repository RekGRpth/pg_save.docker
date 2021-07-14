FROM alpine:3.13
RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
        gcc \
        git \
        libedit-dev \
        libxml2-dev \
        make \
        musl-dev \
        postgresql-dev \
        readline-dev \
        zlib-dev \
    ; \
    mkdir -p /usr/src; \
    cd /usr/src; \
    git clone --recursive https://github.com/RekGRpth/pg_async.git; \
    git clone --recursive https://github.com/RekGRpth/pg_save.git; \
    cd /; \
    find /usr/src -maxdepth 1 -mindepth 1 -type d | sort -u | while read -r NAME; do echo "$NAME" && cd "$NAME" && make -j"$(nproc)" USE_PGXS=1 install || exit 1; done; \
    apk add --no-cache --virtual .postgresql-rundeps \
        busybox-extras \
        busybox-suid \
        ca-certificates \
        dateutils \
        musl-locales \
        postgresql \
        postgresql-contrib \
        procps \
        runit \
        sed \
        shadow \
        tzdata \
        $(scanelf --needed --nobanner --format '%n#p' --recursive /usr/lib/postgresql/* | tr ',' '\n' | sort -u | while read -r lib; do test ! -e "/usr/local/lib/$lib" && echo "so:$lib"; done) \
    ; \
    (strip /usr/local/bin/* /usr/local/lib/*.so || true); \
    apk del --no-cache .build-deps; \
    rm -rf /usr/src /usr/share/doc /usr/share/man /usr/local/share/doc /usr/local/share/man; \
    find / -name "*.a" -delete; \
    find / -name "*.la" -delete; \
    echo done
ADD bin /usr/local/bin
ADD service /etc/service
CMD [ "/etc/service/postgres/run" ]
ENTRYPOINT [ "docker_entrypoint.sh" ]
ENV HOME=/var/lib/postgresql
ENV ARCLOG=../arclog \
    GROUP=postgres \
    PGDATA="data" \
    USER=postgres
VOLUME "${HOME}"
WORKDIR "${HOME}"
RUN set -eux; \
    chmod -R 0755 /etc/service /usr/local/bin; \
    rm -f /var/spool/cron/crontabs/root; \
    echo done
