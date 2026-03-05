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
-- ---------- FOREIGN KEY CONSTRAINTS ----------
ALTER TABLE hotel
  ADD CONSTRAINT fk_hotel_chain
  FOREIGN KEY (chain_id)
  REFERENCES hotel_chain(chain_id)
  ON DELETE CASCADE;

-- Hotel -> Room (cascade)
ALTER TABLE room
  ADD CONSTRAINT fk_room_hotel
  FOREIGN KEY (hotel_id)
  REFERENCES hotel(hotel_id)
  ON DELETE CASCADE;

-- Chain contact info (cascade)
ALTER TABLE chain_email
  ADD CONSTRAINT fk_chain_email_chain
  FOREIGN KEY (chain_id)
  REFERENCES hotel_chain(chain_id)
  ON DELETE CASCADE;

ALTER TABLE chain_phone
  ADD CONSTRAINT fk_chain_phone_chain
  FOREIGN KEY (chain_id)
  REFERENCES hotel_chain(chain_id)
  ON DELETE CASCADE;

-- Hotel contact info (cascade)
ALTER TABLE hotel_email
  ADD CONSTRAINT fk_hotel_email_hotel
  FOREIGN KEY (hotel_id)
  REFERENCES hotel(hotel_id)
  ON DELETE CASCADE;

ALTER TABLE hotel_phone
  ADD CONSTRAINT fk_hotel_phone_hotel
  FOREIGN KEY (hotel_id)
  REFERENCES hotel(hotel_id)
  ON DELETE CASCADE;

-- Room amenities (cascade room side)
ALTER TABLE room_amenity
  ADD CONSTRAINT fk_room_amenity_room
  FOREIGN KEY (room_id)
  REFERENCES room(room_id)
  ON DELETE CASCADE;

ALTER TABLE room_amenity
  ADD CONSTRAINT fk_room_amenity_amenity
  FOREIGN KEY (amenity_id)
  REFERENCES amenity(amenity_id)
  ON DELETE RESTRICT;

-- Employees belong to a hotel (cascade)
ALTER TABLE employee
  ADD CONSTRAINT fk_employee_hotel
  FOREIGN KEY (hotel_id)
  REFERENCES hotel(hotel_id)
  ON DELETE CASCADE;

-- Employee roles (cascade employee side)
ALTER TABLE employee_role
  ADD CONSTRAINT fk_employee_role_employee
  FOREIGN KEY (employee_id)
  REFERENCES employee(employee_id)
  ON DELETE CASCADE;

ALTER TABLE employee_role
  ADD CONSTRAINT fk_employee_role_role
  FOREIGN KEY (role_id)
  REFERENCES role(role_id)
  ON DELETE RESTRICT;

-- Hotel manager (FK only; "manager must belong to same hotel" will be a trigger later)
ALTER TABLE hotel
  ADD CONSTRAINT fk_hotel_manager
  FOREIGN KEY (manager_employee_id)
  REFERENCES employee(employee_id)
  DEFERRABLE INITIALLY DEFERRED;

-- ---------- TRANSACTIONS FKs ----------
-- Bookings: restrict delete of customer/room if referenced by active operational records
ALTER TABLE booking
  ADD CONSTRAINT fk_booking_customer
  FOREIGN KEY (customer_id)
  REFERENCES customer(customer_id)
  ON DELETE RESTRICT;

ALTER TABLE booking
  ADD CONSTRAINT fk_booking_room
  FOREIGN KEY (room_id)
  REFERENCES room(room_id)
  ON DELETE RESTRICT;

-- Renting
ALTER TABLE renting
  ADD CONSTRAINT fk_renting_booking
  FOREIGN KEY (booking_id)
  REFERENCES booking(booking_id)
  ON DELETE SET NULL;

ALTER TABLE renting
  ADD CONSTRAINT fk_renting_customer
  FOREIGN KEY (customer_id)
  REFERENCES customer(customer_id)
  ON DELETE RESTRICT;

ALTER TABLE renting
  ADD CONSTRAINT fk_renting_room
  FOREIGN KEY (room_id)
  REFERENCES room(room_id)
  ON DELETE RESTRICT;

ALTER TABLE renting
  ADD CONSTRAINT fk_renting_employee
  FOREIGN KEY (checkin_employee_id)
  REFERENCES employee(employee_id)
  ON DELETE RESTRICT;

-- Payment: if renting deleted, payments deleted too (no history required)
ALTER TABLE payment
  ADD CONSTRAINT fk_payment_renting
  FOREIGN KEY (renting_id)
  REFERENCES renting(renting_id)
  ON DELETE CASCADE;


-- ---------- DOMAIN / ATTRIBUTE CONSTRAINTS ----------
-- Hotel category 1..5
ALTER TABLE hotel
  ADD CONSTRAINT chk_hotel_star_rating
  CHECK (star_rating BETWEEN 1 AND 5);

-- Prices non-negative
ALTER TABLE room
  ADD CONSTRAINT chk_room_price_nonneg
  CHECK (price_per_night >= 0);

-- Booking dates valid
ALTER TABLE booking
  ADD CONSTRAINT chk_booking_dates
  CHECK (start_date < end_date);

-- Renting dates valid
ALTER TABLE renting
  ADD CONSTRAINT chk_renting_dates
  CHECK (start_date < end_date);

-- Payment amount non-negative
ALTER TABLE payment
  ADD CONSTRAINT chk_payment_amount_nonneg
  CHECK (amount >= 0);

-- Optional: restrict booking status already by ENUM, but keep a sanity check
-- (Not necessary; ENUM already enforces)

-- Optional: enforce simple allowed ID types (inventive, but realistic)
ALTER TABLE customer
  ADD CONSTRAINT chk_customer_id_type
  CHECK (id_type IN ('SSN','SIN','DRIVER_LICENCE','PASSPORT'));

-- Optional: simple allowed payment methods
ALTER TABLE payment
  ADD CONSTRAINT chk_payment_method
  CHECK (method IN ('cash','card','online','transfer'));

