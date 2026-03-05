-- ============================================================
-- init_pgadmin.sql (SQL pur) - Compatible pgAdmin
-- How:
--   Query Tool -> CTRL+A -> F5
-- ============================================================

BEGIN;

-- ============================================================
-- 00_drop.sql  
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


-- ============================================================
-- 01_schema.sql 
-- ============================================================

-- ---------- ENUM TYPES ----------
CREATE TYPE room_capacity AS ENUM ('single','double','triple','quad','suite');
CREATE TYPE room_view AS ENUM ('none','sea','mountain');
CREATE TYPE booking_status AS ENUM ('active','cancelled','expired','checked_in');

-- ---------- HOTEL CHAIN ----------
CREATE TABLE hotel_chain (
    chain_id BIGSERIAL PRIMARY KEY,
    chain_name TEXT NOT NULL UNIQUE,

    hq_street TEXT NOT NULL,
    hq_city TEXT NOT NULL,
    hq_state TEXT,
    hq_country TEXT NOT NULL,
    hq_postal_code TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE chain_email (
    chain_id BIGINT NOT NULL,
    email TEXT NOT NULL,
    PRIMARY KEY (chain_id,email)
);

CREATE TABLE chain_phone (
    chain_id BIGINT NOT NULL,
    phone TEXT NOT NULL,
    PRIMARY KEY (chain_id,phone)
);

-- ---------- HOTEL ----------
CREATE TABLE hotel (
    hotel_id BIGSERIAL PRIMARY KEY,
    chain_id BIGINT NOT NULL,

    hotel_name TEXT NOT NULL,
    star_rating INT NOT NULL,

    street TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT,
    country TEXT NOT NULL,
    postal_code TEXT,

    area TEXT NOT NULL,

    manager_employee_id BIGINT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE hotel_email (
    hotel_id BIGINT NOT NULL,
    email TEXT NOT NULL,
    PRIMARY KEY (hotel_id,email)
);

CREATE TABLE hotel_phone (
    hotel_id BIGINT NOT NULL,
    phone TEXT NOT NULL,
    PRIMARY KEY (hotel_id,phone)
);

-- ---------- ROOM ----------
CREATE TABLE room (
    room_id BIGSERIAL PRIMARY KEY,
    hotel_id BIGINT NOT NULL,

    room_number TEXT NOT NULL,
    price_per_night NUMERIC(10,2) NOT NULL,

    capacity room_capacity NOT NULL,
    view_type room_view DEFAULT 'none',

    extendable BOOLEAN DEFAULT FALSE,
    problem_notes TEXT,

    UNIQUE (hotel_id,room_number)
);

-- ---------- AMENITIES ----------
CREATE TABLE amenity (
    amenity_id BIGSERIAL PRIMARY KEY,
    amenity_name TEXT NOT NULL UNIQUE
);

CREATE TABLE room_amenity (
    room_id BIGINT NOT NULL,
    amenity_id BIGINT NOT NULL,
    PRIMARY KEY (room_id,amenity_id)
);

-- ---------- CUSTOMER ----------
CREATE TABLE customer (
    customer_id BIGSERIAL PRIMARY KEY,

    full_name TEXT NOT NULL,

    street TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT,
    country TEXT NOT NULL,
    postal_code TEXT,

    id_type TEXT NOT NULL,
    id_value TEXT NOT NULL,

    registered_at DATE DEFAULT CURRENT_DATE
);

-- ---------- EMPLOYEE ----------
CREATE TABLE employee (
    employee_id BIGSERIAL PRIMARY KEY,
    hotel_id BIGINT NOT NULL,

    full_name TEXT NOT NULL,

    street TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT,
    country TEXT NOT NULL,
    postal_code TEXT,

    ssn_sin TEXT NOT NULL
);

CREATE TABLE role (
    role_id BIGSERIAL PRIMARY KEY,
    role_name TEXT NOT NULL UNIQUE
);

CREATE TABLE employee_role (
    employee_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (employee_id,role_id)
);

-- ---------- BOOKING ----------
CREATE TABLE booking (
    booking_id BIGSERIAL PRIMARY KEY,

    customer_id BIGINT NOT NULL,
    room_id BIGINT NOT NULL,

    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    status booking_status DEFAULT 'active',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ---------- RENTING ----------
CREATE TABLE renting (
    renting_id BIGSERIAL PRIMARY KEY,

    booking_id BIGINT,
    customer_id BIGINT NOT NULL,
    room_id BIGINT NOT NULL,

    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    checkin_employee_id BIGINT NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ---------- PAYMENT ----------
CREATE TABLE payment (
    payment_id BIGSERIAL PRIMARY KEY,
    renting_id BIGINT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    method TEXT NOT NULL
);

-- ---------- ARCHIVE TABLES ----------
CREATE TABLE booking_archive (
    booking_archive_id BIGSERIAL PRIMARY KEY,
    original_booking_id BIGINT,

    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status TEXT NOT NULL,

    customer_full_name TEXT NOT NULL,
    customer_id_type TEXT NOT NULL,
    customer_id_value TEXT NOT NULL,
    customer_address TEXT NOT NULL,

    chain_name TEXT NOT NULL,
    hotel_name TEXT NOT NULL,
    hotel_address TEXT NOT NULL,
    hotel_star_rating INT NOT NULL,

    room_number TEXT NOT NULL,
    room_price_per_night NUMERIC(10,2) NOT NULL,
    room_capacity TEXT NOT NULL,
    room_view_type TEXT NOT NULL,
    room_extendable BOOLEAN NOT NULL
);

CREATE TABLE renting_archive (
    renting_archive_id BIGSERIAL PRIMARY KEY,
    original_renting_id BIGINT,
    original_booking_id BIGINT,

    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    checkin_employee_name TEXT NOT NULL,
    checkin_employee_ssn_sin TEXT NOT NULL,

    customer_full_name TEXT NOT NULL,
    customer_id_type TEXT NOT NULL,
    customer_id_value TEXT NOT NULL,
    customer_address TEXT NOT NULL,

    chain_name TEXT NOT NULL,
    hotel_name TEXT NOT NULL,
    hotel_address TEXT NOT NULL,
    hotel_star_rating INT NOT NULL,

    room_number TEXT NOT NULL,
    room_price_per_night NUMERIC(10,2) NOT NULL,
    room_capacity TEXT NOT NULL,
    room_view_type TEXT NOT NULL,
    room_extendable BOOLEAN NOT NULL
);

-- ============================================================
-- 02_constraints.sql 
-- ============================================================



-- ============================================================
-- 03_views.sql
-- ============================================================



-- ============================================================
-- 04_indexes.sql 
-- ============================================================



-- ============================================================
-- 05_triggers.sql
-- ============================================================



-- ============================================================
-- 06_populate.sql
-- ============================================================



-- ============================================================
-- 08_server_api.sql
-- ============================================================



COMMIT;