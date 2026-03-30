from .search import router as search_router
from .bookings import router as bookings_router
from .rentings import router as rentings_router
from .payments import router as payments_router
from .admin import router as admin_router

all_routers = [
    search_router,
    bookings_router,
    rentings_router,
    payments_router,
    admin_router,
]