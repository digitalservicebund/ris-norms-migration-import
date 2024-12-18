#!/bin/sh
set -euf

# Load secrets
export PGUSER="${PGUSER:=$(cat /etc/secrets/database-credentials/user)}"
export PGPASSWORD="${PGPASSWORD:=$(cat /etc/secrets/database-credentials/password)}"

echo "PGUSER=$PGUSER"
echo "MIGRATION_STATS_SCHEMA=$MIGRATION_STATS_SCHEMA"

LATEST_SUCCESSFUL_RUN="$(psql --tuples-only --csv --command="SELECT created_at FROM $MIGRATION_STATS_SCHEMA.migration_stats ORDER BY created_at DESC LIMIT 1")"
LATEST_SUCCESSFUL_RUN_DATE="${LATEST_SUCCESSFUL_RUN:0:10}"

CURRENT_DATE="$(date "+%Y-%m-%d")"

if [[ "$LATEST_SUCCESSFUL_RUN_DATE" != "$CURRENT_DATE" ]]; then
  echo "NORMS_SCHEMA=$NORMS_SCHEMA"
  echo "MIGRATION_SCHEMA=$MIGRATION_SCHEMA"
  psql --echo-all --variable=NORMS_SCHEMA=$NORMS_SCHEMA --variable=MIGRATION_SCHEMA=$MIGRATION_SCHEMA --file=./import_from_migration.sql
else
  echo "Found no successful migration that finished today. Last successful run date: $LATEST_SUCCESSFUL_RUN. Today: $CURRENT_DATE"
fi
