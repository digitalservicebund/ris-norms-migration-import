#!/bin/sh
set -euf

# We have a problem that the connection to the database runs into a timeout during our long running sql script.
# To prevent this we run a simple query every 10 minutes.

export PGUSER="${PGUSER:=$(cat /etc/secrets/database-credentials/user)}"
export PGPASSWORD="${PGPASSWORD:=$(cat /etc/secrets/database-credentials/password)}"
export PGHOST="${PGHOST:=$(cat /etc/secrets/database-credentials/host)}"

while true; do
    sleep 300
    psql --tuples-only --csv --command="SELECT MAX(created_at AT TIME ZONE 'UTC') FROM ${NORMS_SCHEMA}.migration_log"
done
