# PostgreSQL pg_cron Workflow Export Setup

## Overview

A pg_cron task has been configured to automatically export all n8n workflows from the PostgreSQL database to JSON files in the `n8n/demo-data/workflows/` directory.

## Configuration Details

### Schedule
- **Job Name:** `export_n8n_workflows_daily`
- **Schedule:** `0 2 * * *` (Daily at 2:00 AM UTC)
- **Status:** Active ✅

### Export Function
- **Function Name:** `export_workflows_to_json()`
- **Location:** PostgreSQL database (n8n)
- **Purpose:** Exports all workflows from `workflow_entity` table to JSON files

### File Output
- **Output Directory:** `/workflows` (mounted to `n8n/demo-data/workflows/`)
- **File Format:** `{workflow_id}.json`
- **Format:** JSON matching n8n workflow export format

## Query to View Job Status

```sql
SELECT jobid, jobname, schedule, command, active 
FROM cron.job 
WHERE jobname = 'export_n8n_workflows_daily';
```

## Manual Workflow Export

To manually trigger a workflow export without waiting for the scheduled time:

```bash
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d n8n -c "SELECT export_workflows_to_json();"
```

## Modifying the Schedule

To change the export schedule, use one of these formats:

### Every hour at minute 0
```sql
SELECT cron.unschedule('export_n8n_workflows_daily');
SELECT cron.schedule('export_n8n_workflows_daily', '0 * * * *', 'SELECT export_workflows_to_json();');
```

### Every 6 hours
```sql
SELECT cron.unschedule('export_n8n_workflows_daily');
SELECT cron.schedule('export_n8n_workflows_daily', '0 */6 * * *', 'SELECT export_workflows_to_json();');
```

### Every 12 hours
```sql
SELECT cron.unschedule('export_n8n_workflows_daily');
SELECT cron.schedule('export_n8n_workflows_daily', '0 */12 * * *', 'SELECT export_workflows_to_json();');
```

### Cron Format Reference
```
┌───────────── min (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (0 = Sunday)
│ │ │ │ │
* * * * *
```

## Files Modified/Created

1. **docker-compose.yml**
   - Added volume mount: `./n8n/demo-data/workflows:/workflows` to postgres container

2. **Dockerfile.postgres**
   - Added copy of: `init-pg-cron-workflow-export.sql` to docker-entrypoint-initdb.d

3. **init-pg-cron-extension.sql**
   - Enhanced with workflow export function and job scheduling

4. **init-pg-cron.sql**
   - Fixed CREATE DATABASE syntax (removed unsupported IF NOT EXISTS)

5. **init-pg-cron-workflow-export.sql** (new)
   - Standalone script with export function (for reference)

## Troubleshooting

### Check if pg_cron extension is installed
```bash
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d n8n -c "SELECT * FROM pg_extension WHERE extname = 'pg_cron';"
```

### View all scheduled cron jobs
```bash
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d n8n -c "SELECT * FROM cron.job;"
```

### Check Docker logs for cron execution
```bash
docker logs self-hosted-ai-starter-kit-postgres-1 | grep -i "cron\|export"
```

### Manually run the export function with output
```bash
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d n8n << 'EOF'
SELECT export_workflows_to_json();
EOF
```

## How It Works

1. The pg_cron scheduler (running as a PostgreSQL background worker) checks for scheduled jobs
2. When 2:00 AM UTC arrives, the job executes: `SELECT export_workflows_to_json();`
3. The `export_workflows_to_json()` function:
   - Queries all workflows from the `workflow_entity` table
   - Constructs proper n8n JSON format for each workflow
   - Exports each workflow to `/workflows/{workflow_id}.json`
   - Logs each export operation

## Notes

- The export function gracefully handles errors and logs warnings if the workflow_entity table doesn't exist (e.g., on initial setup before n8n creates tables)
- Files are overwritten on each export cycle
- Directory permissions must allow the postgresql user to write files
- Ensure sufficient disk space in the `n8n/demo-data/workflows/` directory for workflow backups
