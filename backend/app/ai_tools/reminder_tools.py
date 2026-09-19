from datetime import datetime, timezone

from app.database.mongodb import db


def create_reminder(user_id: str, business_id: str, title: str, description: str, due_at: datetime | str) -> dict:
    if isinstance(due_at, str):
        try:
            due_at = datetime.fromisoformat(due_at)
        except ValueError:
            raise ValueError("Invalid due_at format. Use ISO format.")

    reminder = {
        "user_id": user_id,
        "business_id": business_id,
        "title": title,
        "description": description,
        "due_at": due_at,
        "status": "pending",
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }

    result = db.reminders.insert_one(reminder)

    return {
        "id": str(result.inserted_id),
        "title": title,
        "description": description,
        "due_at": due_at.isoformat(),
        "status": "pending",
    }
