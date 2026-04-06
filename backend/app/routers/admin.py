from fastapi import APIRouter
from ..db import get_conn
from ..schemas import CustomerCreate, CustomerUpdate, EmployeeCreate, EmployeeUpdate, HotelCreate, HotelUpdate, RoomCreate, RoomUpdate
from ..errors import to_http_error

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/customers")
def list_customers():
    sql = """
    SELECT customer_id, full_name, street, city, state, country, postal_code,
           id_type, id_value, registered_at
    FROM customer
    ORDER BY customer_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                return cur.fetchall()
    except Exception as e:
        raise to_http_error(e)


@router.post("/customers")
def create_customer(payload: CustomerCreate):
    sql = """
    INSERT INTO customer (
      full_name, street, city, state, country, postal_code, id_type, id_value
    )
    VALUES (
      %(full_name)s, %(street)s, %(city)s, %(state)s, %(country)s, %(postal_code)s, %(id_type)s, %(id_value)s
    )
    RETURNING customer_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, payload.model_dump())
                row = cur.fetchone()
                return {"customer_id": row["customer_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.patch("/customers/{customer_id}")
def update_customer(customer_id: int, payload: CustomerUpdate):
    data = payload.model_dump(exclude_none=True)
    if not data:
        return {"ok": True, "message": "Nothing to update"}

    set_clause = ", ".join([f"{key} = %({key})s" for key in data.keys()])
    data["customer_id"] = customer_id

    sql = f"""
    UPDATE customer
    SET {set_clause}
    WHERE customer_id = %(customer_id)s
    RETURNING customer_id;
    """

    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, data)
                row = cur.fetchone()
                if not row:
                    return {"ok": False, "message": "Customer not found"}
                return {"ok": True, "customer_id": row["customer_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.delete("/customers/{customer_id}")
def delete_customer(customer_id: int):
    sql = "DELETE FROM customer WHERE customer_id = %(customer_id)s RETURNING customer_id;"
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, {"customer_id": customer_id})
                row = cur.fetchone()
                if not row:
                    return {"ok": False, "message": "Customer not found"}
                return {"ok": True, "customer_id": row["customer_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.get("/employees")
def list_employees():
    sql = """
    SELECT e.employee_id, e.full_name, e.hotel_id, h.hotel_name,
           e.street, e.city, e.state, e.country, e.postal_code, e.ssn_sin
    FROM employee e
    JOIN hotel h ON h.hotel_id = e.hotel_id
    ORDER BY e.employee_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                return cur.fetchall()
    except Exception as e:
        raise to_http_error(e)


@router.post("/employees")
def create_employee(payload: EmployeeCreate):
    sql = """
    INSERT INTO employee (
      hotel_id, full_name, street, city, state, country, postal_code, ssn_sin
    )
    VALUES (
      %(hotel_id)s, %(full_name)s, %(street)s, %(city)s, %(state)s, %(country)s, %(postal_code)s, %(ssn_sin)s
    )
    RETURNING employee_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, payload.model_dump())
                row = cur.fetchone()
                return {"employee_id": row["employee_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.patch("/employees/{employee_id}")
def update_employee(employee_id: int, payload: EmployeeUpdate):
    data = payload.model_dump(exclude_none=True)
    if not data:
        return {"ok": True, "message": "Nothing to update"}
    set_clause = ", ".join([f"{key} = %({key})s" for key in data.keys()])
    data["employee_id"] = employee_id
    sql = f"UPDATE employee SET {set_clause} WHERE employee_id = %(employee_id)s RETURNING employee_id;"
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, data)
                row = cur.fetchone()
                if not row:
                    return {"ok": False, "message": "Employee not found"}
                return {"ok": True, "employee_id": row["employee_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.delete("/employees/{employee_id}")
def delete_employee(employee_id: int):
    sql = "DELETE FROM employee WHERE employee_id = %(employee_id)s RETURNING employee_id;"
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, {"employee_id": employee_id})
                row = cur.fetchone()
                if not row:
                    return {"ok": False, "message": "Employee not found"}
                return {"ok": True, "employee_id": row["employee_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.get("/hotels")
def list_hotels():
    sql = """
    SELECT h.hotel_id, h.hotel_name, h.star_rating, h.street, h.city, h.state,
           h.country, h.postal_code, h.area, h.chain_id, hc.chain_name
    FROM hotel h
    JOIN hotel_chain hc ON hc.chain_id = h.chain_id
    ORDER BY h.hotel_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                return cur.fetchall()
    except Exception as e:
        raise to_http_error(e)


@router.post("/hotels")
def create_hotel(payload: HotelCreate):
    sql = """
    INSERT INTO hotel (
      chain_id, hotel_name, star_rating, street, city, state, country, postal_code, area
    )
    VALUES (
      %(chain_id)s, %(hotel_name)s, %(star_rating)s, %(street)s, %(city)s, %(state)s, %(country)s, %(postal_code)s, %(area)s
    )
    RETURNING hotel_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, payload.model_dump())
                row = cur.fetchone()
                return {"hotel_id": row["hotel_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.patch("/hotels/{hotel_id}")
def update_hotel(hotel_id: int, payload: HotelUpdate):
    data = payload.model_dump(exclude_none=True)
    if not data:
        return {"ok": True, "message": "Nothing to update"}
    set_clause = ", ".join([f"{key} = %({key})s" for key in data.keys()])
    data["hotel_id"] = hotel_id
    sql = f"UPDATE hotel SET {set_clause} WHERE hotel_id = %(hotel_id)s RETURNING hotel_id;"
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, data)
                row = cur.fetchone()
                if not row:
                    return {"ok": False, "message": "Hotel not found"}
                return {"ok": True, "hotel_id": row["hotel_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.delete("/hotels/{hotel_id}")
def delete_hotel(hotel_id: int):
    sql = "DELETE FROM hotel WHERE hotel_id = %(hotel_id)s RETURNING hotel_id;"
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, {"hotel_id": hotel_id})
                row = cur.fetchone()
                if not row:
                    return {"ok": False, "message": "Hotel not found"}
                return {"ok": True, "hotel_id": row["hotel_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.get("/rooms")
def list_rooms():
    sql = """
    SELECT r.room_id, r.room_number, r.price_per_night, r.capacity, r.view_type,
           r.extendable, r.problem_notes, r.hotel_id, h.hotel_name
    FROM room r
    JOIN hotel h ON h.hotel_id = r.hotel_id
    ORDER BY r.hotel_id, r.room_number;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                return cur.fetchall()
    except Exception as e:
        raise to_http_error(e)


@router.post("/rooms")
def create_room(payload: RoomCreate):
    sql = """
    INSERT INTO room (
      hotel_id, room_number, price_per_night, capacity, view_type, extendable, problem_notes
    )
    VALUES (
      %(hotel_id)s, %(room_number)s, %(price_per_night)s, %(capacity)s, %(view_type)s, %(extendable)s, %(problem_notes)s
    )
    RETURNING room_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, payload.model_dump())
                row = cur.fetchone()
                return {"room_id": row["room_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.patch("/rooms/{room_id}")
def update_room(room_id: int, payload: RoomUpdate):
    data = payload.model_dump(exclude_none=True)
    if not data:
        return {"ok": True, "message": "Nothing to update"}
    set_clause = ", ".join([f"{key} = %({key})s" for key in data.keys()])
    data["room_id"] = room_id
    sql = f"UPDATE room SET {set_clause} WHERE room_id = %(room_id)s RETURNING room_id;"
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, data)
                row = cur.fetchone()
                if not row:
                    return {"ok": False, "message": "Room not found"}
                return {"ok": True, "room_id": row["room_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.delete("/rooms/{room_id}")
def delete_room(room_id: int):
    sql = "DELETE FROM room WHERE room_id = %(room_id)s RETURNING room_id;"
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, {"room_id": room_id})
                row = cur.fetchone()
                if not row:
                    return {"ok": False, "message": "Room not found"}
                return {"ok": True, "room_id": row["room_id"]}
    except Exception as e:
        raise to_http_error(e)


@router.get("/views/available-rooms-per-area")
def view_available_rooms_per_area():
    sql = "SELECT * FROM view_available_rooms_per_area;"
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                return cur.fetchall()
    except Exception as e:
        raise to_http_error(e)


@router.get("/views/hotel-capacity")
def view_hotel_capacity():
    sql = "SELECT * FROM view_hotel_capacity ORDER BY hotel_id;"
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                return cur.fetchall()
    except Exception as e:
        raise to_http_error(e)