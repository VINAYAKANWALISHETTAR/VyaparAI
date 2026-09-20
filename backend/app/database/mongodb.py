import os
import certifi
from dotenv import load_dotenv
from pymongo import MongoClient

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL")
DATABASE_NAME = os.getenv("DATABASE_NAME", "vyaparai")

if not MONGODB_URL:
    raise RuntimeError("MONGODB_URL is not configured")

try:
    client = MongoClient(
        MONGODB_URL,
        tlsCAFile=certifi.where(),
        serverSelectionTimeoutMS=3000,
        connectTimeoutMS=3000,
    )
    client.admin.command("ping")
    db = client[DATABASE_NAME]
    print(f"Successfully connected to MongoDB Atlas ({DATABASE_NAME})")
except Exception as e:
    print(f"Notice: MongoDB Atlas connection failed ({e}). Using in-memory fallback database for local development.")
    import mongomock
    client = mongomock.MongoClient()
    db = client[DATABASE_NAME]


def get_database():
    return db