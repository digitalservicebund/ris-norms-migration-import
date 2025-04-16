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

# Optional: Fallbacks in case the queries return nothing (to avoid issues in comparison)
: "${LATEST_NORMS_LOG:=0000-01-01 00:00:00}"
: "${LATEST_STATS:=0000-01-01 00:00:00}"

echo "JOBS_IN_PROGRESS=$JOBS_IN_PROGRESS"
echo "LATEST_NORMS_LOG=$LATEST_NORMS_LOG"
echo "LATEST_STATS=$LATEST_STATS"

# Only if no jobs are in progress AND the latest migration log is older than the latest migration stats (lexicographic comparison using string UTC representations)
if [ "$JOBS_IN_PROGRESS" -eq 0 ] && [ "$LATEST_NORMS_LOG" \< "$LATEST_STATS" ]; then
  echo "No jobs in progress. Running norms migration job..."
  echo "NORMS_SCHEMA=$NORMS_SCHEMA"
  echo "MIGRATION_SCHEMA=$MIGRATION_SCHEMA"
  psql --echo-all --variable=NORMS_SCHEMA=$NORMS_SCHEMA --variable=MIGRATION_SCHEMA=$MIGRATION_SCHEMA --file=./import_from_migration.sql
else
  echo "Jobs are still in progress. Skipping running norms migration job."
fi
