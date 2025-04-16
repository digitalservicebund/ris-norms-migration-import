#!/bin/sh
set -euf

# Load secrets
export PGUSER="${PGUSER:=$(cat /etc/secrets/database-credentials/user)}"
export PGPASSWORD="${PGPASSWORD:=$(cat /etc/secrets/database-credentials/password)}"

echo "PGUSER=$PGUSER"
echo "MIGRATION_STATS_SCHEMA=$MIGRATION_STATS_SCHEMA"

# Check if there are any jobs in progress
JOBS_IN_PROGRESS=$(psql --tuples-only --csv --command="SELECT COUNT(*) FROM $MIGRATION_STATS_SCHEMA.job_in_progress")
# Get date of last norms migration log and cast to UTC (because date is timestamptz) - trimming in case the --tuples-only --csv includes an unexpected newline character
LATEST_NORMS_LOG=$(psql --tuples-only --csv --command="SELECT MAX(created_at AT TIME ZONE 'UTC') FROM ${NORMS_SCHEMA}.migration_log" | tr -d '[:space:]')
# Get date of last migration (it is already UTC) - trimming in case the --tuples-only --csv includes an unexpected newline character
LATEST_STATS=$(psql --tuples-only --csv --command="SELECT MAX(created_at) FROM ${MIGRATION_STATS_SCHEMA}.migration_stats" | tr -d '[:space:]')

echo "JOBS_IN_PROGRESS=$JOBS_IN_PROGRESS"
echo "LATEST_NORMS_LOG=$LATEST_NORMS_LOG"
echo "LATEST_STATS=$LATEST_STATS"

# Only proceed if migration_stats is present
if [ -n "$LATEST_STATS" ]; then
  # If no jobs in progress AND (no migration_log OR migration_log is older than migration_stats)
  if [ "$JOBS_IN_PROGRESS" -eq 0 ] && { [ -z "$LATEST_NORMS_LOG" ] || [ "$LATEST_NORMS_LOG" \< "$LATEST_STATS" ]; }; then
    echo "No jobs in progress and migration needed. Running norms migration job..."
    echo "NORMS_SCHEMA=$NORMS_SCHEMA"
    echo "MIGRATION_SCHEMA=$MIGRATION_SCHEMA"
    psql --echo-all --variable=NORMS_SCHEMA=$NORMS_SCHEMA --variable=MIGRATION_SCHEMA=$MIGRATION_SCHEMA --file=./import_from_migration.sql
  else
    echo "Migration not needed or jobs in progress. Skipping."
  fi
else
  echo "No migration stats found. Skipping execution."
fi
