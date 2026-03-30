from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .settings import settings
from .routers import all_routers

app = FastAPI(
    title="eHotels API",
    version="1.0.0",
    description="Backend API for the eHotels reservation and renting system"
)

origins = [origin.strip() for origin in settings.CORS_ORIGINS.split(",") if origin.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

for router in all_routers:
    app.include_router(router)


@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok"}