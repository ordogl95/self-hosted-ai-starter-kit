CREATE OR REPLACE FUNCTION export_workflows_to_json()
RETURNS void AS $$
DECLARE
    v_workflow RECORD;
    v_json_data jsonb;
    v_file_path text;
    v_filename text;
BEGIN
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
        
        -- Create filename with workflow name, date and time (YYYY-MM-DD_HH-MM-SS format)
        -- Replace spaces and special characters in name with underscores
        -- NOW() is called fresh for each iteration to capture actual export time
        v_filename := regexp_replace(v_workflow.name, '[^a-zA-Z0-9_-]', '_', 'g') || '_' || to_char(NOW(), 'YYYY-MM-DD_HH-MM-SS') || '.json';
        v_file_path := '/workflows/' || v_filename;
        
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
