-- ============================================================
-- 08_server_api.sql
-- "Server-ready" layer: views + functions for backend calls
-- PostgreSQL / pgAdmin-compatible
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