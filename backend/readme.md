# Backend Guide — eHotels Database

This guide explains how the backend server should interact with the **eHotels PostgreSQL database**.

It describes:

- how to initialize the database
- which SQL functions the backend should call
- which tables can be modified by the application
- how the main workflows (search, booking, check-in, renting, payment) work

The backend **should rely on the API functions defined in `08_server_api.sql` whenever possible** instead of directly manipulating the tables.

---

# 1. Database Initialization

The database can be initialized using either **pgAdmin** or **psql**.

---

## Option 1 — pgAdmin (recommended)

1. Open **pgAdmin**
2. Open **Query Tool**
3. Load the file:

```
database/pgadmin/init_pgadmin.sql
```

4. Press:

```
CTRL + A
```

5. Then execute:

```
F5
```

This script will automatically create:

- all tables
- constraints
- indexes
- triggers
- views
- server API functions
- sample data

---

## Option 2 — psql terminal

If PostgreSQL CLI tools are installed:

```
psql -U postgres -d hotel_db -f database/psql/init_psql.sql
```

---

# 2. Main Database Entities

The backend interacts with the following main tables.

### Hotel infrastructure

```
hotel_chain
hotel
room
amenity
room_amenity
```

### Users

```
customer
employee
employee_role
role
```

### Reservation system

```
booking
renting
payment
```

### Historical archives

```
booking_archive
renting_archive
```

Archives ensure that booking and renting history is preserved even if rooms or customers are removed.

---

# 3. Views Available for the Application

These views should be displayed in the user interface.

### Available rooms per area

```
view_available_rooms_per_area
```

Returns the number of available rooms grouped by area.

---

### Hotel capacity

```
view_hotel_capacity
```

Returns for each hotel:

- total number of rooms
- aggregated sleeping capacity

---

# 4. Server API Functions

The backend should interact with the database using the functions defined in:

```
sql/08_server_api.sql
```

These functions implement business logic and guarantee consistency.

---

# 5. Search Available Rooms

Main function used by the application:

```
api_search_available_rooms(
 start_date,
 end_date,
 capacity,
 area,
 chain_id,
 star_min,
 star_max,
 total_rooms_min,
 total_rooms_max,
 price_min,
 price_max
)
```

Example:

```
SELECT * FROM api_search_available_rooms(
 '2026-03-10',
 '2026-03-12',
 'double',
 'Downtown',
 NULL,
 3,
 5,
 NULL,
 NULL,
 100,
 400
);
```

The function automatically:

- filters hotels
- filters rooms
- checks booking conflicts
- checks renting conflicts
- returns only available rooms

Returned fields include:

```
chain_name
hotel_name
area
star_rating
room_number
capacity
price_per_night
```

---

# 6. Create a Booking

Bookings are created directly in the `booking` table.

Example:

```
INSERT INTO booking(
 customer_id,
 room_id,
 start_date,
 end_date
)
VALUES(
 1,
 5001,
 '2026-03-10',
 '2026-03-12'
);
```

Triggers will automatically reject overlapping bookings.

---

# 7. Check-In Process

When a customer arrives with a booking, the backend must call:

```
api_check_in_from_booking(
 booking_id,
 employee_id
)
```

Example:

```
SELECT api_check_in_from_booking(12, 2003);
```

This function will:

1. create a renting record
2. update the booking status to `checked_in`
3. archive booking information

---

# 8. Walk-in Renting (No Booking)

If a customer arrives without a reservation:

```
SELECT api_walk_in_renting(
 customer_id,
 room_id,
 start_date,
 end_date,
 employee_id
);
```

Example:

```
SELECT api_walk_in_renting(
 3,
 5012,
 '2026-03-15',
 '2026-03-17',
 2001
);
```

Triggers will ensure that the room is not already rented or booked.

---

# 9. Insert a Payment

Payments are recorded using:

```
api_add_payment(
 renting_id,
 amount,
 method
)
```

Example:

```
SELECT api_add_payment(
 25,
 180.00,
 'card'
);
```

Payment methods allowed:

```
cash
card
online
transfer
```

---

# 10. Tables the Backend May Modify

The application may perform CRUD operations on:

### Customers

```
customer
```

### Employees

```
employee
employee_role
```

### Hotels

```
hotel
hotel_email
hotel_phone
```

### Rooms

```
room
room_amenity
```

### Bookings

```
booking
```

---

# 11. Tables That Should Not Be Modified Directly

The backend should **not modify these tables directly**:

```
booking_archive
renting_archive
```

These tables are maintained automatically by triggers.

---

# 12. Important Database Constraints

Several rules are enforced by the database.

### Date constraints

```
start_date < end_date
```

Invalid dates will be rejected.

---

### Room availability constraints

Triggers prevent:

- overlapping bookings
- overlapping rentings
- renting during active bookings

---

### Employee constraints

An employee performing a check-in must belong to the same hotel as the room.

---

# 13. Typical Application Flow

### Step 1 — Search

Frontend sends filters.

Backend calls:

```
api_search_available_rooms(...)
```

---

### Step 2 — Booking

Customer selects a room.

Backend inserts into:

```
booking
```

---

### Step 3 — Check-in

Employee validates booking.

Backend calls:

```
api_check_in_from_booking(...)
```

---

### Step 4 — Walk-in renting

If no booking exists:

```
api_walk_in_renting(...)
```

---

### Step 5 — Payment

Employee records payment.

Backend calls:

```
api_add_payment(...)
```

---

# 14. Example Backend Call (Node.js)

Example using parameterized queries:

```
const result = await db.query(
 `SELECT * FROM api_search_available_rooms(
   $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11
 )`,
 [
   startDate,
   endDate,
   capacity,
   area,
   chainId,
   starMin,
   starMax,
   roomsMin,
   roomsMax,
   priceMin,
   priceMax
 ]
);
```

---

# 15. Summary

The backend should:

- initialize the database using `init_pgadmin.sql` or `init_psql.sql`
- call the functions defined in `08_server_api.sql`
- avoid direct manipulation of archive tables
- rely on database triggers to enforce business rules

This design ensures that:

- the application remains consistent
- booking conflicts are prevented
- historical data is preserved
- the backend logic remains simple