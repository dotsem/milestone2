-- ==============================================================================
-- PostgreSQL Database Schema for SVB Webstack
-- ==============================================================================
-- This file defines the database structure for the webstack application.
--
-- PURPOSE:
-- - Documents the database schema for assignment documentation
-- - Can be used for manual database initialization
-- - Serves as reference for the table structure
--
-- NOTE: The FastAPI backend (main.py) automatically creates this table on startup
-- if it doesn't exist. This file is for documentation and manual use.
--
-- USAGE (Manual):
--   psql -U postgres -d webstack -f schema.sql
--
-- Or connect to the database pod:
--   kubectl exec -it -n svb-webstack svb-database-0 -- psql -U postgres -d webstack
--   \i /path/to/schema.sql

-- ==============================================================================
-- SETTINGS TABLE
-- ==============================================================================
-- This table stores application settings, primarily the user name.
--
-- WHY this structure?
-- - Simple key-value storage for the demo
-- - Single row with id=1 holds the current name
-- - Could be extended with more settings if needed

CREATE TABLE IF NOT EXISTS settings (
    -- Primary key
    -- WHY SERIAL?
    -- - Auto-incrementing integer
    -- - Unique identifier for each row
    -- - PostgreSQL-specific (equivalent to AUTO_INCREMENT in MySQL)
    id SERIAL PRIMARY KEY,
    
    -- User name to display on the frontend
    -- WHY VARCHAR(255)?
    -- - Variable-length string up to 255 characters
    -- - Sufficient for names
    -- - NOT NULL ensures a value is always present
    name VARCHAR(255) NOT NULL
);

-- ==============================================================================
-- INITIAL DATA
-- ==============================================================================
-- Insert default data only if the table is empty.
-- This prevents duplicate entries on re-initialization.

-- Check if table is empty and insert default value
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM settings LIMIT 1) THEN
        INSERT INTO settings (name) VALUES ('Sem Van Broekhoven');
    END IF;
END $$;

-- ==============================================================================
-- USEFUL QUERIES (for documentation/testing)
-- ==============================================================================

-- View current name:
-- SELECT name FROM settings WHERE id = 1;

-- Update name:
-- UPDATE settings SET name = 'New Name' WHERE id = 1;

-- View all settings:
-- SELECT * FROM settings;
