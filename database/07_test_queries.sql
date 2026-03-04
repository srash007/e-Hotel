-- ============================================================
-- 07_test_queries.sql
-- At least 4 queries:
-- - include >=1 aggregation query
-- - include >=1 nested query
-- ============================================================

-- ------------------------------------------------------------
-- Query 1 (AGGREGATION): number of hotels per chain + avg star rating
-- ------------------------------------------------------------
SELECT
  hc.chain_name,
  COUNT(h.hotel_id) AS num_hotels,
  ROUND(AVG(h.star_rating)::numeric, 2) AS avg_star_rating
FROM hotel_chain hc
JOIN hotel h ON h.chain_id = hc.chain_id
GROUP BY hc.chain_name
ORDER BY num_hotels DESC;


-- ------------------------------------------------------------
-- Query 2 (NESTED QUERY): rooms priced ABOVE the average price of their own hotel
-- (nested subquery in WHERE)
-- ------------------------------------------------------------
SELECT
  h.hotel_name,
  r.room_number,
  r.capacity,
  r.price_per_night
FROM room r
JOIN hotel h ON h.hotel_id = r.hotel_id
WHERE r.price_per_night >
  (SELECT AVG(r2.price_per_night)
   FROM room r2
   WHERE r2.hotel_id = r.hotel_id)
ORDER BY h.hotel_name, r.price_per_night DESC;


-- ------------------------------------------------------------
-- Query 3 (Availability search example): available rooms with filters
-- Criteria example: dates + area + chain + category + capacity + price range
-- ------------------------------------------------------------
-- Example parameters (edit as needed)
-- Desired interval: 2026-03-10 to 2026-03-12
SELECT
  hc.chain_name,
  h.hotel_name,
  h.star_rating,
  h.area,
  r.room_id,
  r.room_number,
  r.capacity,
  r.price_per_night
FROM room r
JOIN hotel h ON h.hotel_id = r.hotel_id
JOIN hotel_chain hc ON hc.chain_id = h.chain_id
WHERE
  h.area = 'Downtown Montreal'
  AND hc.chain_name IN ('Marriott Group','Hilton Worldwide')
  AND h.star_rating >= 3
  AND r.capacity IN ('double','suite')
  AND r.price_per_night BETWEEN 100 AND 400

  -- Not rented in that interval
  AND NOT EXISTS (
    SELECT 1 FROM renting rt
    WHERE rt.room_id = r.room_id
      AND NOT (rt.end_date <= DATE '2026-03-10' OR rt.start_date >= DATE '2026-03-12')
  )

  -- Not booked (active) in that interval
  AND NOT EXISTS (
    SELECT 1 FROM booking b
    WHERE b.room_id = r.room_id
      AND b.status = 'active'
      AND NOT (b.end_date <= DATE '2026-03-10' OR b.start_date >= DATE '2026-03-12')
  )
ORDER BY r.price_per_night ASC;


-- ------------------------------------------------------------
-- Query 4: Employees who performed the most check-ins (rentings) per hotel
-- (aggregation + group by)
-- ------------------------------------------------------------
SELECT
  h.hotel_name,
  e.full_name AS employee_name,
  COUNT(*) AS num_checkins
FROM renting rt
JOIN employee e ON e.employee_id = rt.checkin_employee_id
JOIN hotel h ON h.hotel_id = e.hotel_id
GROUP BY h.hotel_name, e.full_name
ORDER BY num_checkins DESC, h.hotel_name;


-- ------------------------------------------------------------
-- Query 5 (View demo): View 1 - available rooms per area (for current date)
-- ------------------------------------------------------------
SELECT * FROM view_available_rooms_per_area;


-- ------------------------------------------------------------
-- Query 6 (View demo): View 2 - aggregated capacity per hotel
-- Example: show capacity for one hotel
-- ------------------------------------------------------------
SELECT *
FROM view_hotel_capacity
WHERE hotel_id IN (101, 201, 405)
ORDER BY hotel_id;


-- ------------------------------------------------------------
-- Query 7 (Archive demo): Show archived bookings created by triggers
-- ------------------------------------------------------------
SELECT
  booking_archive_id,
  original_booking_id,
  archived_at,
  customer_full_name,
  hotel_name,
  room_number,
  start_date,
  end_date,
  status
FROM booking_archive
ORDER BY archived_at DESC
LIMIT 10;


-- ------------------------------------------------------------
-- Query 8: average room price by hotel star rating (aggregation)
-- ------------------------------------------------------------

SELECT
  h.star_rating,
  COUNT(r.room_id) AS num_rooms,
  ROUND(AVG(r.price_per_night)::numeric, 2) AS avg_price
FROM hotel h
JOIN room r ON r.hotel_id = h.hotel_id
GROUP BY h.star_rating
ORDER BY h.star_rating;

-- ------------------------------------------------------------
-- Query 9: hotels whose average room price is above the global average (nested query)
-- ------------------------------------------------------------
SELECT
  h.hotel_id,
  h.hotel_name,
  ROUND(AVG(r.price_per_night)::numeric, 2) AS hotel_avg_price
FROM hotel h
JOIN room r ON r.hotel_id = h.hotel_id
GROUP BY h.hotel_id, h.hotel_name
HAVING AVG(r.price_per_night) >
  (SELECT AVG(price_per_night) FROM room)
ORDER BY hotel_avg_price DESC;

