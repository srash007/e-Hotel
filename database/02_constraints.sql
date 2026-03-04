-- ============================================================
-- 02_constraints.sql
-- Adds: Foreign Keys + CHECK constraints + a few UNIQUE constraints
-- Notes:
-- - Some "business rules" will be enforced later with TRIGGERS (05_triggers.sql)
-- ============================================================

-- ---------- FOREIGN KEYS (structure hierarchy) ----------
-- Chain -> Hotel (cascade)
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


-- ---------- USER-DEFINED CONSTRAINTS (to be enforced later by triggers) ----------
-- 1) No overlapping active bookings for the same room
-- 2) No overlap between rentings and bookings on the same room
-- 3) If renting.booking_id is not null, it must match the booking's room/customer, and booking becomes checked_in
-- 4) manager must be an employee of the same hotel
-- These go in 05_triggers.sql.