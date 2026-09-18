import os

from dotenv import load_dotenv
from pymongo import MongoClient

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL")
DATABASE_NAME = os.getenv("DATABASE_NAME", "vyaparai")

if not MONGODB_URL:
    raise RuntimeError("MONGODB_URL is not configured")

client = MongoClient(MONGODB_URL)

db = client[DATABASE_NAME]


def get_database():
    return db