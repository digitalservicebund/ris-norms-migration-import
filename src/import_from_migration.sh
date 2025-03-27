#!/bin/sh
set -euf

# Load secrets
export PGUSER="${PGUSER:=$(cat /etc/secrets/database-credentials/user)}"
export PGPASSWORD="${PGPASSWORD:=$(cat /etc/secrets/database-credentials/password)}"

echo "PGUSER=$PGUSER"
echo "MIGRATION_STATS_SCHEMA=$MIGRATION_STATS_SCHEMA"

psql --echo-all --variable=NORMS_SCHEMA=$NORMS_SCHEMA --variable=MIGRATION_SCHEMA=$MIGRATION_SCHEMA --file=./import_from_migration.sql