-- Optional: prevent empty strings for key text fields
ALTER TABLE hotel_chain
  ADD CONSTRAINT chk_chain_name_not_blank
  CHECK (length(trim(chain_name)) > 0);

ALTER TABLE hotel
  ADD CONSTRAINT chk_hotel_name_not_blank
  CHECK (length(trim(hotel_name)) > 0);

ALTER TABLE customer
  ADD CONSTRAINT chk_customer_name_not_blank
  CHECK (length(trim(full_name)) > 0);

ALTER TABLE employee
  ADD CONSTRAINT chk_employee_name_not_blank
  CHECK (length(trim(full_name)) > 0);



-- ============================================================
-- 03_views.sql
-- ============================================================

-- View 1: available rooms per area for the current night
-- Availability window: [CURRENT_DATE, CURRENT_DATE + 1)
CREATE OR REPLACE VIEW view_available_rooms_per_area AS
SELECT
  h.area,
  COUNT(*) AS available_rooms
FROM room r
JOIN hotel h ON h.hotel_id = r.hotel_id
WHERE
  -- No overlap with any renting
  NOT EXISTS (
    SELECT 1
    FROM renting rt
    WHERE rt.room_id = r.room_id
      AND NOT (rt.end_date <= CURRENT_DATE OR rt.start_date >= CURRENT_DATE + 1)
  )
  -- No overlap with any ACTIVE booking
  AND NOT EXISTS (
    SELECT 1
    FROM booking b
    WHERE b.room_id = r.room_id
      AND b.status = 'active'
      AND NOT (b.end_date <= CURRENT_DATE OR b.start_date >= CURRENT_DATE + 1)
  )
GROUP BY h.area
ORDER BY h.area;

-- View 2: aggregated capacity per hotel (for all hotels; UI can filter by hotel_id)
-- We convert capacity enum to numeric "beds" for aggregation:
-- single=1, double=2, triple=3, quad=4, suite=5
CREATE OR REPLACE VIEW view_hotel_capacity AS
SELECT
  h.hotel_id,
  h.hotel_name,
  h.area,
  COUNT(*) AS total_rooms,
  SUM(
    CASE r.capacity
      WHEN 'single' THEN 1
      WHEN 'double' THEN 2
      WHEN 'triple' THEN 3
      WHEN 'quad'   THEN 4
      WHEN 'suite'  THEN 5
    END
  ) AS aggregated_capacity_beds,

  -- Bonus breakdown (useful in demo)
  SUM(CASE WHEN r.capacity = 'single' THEN 1 ELSE 0 END) AS num_single,
  SUM(CASE WHEN r.capacity = 'double' THEN 1 ELSE 0 END) AS num_double,
  SUM(CASE WHEN r.capacity = 'triple' THEN 1 ELSE 0 END) AS num_triple,
  SUM(CASE WHEN r.capacity = 'quad'   THEN 1 ELSE 0 END) AS num_quad,
  SUM(CASE WHEN r.capacity = 'suite'  THEN 1 ELSE 0 END) AS num_suite
FROM hotel h
JOIN room r ON r.hotel_id = h.hotel_id
GROUP BY h.hotel_id, h.hotel_name, h.area
ORDER BY h.hotel_id;


-- ============================================================
-- 04_indexes.sql 
-- ============================================================

-- 1) Rooms are frequently filtered by hotel (and hotels by chain/area)
CREATE INDEX IF NOT EXISTS idx_room_hotel_id
  ON room(hotel_id);

-- 2) Hotels are frequently filtered by area (UI dropdown / view 1)
CREATE INDEX IF NOT EXISTS idx_hotel_area
  ON hotel(area);

-- 3) Hotels are frequently filtered by chain and category
CREATE INDEX IF NOT EXISTS idx_hotel_chain_star
  ON hotel(chain_id, star_rating);

-- 4) Availability checks: bookings overlap lookups by room & date range
-- Partial index: only active bookings matter for availability
CREATE INDEX IF NOT EXISTS idx_booking_active_room_dates
  ON booking(room_id, start_date, end_date)
  WHERE status = 'active';

-- 5) Availability checks: rentings overlap lookups by room & date range
CREATE INDEX IF NOT EXISTS idx_renting_room_dates
  ON renting(room_id, start_date, end_date);

-- 6) Optional: price filtering in UI (min/max price), often combined with hotel_id
CREATE INDEX IF NOT EXISTS idx_room_price
  ON room(price_per_night);
  
-- ============================================================
-- 05_triggers.sql
-- ============================================================

CREATE OR REPLACE FUNCTION trg_booking_no_overlap_fn()
RETURNS TRIGGER AS $$
BEGIN
  -- Only enforce for ACTIVE bookings
  IF NEW.status <> 'active' THEN
    RETURN NEW;
  END IF;

  -- Basic sanity (also enforced by CHECK in 02_constraints.sql)
  IF NEW.start_date >= NEW.end_date THEN
    RAISE EXCEPTION 'Invalid booking dates: start_date must be < end_date';
  END IF;

  -- (A) No overlap with another ACTIVE booking for same room
  IF EXISTS (
    SELECT 1
    FROM booking b
    WHERE b.room_id = NEW.room_id
      AND b.status = 'active'
      AND (TG_OP = 'INSERT' OR b.booking_id <> NEW.booking_id)
      AND NOT (b.end_date <= NEW.start_date OR b.start_date >= NEW.end_date)
  ) THEN
    RAISE EXCEPTION 'Booking conflict: room % already booked for overlapping dates', NEW.room_id;
  END IF;

  -- (B) No overlap with an existing renting for same room
  IF EXISTS (
    SELECT 1
    FROM renting r
    WHERE r.room_id = NEW.room_id
      AND NOT (r.end_date <= NEW.start_date OR r.start_date >= NEW.end_date)
  ) THEN
    RAISE EXCEPTION 'Booking conflict: room % is rented for overlapping dates', NEW.room_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_booking_no_overlap ON booking;
