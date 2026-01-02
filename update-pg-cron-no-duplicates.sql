-- Update the export_workflows_to_json function to use workflow ID in filename
-- This prevents duplicate files by always updating the same file for each workflow

CREATE OR REPLACE FUNCTION export_workflows_to_json()
RETURNS void AS $$
DECLARE
    v_workflow RECORD;
    v_json_data jsonb;
    v_file_path text;
    v_filename text;
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
        
        -- Create filename with workflow ID to ensure same workflow updates the same file (no duplicates)
        -- Format: {workflow_id}_{workflow_name}.json
        -- Replace spaces and special characters in name with underscores
        v_filename := v_workflow.id || '_' || regexp_replace(v_workflow.name, '[^a-zA-Z0-9_-]', '_', 'g') || '.json';
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
