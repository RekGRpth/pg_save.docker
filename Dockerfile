FROM alpine
ARG POSTGRES_VERSION=14
ENV HOME=/var/lib/postgresql
RUN set -eux; \
    apk update --no-cache; \
    apk upgrade --no-cache; \
    apk add --no-cache --virtual .build-deps \
        gcc \
        git \
        libedit-dev \
        libxml2-dev \
        make \
        musl-dev \
        "postgresql${POSTGRES_VERSION}" \
        "postgresql${POSTGRES_VERSION}-dev" \
        readline-dev \
        zlib-dev \
    ; \
    export PATH="/usr/libexec/postgresql${POSTGRES_VERSION}:${PATH}"; \
    mkdir -p "${HOME}/src"; \
    cd "${HOME}/src"; \
#    git clone -b master https://github.com/RekGRpth/pg_async.git; \
    git clone -b master https://github.com/RekGRpth/pg_save.git; \
    find "${HOME}/src" -maxdepth 1 -mindepth 1 -type d | sort -u | while read -r NAME; do echo "$NAME" && cd "$NAME" && make -j"$(nproc)" USE_PGXS=1 install || exit 1; done; \
    cd /; \
    apk add --no-cache --virtual .postgresql-rundeps \
        busybox-extras \
        busybox-suid \
        ca-certificates \
        dateutils \
        jq \
        musl-locales \
        openssh-client \
        "postgresql${POSTGRES_VERSION}" \
        "postgresql${POSTGRES_VERSION}-client" \
        "postgresql${POSTGRES_VERSION}-contrib" \
#        "postgresql${POSTGRES_VERSION}-contrib-jit" \
#        "postgresql${POSTGRES_VERSION}-jit" \
        procps \
        runit \
        sed \
        shadow \
        tzdata \
        $(scanelf --needed --nobanner --format '%n#p' --recursive /usr/local | tr ',' '\n' | sort -u | while read -r lib; do test ! -e "/usr/local/lib/$lib" && echo "so:$lib"; done) \
        $(scanelf --needed --nobanner --format '%n#p' --recursive "/usr/lib/postgresql${POSTGRES_VERSION}" | tr ',' '\n' | sort -u | while read -r lib; do test ! -e "/usr/local/lib/$lib" && echo "so:$lib"; done) \
    ; \
    find /usr/local/bin -type f -exec strip '{}' \;; \
    find /usr/local/lib -type f -name "*.so" -exec strip '{}' \;; \
    apk del --no-cache .build-deps; \
    find /usr -type f -name "*.a" -delete; \
    find /usr -type f -name "*.la" -delete; \
    rm -rf "${HOME}" /usr/share/doc /usr/share/man /usr/local/share/doc /usr/local/share/man; \
    echo done
ADD bin /usr/local/bin
ADD service /etc/service
CMD [ "/etc/service/postgres/run" ]
ENTRYPOINT [ "docker_entrypoint.sh" ]
ENV ARCLOG=../arc \
    GROUP=postgres \
    PGDATA="${HOME}/data" \
    USER=postgres
WORKDIR "${HOME}"
RUN set -eux; \
    chmod -R 0755 /etc/service /usr/local/bin; \
    rm -f /var/spool/cron/crontabs/root; \
    echo done
