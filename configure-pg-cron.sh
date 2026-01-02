#!/bin/bash
set -e

# Wait for PostgreSQL to be ready
until pg_isready -U "$POSTGRES_USER" -d postgres; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

# Add pg_cron configuration to postgresql.conf if not already present
if ! grep -q "shared_preload_libraries.*pg_cron" "$PGDATA/postgresql.conf"; then
  echo "shared_preload_libraries = 'pg_cron'" >> "$PGDATA/postgresql.conf"
  echo "cron.database_name = 'n8n'" >> "$PGDATA/postgresql.conf"
  echo "pg_cron configuration added to postgresql.conf"
fi
