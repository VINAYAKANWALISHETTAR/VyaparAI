import os
from pathlib import Path

from dotenv import load_dotenv
from pymongo import AsyncMongoClient
from pymongo.server_api import ServerApi


# Always load the .env belonging to this application
env_path = Path(__file__).resolve().parent / ".env"

# IMPORTANT: override any old Windows environment variable
load_dotenv(env_path, override=True)

MONGODB_URL = os.getenv("MONGODB_URL")

if not MONGODB_URL:
    raise RuntimeError(f"MONGODB_URL not found in {env_path}")


# Safe diagnostic information - NEVER print the password
from urllib.parse import urlparse

parsed = urlparse(MONGODB_URL)

print("MongoDB configuration:")
print("  Username:", parsed.username)
print("  Host:", parsed.hostname)
print("  Password present:", bool(parsed.password))
print("  Password length:", len(parsed.password or ""))


client = AsyncMongoClient(
    MONGODB_URL,
    server_api=ServerApi(
        version="1",
        strict=True,
        deprecation_errors=True,
    ),
)

database = client["myapp"]

users_collection = database["users"]