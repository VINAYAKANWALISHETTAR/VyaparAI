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

db_connection_status = "uninitialized"
db_connection_type = "mongodb"
db_connection_error = None

mongo_kwargs = {
    "serverSelectionTimeoutMS": 30000,
    "connectTimeoutMS": 30000,
    "tlsAllowInvalidCertificates": True,
}
if ca_file:
    mongo_kwargs["tlsCAFile"] = ca_file

try:
    client = MongoClient(MONGODB_URL, **mongo_kwargs)
    client.admin.command("ping")
    db = client[DATABASE_NAME]
    db_connection_status = "connected"
    db_connection_type = "mongodb_atlas"
    print(f"Successfully connected to MongoDB Atlas ({DATABASE_NAME})")
except Exception as e:
    db_connection_error = str(e)
    print(f"Notice: MongoDB Atlas direct connection notice: {e}. Trying resilient connection.")
    try:
        client = MongoClient(
            MONGODB_URL,
            tls=True,
            tlsAllowInvalidCertificates=True,
            serverSelectionTimeoutMS=30000,
            connectTimeoutMS=30000,
        )
        client.admin.command("ping")
        db = client[DATABASE_NAME]
        db_connection_status = "connected"
        db_connection_type = "mongodb_atlas_tls"
        db_connection_error = None
        print(f"Successfully connected to MongoDB Atlas via TLS fallback ({DATABASE_NAME})")
    except Exception as e2:
        db_connection_error = f"Atlas connection failed: {e2}"
        print(f"WARNING: Could not connect to MongoDB Atlas ({e2}). Checking mock DB fallback.")
        try:
            import mongomock
            client = mongomock.MongoClient()
            db = client[DATABASE_NAME]
            db_connection_status = "fallback_mock"
            db_connection_type = "mongomock"
            print("CRITICAL NOTICE: Running on in-memory mongomock. Data will NOT persist across restarts! Please verify MongoDB Atlas IP Access List.")
        except Exception as e3:
            db_connection_status = "failed"
            raise RuntimeError(f"Could not connect to MongoDB Atlas and mongomock is not available: {e2}, {e3}")


def init_db_indexes(database):
    try:
        # Transactions: critical for home dashboard, reports, voice queries
        database.transactions.create_index([("business_id", 1), ("date", -1)], background=True)
        database.transactions.create_index([("user_id", 1), ("date", -1)], background=True)
        database.transactions.create_index([("business_id", 1), ("type", 1), ("date", -1)], background=True)
        database.transactions.create_index([("date", -1)], background=True)
        
        # Businesses
        database.businesses.create_index([("owner_id", 1)], background=True)
        
        # Invoices & Receivables
        database.invoices.create_index([("business_id", 1), ("status", 1)], background=True)
        database.invoices.create_index([("user_id", 1)], background=True)
        database.invoices.create_index([("customer_name", 1)], background=True)
        
        # Reminders & Notifications
        database.reminders.create_index([("user_id", 1), ("due_date", 1)], background=True)
        database.notifications.create_index([("user_id", 1), ("created_at", -1)], background=True)
        
        # Users
        database.users.create_index([("email", 1)], unique=True, background=True)
    except Exception as e:
        print(f"Notice: Index setup handled: {e}")


# Initialize indexes on established database
init_db_indexes(db)


def get_database():
    return db


def get_db_diagnostics():
    is_mock = "mongomock" in db.client.__class__.__module__
    return {
        "database": db.name,
        "status": db_connection_status,
        "connection_type": db_connection_type,
        "is_mock": is_mock,
        "error": db_connection_error,
    }