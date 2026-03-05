-- ============================================================
-- 00_drop.sql
-- Drops all objects for a clean reset (PostgreSQL)
-- ============================================================

-- Drop views first
DROP VIEW IF EXISTS view_available_rooms_per_area CASCADE;
DROP VIEW IF EXISTS view_hotel_capacity CASCADE;

-- Drop tables (CASCADE removes dependent constraints/indexes)
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS renting CASCADE;
DROP TABLE IF EXISTS booking CASCADE;

DROP TABLE IF EXISTS employee_role CASCADE;
DROP TABLE IF EXISTS role CASCADE;
DROP TABLE IF EXISTS employee CASCADE;

DROP TABLE IF EXISTS customer CASCADE;

DROP TABLE IF EXISTS room_amenity CASCADE;
DROP TABLE IF EXISTS amenity CASCADE;

DROP TABLE IF EXISTS room CASCADE;

DROP TABLE IF EXISTS hotel_phone CASCADE;
DROP TABLE IF EXISTS hotel_email CASCADE;
DROP TABLE IF EXISTS hotel CASCADE;

DROP TABLE IF EXISTS chain_phone CASCADE;
DROP TABLE IF EXISTS chain_email CASCADE;
DROP TABLE IF EXISTS hotel_chain CASCADE;

DROP TABLE IF EXISTS booking_archive CASCADE;
DROP TABLE IF EXISTS renting_archive CASCADE;

-- Drop enum types last
DROP TYPE IF EXISTS booking_status CASCADE;
DROP TYPE IF EXISTS room_capacity CASCADE;
DROP TYPE IF EXISTS room_view CASCADE;