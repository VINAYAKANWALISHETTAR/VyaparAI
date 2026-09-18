from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import client, database


@asynccontextmanager
async def lifespan(app: FastAPI):

    # Test database connection
    await database.command("ping")

    print("MongoDB connected successfully")

    yield

    # Close database connection
    await client.close()


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {
        "message": "FastAPI is running"
    }


@app.get("/db-test")
async def db_test():

    result = await database.command("ping")

    return {
        "database": "connected",
        "result": result,
    }