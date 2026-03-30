from fastapi import HTTPException
import psycopg


def to_http_error(exc: Exception) -> HTTPException:
    detail = str(exc)

    if isinstance(exc, psycopg.Error):
        if getattr(exc, "diag", None) and getattr(exc.diag, "message_primary", None):
            detail = exc.diag.message_primary

    return HTTPException(status_code=400, detail=detail)