CREATE TRIGGER trg_booking_no_overlap
BEFORE INSERT OR UPDATE OF room_id, start_date, end_date, status
ON booking
FOR EACH ROW
EXECUTE FUNCTION trg_booking_no_overlap_fn();


-- ============================================================
-- TRIGGER 2: Prevent overlapping RENTINGS for the same room
-- and prevent renting overlap with ACTIVE bookings
-- ============================================================

CREATE OR REPLACE FUNCTION trg_renting_no_overlap_fn()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.start_date >= NEW.end_date THEN
    RAISE EXCEPTION 'Invalid renting dates: start_date must be < end_date';
  END IF;

  -- (A) No overlap with another renting for same room
  IF EXISTS (
    SELECT 1
    FROM renting r
    WHERE r.room_id = NEW.room_id
      AND (TG_OP = 'INSERT' OR r.renting_id <> NEW.renting_id)
      AND NOT (r.end_date <= NEW.start_date OR r.start_date >= NEW.end_date)
  ) THEN
    RAISE EXCEPTION 'Renting conflict: room % already rented for overlapping dates', NEW.room_id;
  END IF;

  -- (B) No overlap with an ACTIVE booking
  IF EXISTS (
    SELECT 1
    FROM booking b
    WHERE b.room_id = NEW.room_id
      AND b.status = 'active'
      AND NOT (b.end_date <= NEW.start_date OR b.start_date >= NEW.end_date)
  ) THEN
    RAISE EXCEPTION 'Renting conflict: room % has an active booking for overlapping dates', NEW.room_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_renting_no_overlap ON renting;
CREATE TRIGGER trg_renting_no_overlap
BEFORE INSERT OR UPDATE OF room_id, start_date, end_date
ON renting
FOR EACH ROW
EXECUTE FUNCTION trg_renting_no_overlap_fn();


-- ============================================================
-- TRIGGER 3: If renting is created from a booking:
-- - booking must exist and be ACTIVE
-- - renting.customer_id and renting.room_id must match booking
-- - booking becomes CHECKED_IN automatically
-- - (bonus) archive the booking snapshot immediately
-- ============================================================

CREATE OR REPLACE FUNCTION trg_renting_from_booking_fn()
RETURNS TRIGGER AS $$
DECLARE
  b booking%ROWTYPE;
  c customer%ROWTYPE;
  rm room%ROWTYPE;
  h hotel%ROWTYPE;
  ch hotel_chain%ROWTYPE;
  emp employee%ROWTYPE;

  customer_addr TEXT;
  hotel_addr TEXT;
