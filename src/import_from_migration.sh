#!/bin/sh
set -euf

# Load secrets
export PGUSER="${PGUSER:=$(cat /etc/secrets/database-credentials/user)}"
export PGPASSWORD="${PGPASSWORD:=$(cat /etc/secrets/database-credentials/password)}"

echo "PGUSER=$PGUSER"
echo "MIGRATION_STATS_SCHEMA=$MIGRATION_STATS_SCHEMA"

# Check if there are any jobs in progress
JOBS_IN_PROGRESS=$(psql --tuples-only --csv --command="SELECT COUNT(*) FROM $MIGRATION_STATS_SCHEMA.job_in_progress")

if [ "$JOBS_IN_PROGRESS" -eq 0 ]; then
  echo "No jobs in progress. Running norms migration job..."
  echo "NORMS_SCHEMA=$NORMS_SCHEMA"
  echo "MIGRATION_SCHEMA=$MIGRATION_SCHEMA"
  psql --echo-all --variable=NORMS_SCHEMA=$NORMS_SCHEMA --variable=MIGRATION_SCHEMA=$MIGRATION_SCHEMA --file=./import_from_migration.sql
else
  echo "Jobs are still in progress. Skipping running norms migration job."
fi
