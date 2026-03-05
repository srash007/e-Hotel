-- ============================================================
-- 05_triggers.sql
-- Triggers enforcing user-defined constraints + archiving
-- PostgreSQL (PL/pgSQL)
-- ============================================================

-- ============================================================
-- Helper: overlap predicate (written inline in queries below)
-- Overlap exists if NOT (existing.end <= new.start OR existing.start >= new.end)
-- ============================================================

-- ============================================================
-- TRIGGER 1: Prevent overlapping ACTIVE bookings for the same room
-- Also prevent booking overlap with existing rentings
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


-- ============================================================
-- OPTIONAL (useful for the "archives" requirement):
-- Archive on DELETE of booking / renting (so history survives)
-- You can keep these ON to showcase archiving in demo.
-- ============================================================

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