BEGIN
  -- If walk-in renting (no booking), do nothing here
  IF NEW.booking_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Fetch booking
  SELECT * INTO b FROM booking WHERE booking_id = NEW.booking_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Cannot create renting: booking_id % does not exist', NEW.booking_id;
  END IF;

  IF b.status <> 'active' THEN
    RAISE EXCEPTION 'Cannot create renting from booking %: status is %, expected active', b.booking_id, b.status;
  END IF;

  -- Enforce match
  IF NEW.room_id <> b.room_id THEN
    RAISE EXCEPTION 'Renting.room_id (%) must match Booking.room_id (%)', NEW.room_id, b.room_id;
  END IF;

  IF NEW.customer_id <> b.customer_id THEN
    RAISE EXCEPTION 'Renting.customer_id (%) must match Booking.customer_id (%)', NEW.customer_id, b.customer_id;
  END IF;

  -- Auto-update booking status
  UPDATE booking
  SET status = 'checked_in'
  WHERE booking_id = b.booking_id;

  -- -------- BONUS: archive booking snapshot now --------
  SELECT * INTO c FROM customer WHERE customer_id = b.customer_id;
  SELECT * INTO rm FROM room WHERE room_id = b.room_id;
  SELECT * INTO h FROM hotel WHERE hotel_id = rm.hotel_id;
  SELECT * INTO ch FROM hotel_chain WHERE chain_id = h.chain_id;
  SELECT * INTO emp FROM employee WHERE employee_id = NEW.checkin_employee_id;

  customer_addr := c.street || ', ' || c.city
                   || COALESCE(', ' || c.state, '')
                   || ', ' || c.country
                   || COALESCE(' ' || c.postal_code, '');

  hotel_addr := h.street || ', ' || h.city
                || COALESCE(', ' || h.state, '')
                || ', ' || h.country
                || COALESCE(' ' || h.postal_code, '');

  INSERT INTO booking_archive (
    original_booking_id,
    start_date, end_date, status,
    customer_full_name, customer_id_type, customer_id_value, customer_address,
    chain_name, hotel_name, hotel_address, hotel_star_rating,
    room_number, room_price_per_night, room_capacity, room_view_type, room_extendable
  )
  VALUES (
    b.booking_id,
    b.start_date, b.end_date, b.status::TEXT,
    c.full_name, c.id_type, c.id_value, customer_addr,
    ch.chain_name, h.hotel_name, hotel_addr, h.star_rating,
    rm.room_number, rm.price_per_night, rm.capacity::TEXT, rm.view_type::TEXT, rm.extendable
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_renting_from_booking ON renting;
CREATE TRIGGER trg_renting_from_booking
BEFORE INSERT
ON renting
FOR EACH ROW
EXECUTE FUNCTION trg_renting_from_booking_fn();


-- ============================================================
-- TRIGGER 4: Manager must belong to the same hotel (user-defined)
-- Enforced on insert/update of hotel.manager_employee_id
-- ============================================================

CREATE OR REPLACE FUNCTION trg_hotel_manager_same_hotel_fn()
RETURNS TRIGGER AS $$
DECLARE
  emp_hotel_id BIGINT;
BEGIN
  -- Allow null temporarily (but you can later enforce NOT NULL if you want)
  IF NEW.manager_employee_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT hotel_id INTO emp_hotel_id
  FROM employee
  WHERE employee_id = NEW.manager_employee_id;

  IF emp_hotel_id IS NULL THEN
    RAISE EXCEPTION 'manager_employee_id % does not exist in employee', NEW.manager_employee_id;
  END IF;

  IF emp_hotel_id <> NEW.hotel_id THEN
    RAISE EXCEPTION 'Manager (employee_id=%) must belong to the same hotel (hotel_id=%). Employee belongs to hotel_id=%',
      NEW.manager_employee_id, NEW.hotel_id, emp_hotel_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_hotel_manager_same_hotel ON hotel;
CREATE TRIGGER trg_hotel_manager_same_hotel
BEFORE INSERT OR UPDATE OF manager_employee_id
ON hotel
FOR EACH ROW
EXECUTE FUNCTION trg_hotel_manager_same_hotel_fn();



CREATE OR REPLACE FUNCTION trg_booking_archive_on_delete_fn()
RETURNS TRIGGER AS $$
DECLARE
  c customer%ROWTYPE;
  rm room%ROWTYPE;
  h hotel%ROWTYPE;
  ch hotel_chain%ROWTYPE;

  customer_addr TEXT;
  hotel_addr TEXT;
BEGIN
  -- Snapshot current linked data (exists because FK restrict prevents deleting deps first)
  SELECT * INTO c FROM customer WHERE customer_id = OLD.customer_id;
  SELECT * INTO rm FROM room WHERE room_id = OLD.room_id;
  SELECT * INTO h FROM hotel WHERE hotel_id = rm.hotel_id;
  SELECT * INTO ch FROM hotel_chain WHERE chain_id = h.chain_id;

  customer_addr := c.street || ', ' || c.city
                   || COALESCE(', ' || c.state, '')
                   || ', ' || c.country
                   || COALESCE(' ' || c.postal_code, '');

  hotel_addr := h.street || ', ' || h.city
                || COALESCE(', ' || h.state, '')
                || ', ' || h.country
                || COALESCE(' ' || h.postal_code, '');

  INSERT INTO booking_archive (
    original_booking_id, archived_at,
    start_date, end_date, status,
    customer_full_name, customer_id_type, customer_id_value, customer_address,
    chain_name, hotel_name, hotel_address, hotel_star_rating,
    room_number, room_price_per_night, room_capacity, room_view_type, room_extendable
  )
  VALUES (
    OLD.booking_id, now(),
    OLD.start_date, OLD.end_date, OLD.status::TEXT,
    c.full_name, c.id_type, c.id_value, customer_addr,
    ch.chain_name, h.hotel_name, hotel_addr, h.star_rating,
    rm.room_number, rm.price_per_night, rm.capacity::TEXT, rm.view_type::TEXT, rm.extendable
  );

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_booking_archive_on_delete ON booking;
CREATE TRIGGER trg_booking_archive_on_delete
BEFORE DELETE ON booking
FOR EACH ROW
EXECUTE FUNCTION trg_booking_archive_on_delete_fn();


CREATE OR REPLACE FUNCTION trg_renting_archive_on_delete_fn()
RETURNS TRIGGER AS $$
DECLARE
  c customer%ROWTYPE;
  rm room%ROWTYPE;
  h hotel%ROWTYPE;
  ch hotel_chain%ROWTYPE;
  emp employee%ROWTYPE;

  customer_addr TEXT;
  hotel_addr TEXT;
BEGIN
  SELECT * INTO c FROM customer WHERE customer_id = OLD.customer_id;
  SELECT * INTO rm FROM room WHERE room_id = OLD.room_id;
  SELECT * INTO h FROM hotel WHERE hotel_id = rm.hotel_id;
  SELECT * INTO ch FROM hotel_chain WHERE chain_id = h.chain_id;
  SELECT * INTO emp FROM employee WHERE employee_id = OLD.checkin_employee_id;

  customer_addr := c.street || ', ' || c.city
                   || COALESCE(', ' || c.state, '')
                   || ', ' || c.country
                   || COALESCE(' ' || c.postal_code, '');

  hotel_addr := h.street || ', ' || h.city
                || COALESCE(', ' || h.state, '')
                || ', ' || h.country
                || COALESCE(' ' || h.postal_code, '');

  INSERT INTO renting_archive (
    original_renting_id, original_booking_id, archived_at,
    start_date, end_date,
    checkin_employee_name, checkin_employee_ssn_sin,
    customer_full_name, customer_id_type, customer_id_value, customer_address,
    chain_name, hotel_name, hotel_address, hotel_star_rating,
    room_number, room_price_per_night, room_capacity, room_view_type, room_extendable
  )
  VALUES (
    OLD.renting_id, OLD.booking_id, now(),
    OLD.start_date, OLD.end_date,
    emp.full_name, emp.ssn_sin,
    c.full_name, c.id_type, c.id_value, customer_addr,
    ch.chain_name, h.hotel_name, hotel_addr, h.star_rating,
    rm.room_number, rm.price_per_night, rm.capacity::TEXT, rm.view_type::TEXT, rm.extendable
  );

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_renting_archive_on_delete ON renting;
CREATE TRIGGER trg_renting_archive_on_delete
BEFORE DELETE ON renting
FOR EACH ROW
EXECUTE FUNCTION trg_renting_archive_on_delete_fn();

-- ============================================================
-- 06_populate.sql
-- ============================================================


-- ---------- ROLES ----------
INSERT INTO role(role_id, role_name) VALUES
  (1, 'Manager'),
  (2, 'Receptionist')
ON CONFLICT DO NOTHING;

-- ---------- AMENITIES ----------
INSERT INTO amenity(amenity_id, amenity_name) VALUES
  (1,'TV'),
  (2,'Air Conditioning'),
  (3,'Fridge'),
  (4,'WiFi'),
  (5,'Coffee Machine'),
  (6,'Balcony')
ON CONFLICT DO NOTHING;

-- ---------- HOTEL CHAINS (5) ----------
INSERT INTO hotel_chain(chain_id, chain_name, hq_street, hq_city, hq_state, hq_country, hq_postal_code) VALUES
  (1,'Marriott Group','7750 Wisconsin Ave','Bethesda','MD','USA','20814'),
  (2,'Hilton Worldwide','7930 Jones Branch Dr','McLean','VA','USA','22102'),
  (3,'Hyatt Hotels','150 N Riverside Plaza','Chicago','IL','USA','60606'),
  (4,'IHG Hotels','3 Ravinia Dr','Atlanta','GA','USA','30346'),
  (5,'Accor Hotels','82 Rue Henri Farman','Paris',NULL,'France','92130');

INSERT INTO chain_email(chain_id,email) VALUES
  (1,'contact@marriott.example'), (2,'contact@hilton.example'),
  (3,'contact@hyatt.example'),   (4,'contact@ihg.example'),
  (5,'contact@accor.example')
ON CONFLICT DO NOTHING;

INSERT INTO chain_phone(chain_id,phone) VALUES
  (1,'+1-800-000-0001'), (2,'+1-800-000-0002'),
  (3,'+1-800-000-0003'), (4,'+1-800-000-0004'),
  (5,'+33-1-0000-0005')
ON CONFLICT DO NOTHING;

-- ---------- HOTELS (8 per chain, 40 total) ----------
-- Note: manager_employee_id left NULL for now (will be updated after employees insert)

-- Chain 1 (hotel_id 101-108)
INSERT INTO hotel(hotel_id, chain_id, hotel_name, star_rating, street, city, state, country, postal_code, area, manager_employee_id) VALUES
 (101,1,'Marriott Downtown Montreal',5,'100 Rue Sainte-Catherine','Montreal','QC','Canada','H2X 1Z6','Downtown Montreal',NULL),
 (102,1,'Marriott Old Port Montreal',4,'200 Rue de la Commune','Montreal','QC','Canada','H2Y 2E2','Old Port Montreal',NULL),
 (103,1,'Marriott Toronto Centre',4,'50 King St W','Toronto','ON','Canada','M5H 1J9','Toronto Downtown',NULL),
 (104,1,'Marriott Ottawa Central',3,'80 Laurier Ave','Ottawa','ON','Canada','K1P 5J4','Ottawa Downtown',NULL),
 (105,1,'Marriott Vancouver Bay',5,'1200 W Georgia St','Vancouver','BC','Canada','V6E 4R2','Vancouver Downtown',NULL),
 (106,1,'Marriott Quebec City',3,'10 Rue Saint-Jean','Quebec City','QC','Canada','G1R 1N6','Quebec Old Town',NULL),
 (107,1,'Marriott Boston Harbor',4,'1 Seaport Ln','Boston','MA','USA','02210','Boston Seaport',NULL),
 (108,1,'Marriott New York Midtown',5,'300 8th Ave','New York','NY','USA','10001','NYC Midtown',NULL);

-- Chain 2 (201-208)  (two hotels in same area: Downtown Montreal)
INSERT INTO hotel(hotel_id, chain_id, hotel_name, star_rating, street, city, state, country, postal_code, area, manager_employee_id) VALUES
 (201,2,'Hilton Downtown Montreal East',4,'1100 Blvd Rene-Levesque','Montreal','QC','Canada','H3B 4W8','Downtown Montreal',NULL),
 (202,2,'Hilton Downtown Montreal West',3,'900 Rue Sherbrooke O','Montreal','QC','Canada','H3A 1G5','Downtown Montreal',NULL),
 (203,2,'Hilton Toronto Airport',3,'600 Dixon Rd','Toronto','ON','Canada','M9W 1J1','Toronto Airport',NULL),
 (204,2,'Hilton Ottawa Riverside',4,'40 Queen St','Ottawa','ON','Canada','K1P 5Y7','Ottawa Downtown',NULL),
 (205,2,'Hilton Calgary City',4,'200 4 Ave SW','Calgary','AB','Canada','T2P 2Z6','Calgary Downtown',NULL),
 (206,2,'Hilton Miami Beach',5,'444 Ocean Dr','Miami','FL','USA','33139','Miami Beach',NULL),
 (207,2,'Hilton Chicago Loop',4,'10 S Wabash Ave','Chicago','IL','USA','60603','Chicago Loop',NULL),
 (208,2,'Hilton Seattle Waterfront',4,'9 Alaskan Way','Seattle','WA','USA','98104','Seattle Waterfront',NULL);

-- Chain 3 (301-308)
INSERT INTO hotel(hotel_id, chain_id, hotel_name, star_rating, street, city, state, country, postal_code, area, manager_employee_id) VALUES
 (301,3,'Hyatt Montreal Plateau',3,'50 Ave du Mont-Royal','Montreal','QC','Canada','H2T 2S2','Plateau Montreal',NULL),
 (302,3,'Hyatt Toronto Downtown',4,'250 Yonge St','Toronto','ON','Canada','M5B 2L7','Toronto Downtown',NULL),
 (303,3,'Hyatt Ottawa ByWard',4,'70 Clarence St','Ottawa','ON','Canada','K1N 5P5','ByWard Market',NULL),
 (304,3,'Hyatt Vancouver Pacific',5,'999 Canada Pl','Vancouver','BC','Canada','V6C 3T4','Vancouver Waterfront',NULL),
 (305,3,'Hyatt San Francisco Bay',5,'200 Embarcadero','San Francisco','CA','USA','94105','SF Waterfront',NULL),
 (306,3,'Hyatt Los Angeles Sunset',4,'8000 Sunset Blvd','Los Angeles','CA','USA','90046','Hollywood',NULL),
 (307,3,'Hyatt Dallas Central',3,'400 N Olive St','Dallas','TX','USA','75201','Dallas Downtown',NULL),
 (308,3,'Hyatt New York SoHo',5,'150 Varick St','New York','NY','USA','10013','SoHo',NULL);

-- Chain 4 (401-408)
INSERT INTO hotel(hotel_id, chain_id, hotel_name, star_rating, street, city, state, country, postal_code, area, manager_employee_id) VALUES
 (401,4,'IHG Montreal Airport',3,'5000 Cote-Vertu','Montreal','QC','Canada','H4S 1Z1','Montreal Airport',NULL),
 (402,4,'IHG Quebec City',3,'120 Grande Allee','Quebec City','QC','Canada','G1R 2J8','Quebec Downtown',NULL),
 (403,4,'IHG Toronto Lakeshore',4,'11 Lake Shore Blvd','Toronto','ON','Canada','M5J 2W4','Toronto Waterfront',NULL),
 (404,4,'IHG Ottawa Trainyards',3,'1500 Terminal Ave','Ottawa','ON','Canada','K1G 0Z3','Ottawa East',NULL),
 (405,4,'IHG New York Times Sq',5,'5 Times Sq','New York','NY','USA','10036','NYC Midtown',NULL),
 (406,4,'IHG Washington DC',4,'700 Pennsylvania Ave','Washington','DC','USA','20004','DC Downtown',NULL),
 (407,4,'IHG Houston Galleria',4,'5252 Westheimer','Houston','TX','USA','77056','Galleria',NULL),
 (408,4,'IHG Denver Union',4,'1701 Wynkoop St','Denver','CO','USA','80202','Denver Downtown',NULL);

-- Chain 5 (501-508)
INSERT INTO hotel(hotel_id, chain_id, hotel_name, star_rating, street, city, state, country, postal_code, area, manager_employee_id) VALUES
 (501,5,'Accor Montreal Centre',4,'300 Rue Saint-Jacques','Montreal','QC','Canada','H2Y 1N5','Old Montreal',NULL),
 (502,5,'Accor Toronto Midtown',4,'200 Bloor St','Toronto','ON','Canada','M4W 1A8','Toronto Midtown',NULL),
 (503,5,'Accor Ottawa Central',3,'90 Elgin St','Ottawa','ON','Canada','K1P 5K7','Ottawa Downtown',NULL),
 (504,5,'Accor Vancouver Downtown',5,'777 Burrard St','Vancouver','BC','Canada','V6Z 1X7','Vancouver Downtown',NULL),
 (505,5,'Accor New York Downtown',5,'20 Wall St','New York','NY','USA','10005','Financial District',NULL),
 (506,5,'Accor Boston Back Bay',4,'400 Boylston St','Boston','MA','USA','02116','Back Bay',NULL),
 (507,5,'Accor Miami Brickell',4,'900 Brickell Ave','Miami','FL','USA','33131','Brickell',NULL),
 (508,5,'Accor Chicago River',4,'300 N State St','Chicago','IL','USA','60654','River North',NULL);

-- ---------- ROOMS (5 rooms per hotel, different capacities) ----------
-- Pattern: for each hotel, create room numbers 101..105 with capacities single/double/triple/quad/suite.

DO $$
DECLARE
  hid BIGINT;
  base_room_id BIGINT := 10000;
  rid BIGINT;
BEGIN
  FOR hid IN
    SELECT hotel_id FROM hotel ORDER BY hotel_id
  LOOP
    -- single
    rid := base_room_id + hid*10 + 1;
    INSERT INTO room(room_id, hotel_id, room_number, price_per_night, capacity, view_type, extendable, problem_notes)
    VALUES (rid, hid, '101', 120.00 + (hid % 5)*10, 'single', 'none', false, NULL);

    -- double
    rid := base_room_id + hid*10 + 2;
    INSERT INTO room(room_id, hotel_id, room_number, price_per_night, capacity, view_type, extendable, problem_notes)
    VALUES (rid, hid, '102', 150.00 + (hid % 5)*10, 'double', 'sea', true, NULL);

    -- triple
    rid := base_room_id + hid*10 + 3;
    INSERT INTO room(room_id, hotel_id, room_number, price_per_night, capacity, view_type, extendable, problem_notes)
    VALUES (rid, hid, '103', 180.00 + (hid % 5)*10, 'triple', 'mountain', true, NULL);

    -- quad
    rid := base_room_id + hid*10 + 4;
    INSERT INTO room(room_id, hotel_id, room_number, price_per_night, capacity, view_type, extendable, problem_notes)
    VALUES (rid, hid, '104', 210.00 + (hid % 5)*10, 'quad', 'none', false, 'Minor paint scratch');

    -- suite
    rid := base_room_id + hid*10 + 5;
    INSERT INTO room(room_id, hotel_id, room_number, price_per_night, capacity, view_type, extendable, problem_notes)
    VALUES (rid, hid, '105', 300.00 + (hid % 5)*20, 'suite', 'sea', true, NULL);

    -- Amenities (simple demo): give all rooms WiFi+TV; suites get extra
    INSERT INTO room_amenity(room_id, amenity_id) VALUES
      (base_room_id + hid*10 + 1, 1), (base_room_id + hid*10 + 1, 4),
      (base_room_id + hid*10 + 2, 1), (base_room_id + hid*10 + 2, 4),
      (base_room_id + hid*10 + 3, 1), (base_room_id + hid*10 + 3, 4),
      (base_room_id + hid*10 + 4, 1), (base_room_id + hid*10 + 4, 4),
      (base_room_id + hid*10 + 5, 1), (base_room_id + hid*10 + 5, 4),
      (base_room_id + hid*10 + 5, 5), (base_room_id + hid*10 + 5, 6)
    ON CONFLICT DO NOTHING;

  END LOOP;
END $$;

-- ---------- HOTEL CONTACTS (emails/phones) ----------
-- Add 1 email + 1 phone per hotel (enough for demo)
INSERT INTO hotel_email(hotel_id,email)
SELECT hotel_id, lower(replace(hotel_name,' ','_')) || '@hotel.example'
FROM hotel
ON CONFLICT DO NOTHING;

INSERT INTO hotel_phone(hotel_id,phone)
SELECT hotel_id, '+1-555-' || lpad((hotel_id % 1000)::text, 4, '0')
FROM hotel
ON CONFLICT DO NOTHING;

-- ---------- EMPLOYEES (1 manager per hotel) ----------
-- employee_id pattern: 90000 + hotel_id
INSERT INTO employee(employee_id, hotel_id, full_name, street, city, state, country, postal_code, ssn_sin)
SELECT
  90000 + hotel_id,
  hotel_id,
  'Manager of ' || hotel_name,
  '1 Manager St',
  city, state, country, postal_code,
  'SIN-' || hotel_id::text
FROM hotel
ON CONFLICT DO NOTHING;

-- Assign role Manager to each manager employee
INSERT INTO employee_role(employee_id, role_id)
SELECT 90000 + hotel_id, 1
FROM hotel
ON CONFLICT DO NOTHING;

-- Now set hotel.manager_employee_id (trigger enforces same hotel ✅)
UPDATE hotel
SET manager_employee_id = 90000 + hotel_id
WHERE manager_employee_id IS NULL;

-- ---------- CUSTOMERS ----------
INSERT INTO customer(customer_id, full_name, street, city, state, country, postal_code, id_type, id_value, registered_at) VALUES
 (1,'Alice Martin','10 Rue Sherbrooke','Montreal','QC','Canada','H2X 3Y7','SIN','SIN-ALICE-001','2026-01-10'),
 (2,'Bob Johnson','20 King St','Toronto','ON','Canada','M5H 2N2','DRIVER_LICENCE','DL-BOB-778','2026-02-01'),
 (3,'Carla Gomez','99 Elgin St','Ottawa','ON','Canada','K1P 5K7','PASSPORT','P-CARLA-554','2026-02-15'),
 (4,'David Smith','400 Boylston St','Boston','MA','USA','02116','SSN','SSN-DAVID-909','2026-03-01')
ON CONFLICT DO NOTHING;

-- ---------- SAMPLE BOOKINGS (non-overlapping) ----------
-- Choose a few specific rooms (using our generated ids)
-- room_id = 10000 + hotel_id*10 + room_index

-- Booking 1: Alice books Marriott Downtown Montreal room 102 (double)
INSERT INTO booking(booking_id, customer_id, room_id, start_date, end_date, status, created_at) VALUES
 (1, 1, 10000 + 101*10 + 2, '2026-03-10', '2026-03-12', 'active', now());

-- Booking 2: Bob books Hilton Downtown Montreal East room 105 (suite)
INSERT INTO booking(booking_id, customer_id, room_id, start_date, end_date, status, created_at) VALUES
 (2, 2, 10000 + 201*10 + 5, '2026-03-15', '2026-03-18', 'active', now());

-- Booking 3: Carla books Hyatt Toronto Downtown room 101 (single)
INSERT INTO booking(booking_id, customer_id, room_id, start_date, end_date, status, created_at) VALUES
 (3, 3, 10000 + 302*10 + 1, '2026-03-20', '2026-03-22', 'active', now());

-- Booking 4: David books IHG New York Times Sq room 103 (triple)
INSERT INTO booking(booking_id, customer_id, room_id, start_date, end_date, status, created_at) VALUES
 (4, 4, 10000 + 405*10 + 3, '2026-03-08', '2026-03-10', 'active', now());

-- ---------- SAMPLE RENTINGS ----------
-- Renting from booking: David checks in for booking 4 (employee = manager of hotel 405)
-- renting trigger will:
-- - validate booking active
-- - set booking status checked_in
-- - archive booking snapshot
INSERT INTO renting(renting_id, booking_id, customer_id, room_id, start_date, end_date, checkin_employee_id, created_at) VALUES
 (1, 4, 4, 10000 + 405*10 + 3, '2026-03-08', '2026-03-10', 90000 + 405, now());

-- Walk-in renting: Alice rents Accor Montreal Centre room 101 (single) without booking (booking_id NULL)
INSERT INTO renting(renting_id, booking_id, customer_id, room_id, start_date, end_date, checkin_employee_id, created_at) VALUES
 (2, NULL, 1, 10000 + 501*10 + 1, '2026-03-05', '2026-03-06', 90000 + 501, now());

-- ---------- PAYMENTS (no history required) ----------
INSERT INTO payment(payment_id, renting_id, amount, paid_at, method) VALUES
 (1, 1, 400.00, now(), 'card'),
 (2, 2, 140.00, now(), 'cash');


-- ============================================================
-- 08_server_api.sql
-- ============================================================

-- ------------------------------------------------------------
-- View: total rooms per hotel (needed for UI filter: total number of rooms)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW view_hotel_room_counts AS
SELECT
  h.hotel_id,
  COUNT(r.room_id) AS total_rooms
FROM hotel h
LEFT JOIN room r ON r.hotel_id = h.hotel_id
GROUP BY h.hotel_id;


-- ------------------------------------------------------------
-- Function: search available rooms with optional filters
-- The backend can call this with NULLs for "no filter".
--
-- Availability rule:
-- - no overlap with renting
-- - no overlap with ACTIVE booking
-- overlap if NOT (existing.end <= start OR existing.start >= end)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION api_search_available_rooms(
  p_start_date DATE,
  p_end_date   DATE,
  p_capacity   room_capacity DEFAULT NULL,
  p_area       TEXT DEFAULT NULL,
  p_chain_id   BIGINT DEFAULT NULL,
  p_star_min   INT DEFAULT NULL,
  p_star_max   INT DEFAULT NULL,
  p_total_rooms_min INT DEFAULT NULL,
  p_total_rooms_max INT DEFAULT NULL,
  p_price_min  NUMERIC DEFAULT NULL,
  p_price_max  NUMERIC DEFAULT NULL
)
RETURNS TABLE (
  chain_id BIGINT,
  chain_name TEXT,
  hotel_id BIGINT,
  hotel_name TEXT,
  star_rating INT,
  area TEXT,
  total_rooms BIGINT,
  room_id BIGINT,
  room_number TEXT,
  capacity room_capacity,
  view_type room_view,
  extendable BOOLEAN,
  price_per_night NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_start_date IS NULL OR p_end_date IS NULL THEN
    RAISE EXCEPTION 'start_date and end_date are required';
  END IF;

  IF p_start_date >= p_end_date THEN
    RAISE EXCEPTION 'Invalid date range: start_date must be < end_date';
  END IF;

  RETURN QUERY
  SELECT
    hc.chain_id,
    hc.chain_name,
    h.hotel_id,
    h.hotel_name,
    h.star_rating,
    h.area,
    vrc.total_rooms,
    r.room_id,
    r.room_number,
    r.capacity,
    r.view_type,
    r.extendable,
    r.price_per_night
  FROM room r
  JOIN hotel h ON h.hotel_id = r.hotel_id
  JOIN hotel_chain hc ON hc.chain_id = h.chain_id
  JOIN view_hotel_room_counts vrc ON vrc.hotel_id = h.hotel_id
  WHERE
    -- Optional filters
    (p_capacity IS NULL OR r.capacity = p_capacity)
    AND (p_area IS NULL OR h.area = p_area)
    AND (p_chain_id IS NULL OR hc.chain_id = p_chain_id)
    AND (p_star_min IS NULL OR h.star_rating >= p_star_min)
    AND (p_star_max IS NULL OR h.star_rating <= p_star_max)
    AND (p_total_rooms_min IS NULL OR vrc.total_rooms >= p_total_rooms_min)
    AND (p_total_rooms_max IS NULL OR vrc.total_rooms <= p_total_rooms_max)
    AND (p_price_min IS NULL OR r.price_per_night >= p_price_min)
    AND (p_price_max IS NULL OR r.price_per_night <= p_price_max)

    -- Availability: NOT rented in interval
    AND NOT EXISTS (
      SELECT 1
      FROM renting rt
      WHERE rt.room_id = r.room_id
        AND NOT (rt.end_date <= p_start_date OR rt.start_date >= p_end_date)
    )

    -- Availability: NOT actively booked in interval
    AND NOT EXISTS (
      SELECT 1
      FROM booking b
      WHERE b.room_id = r.room_id
        AND b.status = 'active'
        AND NOT (b.end_date <= p_start_date OR b.start_date >= p_end_date)
    )
  ORDER BY r.price_per_night ASC, hc.chain_name, h.hotel_name, r.room_number;
END;
$$;


-- ------------------------------------------------------------
-- Function: Check-in -> create renting from booking
-- Enforces: booking exists + employee belongs to the same hotel as the room
-- (Your trigger already verifies booking active + matching room/customer, etc.)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION api_check_in_from_booking(
  p_booking_id BIGINT,
  p_employee_id BIGINT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
  b booking%ROWTYPE;
  emp_hotel BIGINT;
  room_hotel BIGINT;
  new_renting_id BIGINT;
BEGIN
  SELECT * INTO b FROM booking WHERE booking_id = p_booking_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking % not found', p_booking_id;
  END IF;

  -- employee must exist and belong to same hotel as the room
  SELECT hotel_id INTO emp_hotel FROM employee WHERE employee_id = p_employee_id;
  IF emp_hotel IS NULL THEN
    RAISE EXCEPTION 'Employee % not found', p_employee_id;
  END IF;

  SELECT hotel_id INTO room_hotel FROM room WHERE room_id = b.room_id;
  IF room_hotel IS NULL THEN
    RAISE EXCEPTION 'Room % not found', b.room_id;
  END IF;

  IF emp_hotel <> room_hotel THEN
    RAISE EXCEPTION 'Employee % cannot check-in booking %: different hotel', p_employee_id, p_booking_id;
  END IF;

  -- Create renting (trigger will set booking status checked_in + archive booking)
  INSERT INTO renting(booking_id, customer_id, room_id, start_date, end_date, checkin_employee_id)
  VALUES (b.booking_id, b.customer_id, b.room_id, b.start_date, b.end_date, p_employee_id)
  RETURNING renting_id INTO new_renting_id;

  RETURN new_renting_id;
END;
$$;


-- ------------------------------------------------------------
-- Function: Walk-in renting (no booking)
-- Enforces: employee hotel == room hotel
-- (Trigger prevents overlap with bookings/rentings)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION api_walk_in_renting(
  p_customer_id BIGINT,
  p_room_id BIGINT,
  p_start_date DATE,
  p_end_date DATE,
  p_employee_id BIGINT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
  emp_hotel BIGINT;
  room_hotel BIGINT;
  new_renting_id BIGINT;
BEGIN
  IF p_start_date IS NULL OR p_end_date IS NULL THEN
    RAISE EXCEPTION 'start_date and end_date are required';
  END IF;

  IF p_start_date >= p_end_date THEN
    RAISE EXCEPTION 'Invalid date range';
  END IF;

  -- validate employee and room belong to same hotel
  SELECT hotel_id INTO emp_hotel FROM employee WHERE employee_id = p_employee_id;
  IF emp_hotel IS NULL THEN
    RAISE EXCEPTION 'Employee % not found', p_employee_id;
  END IF;

  SELECT hotel_id INTO room_hotel FROM room WHERE room_id = p_room_id;
  IF room_hotel IS NULL THEN
    RAISE EXCEPTION 'Room % not found', p_room_id;
  END IF;

  IF emp_hotel <> room_hotel THEN
    RAISE EXCEPTION 'Employee % cannot create renting for room %: different hotel', p_employee_id, p_room_id;
  END IF;

  INSERT INTO renting(booking_id, customer_id, room_id, start_date, end_date, checkin_employee_id)
  VALUES (NULL, p_customer_id, p_room_id, p_start_date, p_end_date, p_employee_id)
  RETURNING renting_id INTO new_renting_id;

  RETURN new_renting_id;
END;
$$;


-- ------------------------------------------------------------
-- Function: Insert payment (the project says payment history not needed,
-- but you still store payments to show UI insert)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION api_add_payment(
  p_renting_id BIGINT,
  p_amount NUMERIC,
  p_method TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
  new_payment_id BIGINT;
BEGIN
  IF p_amount IS NULL OR p_amount < 0 THEN
    RAISE EXCEPTION 'Invalid payment amount';
  END IF;

  INSERT INTO payment(renting_id, amount, method)
  VALUES (p_renting_id, p_amount, p_method)
  RETURNING payment_id INTO new_payment_id;

  RETURN new_payment_id;
END;
$$;


COMMIT;