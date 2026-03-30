from fastapi import APIRouter
from ..db import get_conn
from ..schemas import AvailabilitySearchParams
from ..errors import to_http_error

router = APIRouter(prefix="/search", tags=["Search"])


@router.post("/available-rooms")
def search_available_rooms(payload: AvailabilitySearchParams):
    sql = """
    SELECT * FROM api_search_available_rooms(
      %(start_date)s,
      %(end_date)s,
      %(capacity)s,
      %(area)s,
      %(chain_id)s,
      %(star_min)s,
      %(star_max)s,
      %(total_rooms_min)s,
      %(total_rooms_max)s,
      %(price_min)s,
      %(price_max)s
    );
    """

    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, payload.model_dump())
                return cur.fetchall()
    except Exception as e:
        raise to_http_error(e)


@router.get("/filters")
def get_filter_options():
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT DISTINCT area FROM hotel ORDER BY area;")
                areas = [row["area"] for row in cur.fetchall()]

                cur.execute("SELECT chain_id, chain_name FROM hotel_chain ORDER BY chain_name;")
                chains = cur.fetchall()

                cur.execute("SELECT DISTINCT star_rating FROM hotel ORDER BY star_rating;")
                stars = [row["star_rating"] for row in cur.fetchall()]

                capacities = ["single", "double", "triple", "quad", "suite"]

                cur.execute("SELECT MIN(price_per_night) AS min_price, MAX(price_per_night) AS max_price FROM room;")
                price_range = cur.fetchone()

                return {
                    "areas": areas,
                    "chains": chains,
                    "stars": stars,
                    "capacities": capacities,
                    "price_range": price_range
                }
    except Exception as e:
        raise to_http_error(e)