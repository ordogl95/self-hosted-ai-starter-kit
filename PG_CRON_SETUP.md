# pg_cron Extension Setup Guide

This guide explains how to use the pg_cron extension with your PostgreSQL database in Docker.

## Overview

pg_cron is a PostgreSQL extension that allows you to schedule SQL commands directly from PostgreSQL. It works similarly to cron on Unix systems, enabling you to run queries on a schedule.

**Repository:** https://github.com/citusdata/pg_cron

## Files Created

- **`Dockerfile.postgres`** - Custom PostgreSQL image with pg_cron built and installed
- **`init-pg-cron.sql`** - Initialization script that creates the pg_cron extension on database startup
- **`docker-compose.yml`** - Updated to build the custom PostgreSQL image

## Setup Instructions

### 1. Build the Custom PostgreSQL Image

The `docker-compose.yml` has been updated to build a custom PostgreSQL image instead of using the standard image. The build process will:

- Install pg_cron source code and dependencies
- Compile pg_cron extension
- Initialize the extension when the container starts

### 2. Start the Containers

```bash
# Start all services with the custom PostgreSQL image
docker-compose up -d

# Or with a specific profile (e.g., for CPU)
docker-compose --profile cpu up -d
```

The first startup may take longer due to building the custom image and compiling pg_cron.

### 3. Verify pg_cron Installation

Once the database is running, connect to PostgreSQL and verify the extension is loaded:

```bash
# Using psql inside the container
docker exec -it postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "CREATE EXTENSION IF NOT EXISTS pg_cron;"

# Or verify it's already created
docker exec -it postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT * FROM pg_extension WHERE extname = 'pg_cron';"
```

Or through pgAdmin:
1. Go to http://localhost:5050
2. Connect to the postgres server
3. Open the Query Tool
4. Run: `SELECT * FROM pg_extension WHERE extname = 'pg_cron';`

## Using pg_cron

### Basic Syntax

```sql
-- Schedule a job
SELECT cron.schedule('job-name', 'schedule', 'SQL command');

-- Example: Run a query every hour
SELECT cron.schedule('hourly-job', '0 * * * *', 'SELECT 1;');

-- Example: Run a query every day at 2 AM
SELECT cron.schedule('daily-job', '0 2 * * *', 'DELETE FROM old_logs WHERE created_at < NOW() - INTERVAL ''7 days'';');

-- List all scheduled jobs
SELECT * FROM cron.job;

-- Remove a job
SELECT cron.unschedule('job-name');
```

### Time Format

pg_cron uses standard cron format:

```
 ┌───────────── min (0 - 59)
 │ ┌───────────── hour (0 - 23)
 │ │ ┌───────────── day of month (1 - 31)
 │ │ │ ┌───────────── month (1 - 12)
 │ │ │ │ ┌───────────── day of week (0 - 6) (0 = Sunday)
 │ │ │ │ │
 │ │ │ │ │
 * * * * *
```

### Common Examples

```sql
-- Every minute
SELECT cron.schedule('every-minute', '* * * * *', 'your_sql_here');

-- Every 5 minutes
SELECT cron.schedule('every-5-min', '*/5 * * * *', 'your_sql_here');

-- Every hour at minute 0
SELECT cron.schedule('every-hour', '0 * * * *', 'your_sql_here');

-- Every day at midnight
SELECT cron.schedule('every-day', '0 0 * * *', 'your_sql_here');

-- Every Monday at 9 AM
SELECT cron.schedule('every-monday', '0 9 * * 1', 'your_sql_here');

-- First day of each month at 1 AM
SELECT cron.schedule('monthly', '0 1 1 * *', 'your_sql_here');
```

## Troubleshooting

### Extension Not Found

If you get an error about pg_cron not being found:

1. Verify the build completed successfully:
   ```bash
   docker-compose logs postgres | grep -i "pg_cron\|error"
   ```

2. Rebuild the image:
   ```bash
   docker-compose down -v
   docker-compose build --no-cache postgres
   docker-compose up -d postgres
   ```

### Build Failures

If the Docker build fails:

1. Check disk space is available
2. Ensure you have internet connectivity for cloning the pg_cron repository
3. Check logs:
   ```bash
   docker-compose build postgres --progress=plain
   ```

### Permission Issues

If you get permission errors when running queries:

```sql
-- Grant schema permissions if needed
GRANT USAGE ON SCHEMA cron TO your_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA cron TO your_user;
```

## Performance Considerations

- pg_cron jobs run in the PostgreSQL server process
- Long-running jobs may impact database performance
- Monitor job execution time and optimize queries accordingly
- Use `cron.job_cache_size` GUC parameter to control the number of cached jobs (default: 32)

## Security Notes

- pg_cron jobs run with the permissions of the database user that created them
- Only superusers can create jobs in the cluster-specific schedule (the default `cron` schema)
- Consider creating dedicated database users with limited permissions for specific jobs

## Useful Resources

- **Official pg_cron Documentation:** https://github.com/citusdata/pg_cron
- **PostgreSQL cron Format:** https://linux.die.net/man/5/crontab
- **Online Cron Expression Generator:** https://crontab.guru/

## Next Steps

1. Test pg_cron by creating a simple scheduled job
2. Set up monitoring/alerting for job failures
3. Plan your regular maintenance tasks to run via pg_cron
4. Review security and permissions for different jobs

Enjoy automated database maintenance with pg_cron! 🚀