-- ------------------------------------------------------------
-- Query 10: rooms and their amenities list (aggregation + string_agg)  
-- ------------------------------------------------------------

SELECT
  h.hotel_name,
  r.room_number,
  r.capacity,
  r.price_per_night,
  STRING_AGG(a.amenity_name, ', ' ORDER BY a.amenity_name) AS amenities
FROM room r
JOIN hotel h ON h.hotel_id = r.hotel_id
LEFT JOIN room_amenity ra ON ra.room_id = r.room_id
LEFT JOIN amenity a ON a.amenity_id = ra.amenity_id
GROUP BY h.hotel_name, r.room_number, r.capacity, r.price_per_night
ORDER BY h.hotel_name, r.room_number;
-- ------------------------------------------------------------
-- Query 11: top 5 hotels with most suites (aggregation + group by)
-- ------------------------------------------------------------

SELECT
  h.hotel_name,
  SUM(CASE WHEN r.capacity = 'suite' THEN 1 ELSE 0 END) AS num_suites
FROM hotel h
JOIN room r ON r.hotel_id = h.hotel_id
GROUP BY h.hotel_name
ORDER BY num_suites DESC, h.hotel_name
LIMIT 5;


-- ------------------------------------------------------------
-- Query 12: customers who currently have at least one ACTIVE booking (nested EXISTS)
-- ------------------------------------------------------------
SELECT
  c.customer_id,
  c.full_name
FROM customer c
WHERE EXISTS (
  SELECT 1
  FROM booking b
  WHERE b.customer_id = c.customer_id
    AND b.status = 'active'
)
ORDER BY c.customer_id;
-- ------------------------------------------------------------
-- Query 13: total collected payments per hotel (aggregation)
-- ------------------------------------------------------------

SELECT
  h.hotel_name,
  ROUND(SUM(p.amount)::numeric, 2) AS total_revenue
FROM payment p
JOIN renting rt ON rt.renting_id = p.renting_id
JOIN room r ON r.room_id = rt.room_id
JOIN hotel h ON h.hotel_id = r.hotel_id
GROUP BY h.hotel_name
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- Query 14: active bookings starting in the next 30 days
-- ------------------------------------------------------------

SELECT
  b.booking_id,
  c.full_name,
  h.hotel_name,
  r.room_number,
  b.start_date,
  b.end_date,
  b.status
FROM booking b
JOIN customer c ON c.customer_id = b.customer_id
JOIN room r ON r.room_id = b.room_id
JOIN hotel h ON h.hotel_id = r.hotel_id
WHERE b.status = 'active'
  AND b.start_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + 30)
ORDER BY b.start_date, h.hotel_name;


-- ------------------------------------------------------------
-- Query 15: rooms priced above their chain's average (nested subquery)
-- ------------------------------------------------------------

SELECT
  hc.chain_name,
  h.hotel_name,
  r.room_number,
  r.capacity,
  r.price_per_night
FROM room r
JOIN hotel h ON h.hotel_id = r.hotel_id
JOIN hotel_chain hc ON hc.chain_id = h.chain_id
WHERE r.price_per_night >
  (SELECT AVG(r2.price_per_night)
   FROM room r2
   JOIN hotel h2 ON h2.hotel_id = r2.hotel_id
   WHERE h2.chain_id = h.chain_id)
ORDER BY hc.chain_name, r.price_per_night DESC;


-- ------------------------------------------------------------
-- Query 16: number of available rooms per hotel for a given interval (aggregation)
-- ------------------------------------------------------------

SELECT
  h.hotel_name,
  h.area,
  COUNT(*) AS available_rooms
FROM room r
JOIN hotel h ON h.hotel_id = r.hotel_id
WHERE
  NOT EXISTS (
    SELECT 1 FROM renting rt
    WHERE rt.room_id = r.room_id
      AND NOT (rt.end_date <= DATE '2026-03-10' OR rt.start_date >= DATE '2026-03-12')
  )
  AND NOT EXISTS (
    SELECT 1 FROM booking b
    WHERE b.room_id = r.room_id
      AND b.status = 'active'
      AND NOT (b.end_date <= DATE '2026-03-10' OR b.start_date >= DATE '2026-03-12')
  )
GROUP BY h.hotel_name, h.area
ORDER BY available_rooms DESC, h.hotel_name;


-- ------------------------------------------------------------
-- Query 17: rooms with reported problems or damages
-- ------------------------------------------------------------

SELECT
  hc.chain_name,
  h.hotel_name,
  r.room_number,
  r.problem_notes
FROM room r
JOIN hotel h ON h.hotel_id = r.hotel_id
JOIN hotel_chain hc ON hc.chain_id = h.chain_id
WHERE r.problem_notes IS NOT NULL
ORDER BY hc.chain_name, h.hotel_name, r.room_number;


-- ------------------------------------------------------------
-- Query 18: hotels that have at least one sea view room AND one mountain view room (nested EXISTS)
-- ------------------------------------------------------------

SELECT
  h.hotel_id,
  h.hotel_name,
  h.area
FROM hotel h
WHERE EXISTS (
  SELECT 1
  FROM room r1
  WHERE r1.hotel_id = h.hotel_id
    AND r1.view_type = 'sea'
)
AND EXISTS (
  SELECT 1
  FROM room r2
  WHERE r2.hotel_id = h.hotel_id
    AND r2.view_type = 'mountain'
)
ORDER BY h.hotel_name;