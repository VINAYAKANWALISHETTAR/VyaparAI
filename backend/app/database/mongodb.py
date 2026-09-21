import os
from dotenv import load_dotenv
from pymongo import MongoClient

try:
    import certifi
    ca_file = certifi.where()
except Exception:
    ca_file = None

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL")
DATABASE_NAME = os.getenv("DATABASE_NAME", "vyaparai")

if not MONGODB_URL:
    raise RuntimeError("MONGODB_URL is not configured")

mongo_kwargs = {
    "serverSelectionTimeoutMS": 5000,
    "connectTimeoutMS": 5000,
    "tlsAllowInvalidCertificates": True,
}
if ca_file:
    mongo_kwargs["tlsCAFile"] = ca_file

try:
    client = MongoClient(MONGODB_URL, **mongo_kwargs)
    client.admin.command("ping")
    db = client[DATABASE_NAME]
    print(f"Successfully connected to MongoDB Atlas ({DATABASE_NAME})")
except Exception as e:
    print(f"Notice: MongoDB Atlas direct connection notice: {e}. Trying resilient connection.")
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
        try:
            import mongomock
            client = mongomock.MongoClient()
            db = client[DATABASE_NAME]
        except Exception as e3:
            raise RuntimeError(f"Could not connect to MongoDB Atlas and mongomock is not available: {e2}, {e3}")


def get_database():
    return db