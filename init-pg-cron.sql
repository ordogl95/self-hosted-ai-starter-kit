-- Initialize n8n database and pg_cron extension
-- This script is automatically executed when the PostgreSQL container starts
-- Note: pg_cron requires shared_preload_libraries configuration

-- Create n8n database (it should already exist from docker-compose, but ensure it exists)
CREATE DATABASE n8n OWNER root;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE n8n TO root;
