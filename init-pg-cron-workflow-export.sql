-- Setup pg_cron job for automatic workflow export
-- This script creates a pg_cron task that exports all workflows from n8n database
-- to JSON files in the /workflows directory

-- Connect to n8n database (note: this may not work in init scripts, ensure we're in n8n db)

-- Create a helper function to export workflows to JSON files
CREATE OR REPLACE FUNCTION export_workflows_to_json()
RETURNS void AS $$
DECLARE
    v_workflow RECORD;
    v_json_data jsonb;
    v_file_path text;
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
            'nodes', v_workflow.nodes,
            'connections', v_workflow.connections,
            'settings', COALESCE(v_workflow.settings, '{}'::jsonb),
            'staticData', v_workflow."staticData",
            'meta', COALESCE(v_workflow.meta, '{}'::jsonb),
            'pinData', COALESCE(v_workflow."pinData", '{}'::jsonb),
            'versionId', v_workflow."versionId",
            'triggerCount', v_workflow."triggerCount",
            'tags', '[]'::jsonb
        );
        
        -- Set the file path for this workflow
        v_file_path := '/workflows/' || v_workflow.id || '.json';
        
        -- Write the JSON to file using PostgreSQL's COPY command
        EXECUTE format('
            COPY (
                SELECT %L::text
            ) TO %L
        ', v_json_data::text, v_file_path);
        
        RAISE NOTICE 'Exported workflow: % (%)', v_workflow.name, v_workflow.id;
    END LOOP;
    
    RAISE NOTICE 'Workflow export completed successfully';
    
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error exporting workflows: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to the postgres user
GRANT EXECUTE ON FUNCTION export_workflows_to_json() TO PUBLIC;

-- Create the pg_cron job to run the export function
-- Schedule: Every day at 2 AM (02:00:00)
-- Format: minute hour day month day_of_week
SELECT cron.schedule(
    'export_n8n_workflows_daily',
    '0 2 * * *',
    'SELECT export_workflows_to_json();'
);

-- Alternatively, you can use different schedules:
-- Every hour at minute 0:
-- SELECT cron.schedule('export_n8n_workflows_hourly', '0 * * * *', 'SELECT export_workflows_to_json();');
-- 
-- Every 12 hours:
-- SELECT cron.schedule('export_n8n_workflows_12h', '0 */12 * * *', 'SELECT export_workflows_to_json();');
--
-- Every 6 hours:
-- SELECT cron.schedule('export_n8n_workflows_6h', '0 */6 * * *', 'SELECT export_workflows_to_json();');
--
-- Every new hour:
-- SELECT cron.schedule('export_n8n_workflows_hourly', '0 * * * *', 'SELECT export_workflows_to_json();');

-- List all scheduled jobs to verify
SELECT * FROM cron.job;

-- Optional: Create a manual export function for testing
-- Run this function manually to test the export:
-- SELECT export_workflows_to_json();
