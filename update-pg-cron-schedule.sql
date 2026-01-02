-- Update the pg_cron job schedule to run every 2 minutes

-- Delete existing job if it exists
DO $$
BEGIN
    PERFORM cron.unschedule('export_n8n_workflows_daily');
EXCEPTION WHEN OTHERS THEN
    -- Ignore if job doesn't exist
END $$;

-- Schedule the job to run every 2 minutes
-- Format: '*/2 * * * *' = every 2 minutes
SELECT cron.schedule(
    'export_n8n_workflows_daily',
    '*/2 * * * *',
    'SELECT export_workflows_to_json();'
);

RAISE NOTICE 'pg_cron workflow export job schedule updated to every 2 minutes';
