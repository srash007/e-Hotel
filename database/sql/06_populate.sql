-- ============================================================
-- 06_populate.sql
-- Sample data for demo (5 chains, 40 hotels, 200 rooms, etc.)
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