from fastapi import APIRouter
from ..db import get_conn
from ..schemas import PaymentCreate
from ..errors import to_http_error

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("")
def add_payment(payload: PaymentCreate):
    sql = """
    SELECT api_add_payment(
      %(renting_id)s,
      %(amount)s,
      %(method)s
    ) AS payment_id;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, payload.model_dump())
                row = cur.fetchone()
                return {"payment_id": row["payment_id"], "message": "Payment added successfully"}
    except Exception as e:
        raise to_http_error(e)


@router.get("")
def list_payments():
    sql = """
    SELECT
      p.payment_id,
      p.amount,
      p.method,
      p.paid_at,
      rt.renting_id,
      h.hotel_name,
      hc.chain_name,
      r.room_number
    FROM payment p
    JOIN renting rt ON rt.renting_id = p.renting_id
    JOIN room r ON r.room_id = rt.room_id
    JOIN hotel h ON h.hotel_id = r.hotel_id
    JOIN hotel_chain hc ON hc.chain_id = h.chain_id
    ORDER BY p.paid_at DESC;
    """
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                return cur.fetchall()
    except Exception as e:
        raise to_http_error(e)