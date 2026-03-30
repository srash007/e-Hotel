from contextlib import contextmanager
import psycopg
from psycopg.rows import dict_row
from .settings import settings


@contextmanager
def get_conn():
    conn = psycopg.connect(settings.DATABASE_URL, row_factory=dict_row)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()