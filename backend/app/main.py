from fastapi import FastAPI

from app.database.mongodb import client, db
from app.api.users import router as users_router
from app.api.businesses import router as businesses_router
from app.api.auth import router as auth_router

app = FastAPI(
    title="VyaparAI API",
    description="AI Financial Copilot for Small Businesses",
    version="1.0.0",
)

app.include_router(businesses_router)
app.include_router(users_router)
app.include_router(auth_router)


@app.get("/")
def root():
    return {
        "message": "VyaparAI Backend is running"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }


@app.get("/health/database")
def database_health():
    client.admin.command("ping")

    return {
        "database": db.name,
        "status": "connected"
    }