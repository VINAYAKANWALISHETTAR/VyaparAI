from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database.mongodb import db
from app.database.indexes import create_indexes
from app.api.users import router as users_router
from app.api.businesses import router as businesses_router
from app.api.auth import router as auth_router
from app.api.invoices import router as invoices_router
from app.api.transactions import router as transactions_router
from app.api.ocr import router as ocr_router
from app.api.financials import router as financials_router
from app.api.copilot import router as copilot_router
from app.api.voice import router as voice_router

app = FastAPI(
    title="VyaparAI API",
    description="AI Financial Copilot for Small Businesses",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup_event():
    create_indexes()


app.include_router(businesses_router)
app.include_router(users_router)
app.include_router(auth_router)
app.include_router(invoices_router)
app.include_router(transactions_router)
app.include_router(ocr_router)
app.include_router(financials_router)
app.include_router(copilot_router)
app.include_router(voice_router)


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
    db.command("ping")

    return {
        "database": db.name,
        "status": "connected"
    }