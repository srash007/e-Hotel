# eHotels Database

This directory contains all SQL scripts required to create, initialize and use the **eHotels database**.

The database supports the hotel reservation system described in the course project, including:

- hotel chains and hotels
- rooms and amenities
- customers and employees
- bookings and rentings
- payment records
- archives of bookings and rentings
- SQL views, triggers, indexes and server API functions

The database is designed for **PostgreSQL**.

---

# Directory Structure

database/
│
├── pgadmin/
│   └── init_pgadmin.sql
│
├── psql/
│   └── init_psql.sql
│
├── sql/
│   ├── 00_drop.sql
│   ├── 01_schema.sql
│   ├── 02_constraints.sql
│   ├── 03_views.sql
│   ├── 04_indexes.sql
│   ├── 05_triggers.sql
│   ├── 06_populate.sql
│   ├── 07_queries.sql
│   └── 08_server_api.sql
│
└── README.md

---

# SQL Scripts Description

## 00_drop.sql

Drops all database objects in the correct order.

Removes:
- tables
- views
- triggers
- types

Used to reset the database before rebuilding it.

---

## 01_schema.sql

Creates the **database schema**, including:

Tables:

- hotel_chain
- hotel
- room
- amenity
- room_amenity
- customer
- employee
- role
- employee_role
- booking
- renting
- payment
- booking_archive
- renting_archive

Also defines ENUM types:

- room_capacity
- room_view
- booking_status

Foreign keys are **not defined here** to simplify creation order.

---

## 02_constraints.sql

Defines database integrity rules.

### Primary Keys

Primary keys are defined in the table definitions.

### Foreign Keys

Examples:

- hotel.chain_id → hotel_chain.chain_id  
- room.hotel_id → hotel.hotel_id  
- booking.customer_id → customer.customer_id  
- renting.room_id → room.room_id  

### Domain Constraints

Examples:

- hotel.star_rating BETWEEN 1 AND 5  
- price_per_night >= 0  
- booking.start_date < booking.end_date  
- payment.amount >= 0  

### User-Defined Constraints

Additional business rules are enforced using triggers.

---

## 03_views.sql

Defines the views required by the project.

### View 1 — Available Rooms Per Area

view_available_rooms_per_area

Shows the number of rooms currently available in each area.

---

### View 2 — Aggregated Capacity of a Hotel

view_hotel_capacity

Displays:

- total number of rooms
- total sleeping capacity

for each hotel.

---

## 04_indexes.sql

Indexes improve query performance.

Examples:

- searching rooms by hotel
- searching hotels by area
- detecting booking conflicts

Indexes include:

- idx_room_hotel_id
- idx_hotel_area
- idx_booking_active_room_dates
- idx_renting_room_dates

These indexes speed up the **room availability search** used by the application.

---

## 05_triggers.sql

Triggers enforce business rules such as:

### Prevent overlapping reservations

A room cannot be:

- rented during another renting
- booked during an existing booking
- rented during an active booking

---

### Booking → Renting

When a renting is created from a booking:

- the booking status becomes **checked_in**
- the booking information is archived

---

### Archive Historical Data

When bookings or rentings are completed or removed:

- their information is copied into  
  - booking_archive  
  - renting_archive  

This ensures historical data remains available even if the original room or customer record is deleted.

---

## 06_populate.sql

Populates the database with demonstration data.

The dataset includes:

- **5 hotel chains**
- **at least 8 hotels per chain**
- **multiple star categories**
- **at least 5 rooms per hotel**

Also includes:

- sample customers
- sample employees
- sample bookings and rentings

These data are used to demonstrate queries, triggers and views.

---

## 07_queries.sql

Contains example SQL queries used for the project demonstration.

Examples include:

- aggregation queries
- nested queries
- availability queries
- business analytics queries

---

## 08_server_api.sql

Defines functions used directly by the **backend server**.

These functions simplify interaction between the web application and the database.

### Room Availability Search

api_search_available_rooms(...)

Supports filtering by:

- date range
- room capacity
- area
- hotel chain
- hotel category (stars)
- number of rooms in the hotel
- price range

---

### Check-in Process

api_check_in_from_booking(...)

Transforms an existing booking into a renting.

---

### Walk-in Renting

api_walk_in_renting(...)

Allows customers to rent a room without a prior booking.

---

### Payment Insertion

api_add_payment(...)

Adds a payment record for a renting.

---

# Database Initialization

Two initialization methods are provided.

---

# Option 1 — pgAdmin (recommended)

Open the file:

database/pgadmin/init_pgadmin.sql

Steps:

1. Open **pgAdmin**
2. Open **Query Tool**
3. Load the file
4. Press **CTRL + A**
5. Press **F5**

This script rebuilds the entire database.

---

# Option 2 — psql terminal

If PostgreSQL CLI is installed, run:

psql -U postgres -d hotel_db -f database/psql/init_psql.sql

This will automatically execute all scripts in the correct order.

---

# Backend Usage

The backend should use the API functions defined in:

08_server_api.sql

Example — Search available rooms:

SELECT * FROM api_search_available_rooms(
  '2026-03-10',
  '2026-03-12',
  'double',
  'Downtown',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  100,
  400
);

Example — Check-in customer:

SELECT api_check_in_from_booking(booking_id, employee_id);

Example — Walk-in renting:

SELECT api_walk_in_renting(customer_id, room_id, start_date, end_date, employee_id);

Example — Insert payment:

SELECT api_add_payment(renting_id, amount, method);

---

# Authors

Sarah Rashiwa
Stefan Wakata
Adam Sawadogo

Course Project – Database Systems  
University of Ottawa  
CSI Course Project – Hotel Reservation System