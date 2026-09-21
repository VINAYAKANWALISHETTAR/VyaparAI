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
        tlsAllowInvalidCertificates=True,
        serverSelectionTimeoutMS=5000,
        connectTimeoutMS=5000,
    )
    client.admin.command("ping")
    db = client[DATABASE_NAME]
    print(f"Successfully connected to MongoDB Atlas ({DATABASE_NAME})")
except Exception as e:
    print(f"Notice: MongoDB Atlas direct connection notice: {e}. Trying resilient local database.")
    try:
        client = MongoClient(
            MONGODB_URL,
            tls=True,
            tlsAllowInvalidCertificates=True,
            serverSelectionTimeoutMS=5000,
        )
        client.admin.command("ping")
        db = client[DATABASE_NAME]
        print(f"Successfully connected to MongoDB Atlas via TLS fallback ({DATABASE_NAME})")
    except Exception as e2:
        print(f"Notice: Falling back to local mongomock ({e2})")
        import mongomock
        client = mongomock.MongoClient()
        db = client[DATABASE_NAME]



def get_database():
    return db