-- ============================================================
-- 04_indexes.sql
-- At least 3 indexes + rationale in the report
-- Focus: real-time availability search & frequent filtering
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
  