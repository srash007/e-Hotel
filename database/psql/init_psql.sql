-- ============================================================
-- init_psql.sql (for psql terminal)
-- Usage:
--   psql -U postgres -d hotel_db -f database/psql/init_psql.sql
-- ============================================================

\set ON_ERROR_STOP on

BEGIN;

\i database/sql/00_drop.sql
\i database/sql/01_schema.sql
\i database/sql/02_constraints.sql
\i database/sql/03_views.sql
\i database/sql/04_indexes.sql
\i database/sql/05_triggers.sql
\i database/sql/06_populate.sql
\i database/sql/08_server_api.sql
-- optional:
-- \i database/sql/07_queries.sql

COMMIT;