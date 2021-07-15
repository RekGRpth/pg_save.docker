FROM alpine:3.13
ENV HOME=/var/lib/postgresql
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
    mkdir -p "${HOME}"; \
    cd "${HOME}"; \
    git clone --recursive https://github.com/RekGRpth/pg_async.git; \
    git clone --recursive https://github.com/RekGRpth/pg_save.git; \
    find "${HOME}" -maxdepth 1 -mindepth 1 -type d | sort -u | while read -r NAME; do echo "$NAME" && cd "$NAME" && make -j"$(nproc)" USE_PGXS=1 install || exit 1; done; \
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
    find /usr/local/bin /usr/local/lib -type f -exec strip '{}' \;; \
    apk del --no-cache .build-deps; \
    find / -type f -name "*.a" -delete; \
    find / -type f -name "*.la" -delete; \
    rm -rf "${HOME}" /usr/share/doc /usr/share/man /usr/local/share/doc /usr/local/share/man; \
    echo done
CMD [ "/etc/service/postgres/run" ]
COPY bin /usr/local/bin
COPY service /etc/service
ENTRYPOINT [ "docker_entrypoint.sh" ]
ENV ARCLOG=../arclog \
    GROUP=postgres \
    PGDATA=data \
    USER=postgres
VOLUME "${HOME}"
WORKDIR "${HOME}"
RUN set -eux; \
    chmod -R 0755 /etc/service /usr/local/bin; \
    rm -f /var/spool/cron/crontabs/root; \
    echo done
