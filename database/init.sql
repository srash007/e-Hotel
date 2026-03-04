-- ============================================================
-- init.sql
-- Main script to recreate the entire database structure
-- Run with:
-- psql -d hotel_db -f database/init.sql
-- ============================================================

\set ON_ERROR_STOP on

BEGIN;

-- 1. Clean database
\i database/00_drop.sql

-- 2. Create tables and types
\i database/01_schema.sql

-- 3. Add constraints (PK, FK, CHECK, etc.)
\i database/02_constraints.sql

-- 4. Create views
\i database/03_views.sql

-- 5. Create indexes
\i database/04_indexes.sql

-- 6. Create triggers
\i database/05_triggers.sql

-- 7. Populate database with sample data
\i database/06_populate.sql

COMMIT;