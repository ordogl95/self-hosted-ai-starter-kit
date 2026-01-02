-- Create pg_cron extension in n8n database
-- This script runs AFTER the n8n database is created

-- First, ensure pg_cron is created in the postgres database (default)
-- This is required as a fallback in case cron.database_name config isn't loaded yet
\c postgres
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Now connect to n8n database and create extension there
\c n8n
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Verify extension was created in n8n
SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_cron' AND nspname = 'cron';

-- Grant usage on cron schema to application user
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    GRANT USAGE ON SCHEMA cron TO PUBLIC;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA cron TO PUBLIC;
    RAISE NOTICE 'pg_cron permissions granted successfully';
  END IF;
END $$;

-- ===================================================
-- Setup pg_cron job for automatic workflow export ===
-- ===================================================

-- Create a helper function to export workflows to JSON files
CREATE OR REPLACE FUNCTION export_workflows_to_json()
RETURNS void AS $$
DECLARE
    v_workflow RECORD;
    v_json_data jsonb;
    v_file_path text;
    v_filename text;
    v_workflow_name_safe text;
    v_cmd text;
BEGIN
    -- Loop through all workflows in the database
    FOR v_workflow IN 
        SELECT 
            id, 
            name, 
            active, 
            nodes, 
            connections, 
            "createdAt",
            "updatedAt",
            settings,
            "staticData",
            "pinData",
            "versionId",
            "triggerCount",
            meta
        FROM workflow_entity
        ORDER BY "createdAt" DESC
    LOOP
        -- Construct the JSON object matching n8n workflow format
        v_json_data := jsonb_build_object(
            'createdAt', (v_workflow."createdAt")::text,
            'updatedAt', (v_workflow."updatedAt")::text,
            'id', v_workflow.id,
            'name', v_workflow.name,
            'active', v_workflow.active,
            'nodes', v_workflow.nodes::jsonb,
            'connections', v_workflow.connections::jsonb,
            'settings', COALESCE(v_workflow.settings::jsonb, '{}'::jsonb),
            'staticData', v_workflow."staticData"::jsonb,
            'meta', COALESCE(v_workflow.meta::jsonb, '{}'::jsonb),
            'pinData', COALESCE(v_workflow."pinData"::jsonb, '{}'::jsonb),
            'versionId', v_workflow."versionId",
            'triggerCount', v_workflow."triggerCount",
            'tags', '[]'::jsonb
        );
        
        -- Create safe workflow name for file operations
        v_workflow_name_safe := regexp_replace(v_workflow.name, '[^a-zA-Z0-9_-]', '_', 'g');
        
        -- Delete all old files for this workflow to prevent duplicates
        -- This removes any previously exported versions of this workflow
        v_cmd := 'rm /workflows/' || v_workflow_name_safe || '_*.json 2>/dev/null || true';
        EXECUTE format('COPY (SELECT %L::text) TO PROGRAM %L', '', v_cmd);
        
        -- Create filename with workflow name and updatedAt timestamp (YYYY-MM-DD_HH-MI-SS format)
        -- Using the workflow's updatedAt field converted to Budapest local timezone
        -- Replace spaces and special characters in name with underscores
        v_filename := v_workflow_name_safe || '_' || to_char(v_workflow."updatedAt" AT TIME ZONE 'Europe/Budapest', 'YYYY-MM-DD_HH24-MI-SS') || '.json';
        v_file_path := '/workflows/' || v_filename;
        
        -- Write the JSON to file using PostgreSQL's COPY command
        EXECUTE format('
            COPY (
                SELECT %L::text
            ) TO %L
        ', v_json_data::text, v_file_path);
        
        RAISE NOTICE 'Exported workflow: % -> %', v_workflow.name, v_filename;
    END LOOP;
    
    RAISE NOTICE 'Workflow export completed successfully';
    
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error exporting workflows: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION export_workflows_to_json() TO PUBLIC;

-- Schedule the pg_cron job to run every 2 minutes
-- Format: '*/2 * * * *' = every 2 minutes, every hour, every day, every month, every day of week
DO $$
BEGIN
    -- Delete existing job if it exists
    PERFORM cron.unschedule('export_n8n_workflows_daily');
EXCEPTION WHEN OTHERS THEN
    -- Ignore if job doesn't exist
END $$;

SELECT cron.schedule(
    'export_n8n_workflows_daily',
    '*/2 * * * *',
    'SELECT export_workflows_to_json();'
);

RAISE NOTICE 'pg_cron workflow export job scheduled successfully (every 2 minutes)';
