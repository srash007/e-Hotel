from fastapi import APIRouter
from ..db import get_conn
from ..schemas import BookingCreate, BookingCancel
from ..errors import to_http_error

router = APIRouter(prefix="/bookings", tags=["Bookings"])


@router.post("")
def create_booking(payload: BookingCreate):
    sql = """
    INSERT INTO booking (customer_id, room_id, start_date, end_date, status)
    VALUES (%(customer_id)s, %(room_id)s, %(start_date)s, %(end_date)s, 'active')
    RETURNING booking_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, payload.model_dump())
                row = cur.fetchone()
                return {"booking_id": row["booking_id"], "message": "Booking created successfully"}
    except Exception as e:
        raise to_http_error(e)


@router.get("/active")
def get_active_bookings():
    sql = """
    SELECT
      b.booking_id,
      b.start_date,
      b.end_date,
      b.status,
      c.customer_id,
      c.full_name AS customer_name,
      h.hotel_id,
      h.hotel_name,
      hc.chain_name,
      r.room_id,
      r.room_number
    FROM booking b
    JOIN customer c ON c.customer_id = b.customer_id
    JOIN room r ON r.room_id = b.room_id
    JOIN hotel h ON h.hotel_id = r.hotel_id
    JOIN hotel_chain hc ON hc.chain_id = h.chain_id
    WHERE b.status = 'active'
    ORDER BY b.start_date, b.booking_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                return cur.fetchall()
    except Exception as e:
        raise to_http_error(e)


@router.post("/cancel")
def cancel_booking(payload: BookingCancel):
    sql = """
    UPDATE booking
    SET status = 'cancelled'
    WHERE booking_id = %(booking_id)s
    RETURNING booking_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, payload.model_dump())
                row = cur.fetchone()
                if not row:
                    return {"ok": False, "message": "Booking not found"}
                return {"ok": True, "booking_id": row["booking_id"], "message": "Booking cancelled"}
    except Exception as e:
        raise to_http_error(e)