-- ==============================================================================
-- PostgreSQL Initialization Script for SVB Webstack
-- ==============================================================================
-- This script is automatically run when the PostgreSQL container starts
-- for the first time (via Docker's init mechanism).
--
-- WHY a separate init script?
-- - Docker's postgres image runs .sql files from /docker-entrypoint-initdb.d/
-- - Ensures database is ready before the backend connects
-- - Cleaner separation of concerns
--
-- HOW IT WORKS:
-- When the PostgreSQL container starts with an empty data directory:
-- 1. PostgreSQL initializes the database cluster
-- 2. Creates the database specified by POSTGRES_DB
-- 3. Runs all .sql files in /docker-entrypoint-initdb.d/ alphabetically
--
-- USAGE:
-- This file is copied to /docker-entrypoint-initdb.d/ in the container.
-- See database.yaml (Kubernetes) or docker-compose.yml (Docker)

-- Create the settings table
CREATE TABLE IF NOT EXISTS settings (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Insert default value (your initials as default name)
INSERT INTO settings (name) VALUES ('Sem Van Broekhoven')
ON CONFLICT DO NOTHING;

-- Optional: Create an index for faster lookups (not needed for single row, but good practice)
-- CREATE INDEX IF NOT EXISTS idx_settings_id ON settings(id);

-- Log that initialization is complete
DO $$
BEGIN
    RAISE NOTICE 'SVB Webstack database initialized successfully!';
END $$;
