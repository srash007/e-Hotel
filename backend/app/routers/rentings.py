from fastapi import APIRouter
from ..db import get_conn
from ..schemas import CheckInRequest, WalkInRequest
from ..errors import to_http_error

router = APIRouter(prefix="/rentings", tags=["Rentings"])


@router.post("/check-in")
def check_in_from_booking(payload: CheckInRequest):
    sql = """
    SELECT api_check_in_from_booking(
      %(booking_id)s,
      %(employee_id)s
    ) AS renting_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, payload.model_dump())
                row = cur.fetchone()
                return {"renting_id": row["renting_id"], "message": "Check-in completed successfully"}
    except Exception as e:
        raise to_http_error(e)


@router.post("/walk-in")
def create_walk_in_renting(payload: WalkInRequest):
    sql = """
    SELECT api_walk_in_renting(
      %(customer_id)s,
      %(room_id)s,
      %(start_date)s,
      %(end_date)s,
      %(employee_id)s
    ) AS renting_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, payload.model_dump())
                row = cur.fetchone()
                return {"renting_id": row["renting_id"], "message": "Walk-in renting created successfully"}
    except Exception as e:
        raise to_http_error(e)


@router.get("/active")
def get_active_rentings():
    sql = """
    SELECT
      rt.renting_id,
      rt.booking_id,
      rt.start_date,
      rt.end_date,
      c.customer_id,
      c.full_name AS customer_name,
      e.employee_id,
      e.full_name AS employee_name,
      h.hotel_name,
      hc.chain_name,
      r.room_id,
      r.room_number
    FROM renting rt
    JOIN customer c ON c.customer_id = rt.customer_id
    JOIN employee e ON e.employee_id = rt.checkin_employee_id
    JOIN room r ON r.room_id = rt.room_id
    JOIN hotel h ON h.hotel_id = r.hotel_id
    JOIN hotel_chain hc ON hc.chain_id = h.chain_id
    ORDER BY rt.start_date, rt.renting_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                return cur.fetchall()
    except Exception as e:
        raise to_http_error(e)