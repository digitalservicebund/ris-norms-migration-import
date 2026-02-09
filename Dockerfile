FROM  cgr.dev/chainguard/wolfi-base:latest

RUN apk update \
    && apk add --no-cache --update-cache postgresql-14-client;

COPY src/import_from_migration.sql /import_from_migration.sql
COPY src/keep_alive.sh /keep_alive.sh
COPY --chmod=555 src/import_from_migration.sh /import_from_migration.sh

CMD ["/import_from_migration.sh"]
