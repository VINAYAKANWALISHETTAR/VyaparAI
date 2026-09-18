from datetime import datetime, timezone


def user_document(name: str, email: str, password_hash: str):
    return {
        "name": name,
        "email": email,
        "password_hash": password_hash,
        "created_at": datetime.now(timezone.utc),
    }