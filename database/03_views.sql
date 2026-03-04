-- ============================================================
-- 03_views.sql
-- Required views:
-- View 1: number of available rooms per area
-- View 2: aggregated capacity of all rooms of a specific hotel
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