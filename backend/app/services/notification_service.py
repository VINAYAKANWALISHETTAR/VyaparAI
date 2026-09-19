from datetime import datetime, timezone
from typing import Optional

from app.database.mongodb import db


class NotificationService:
    def create_notification(self, user_id: str, business_id: str, notification_type: str, title: str, message: str, data: Optional[dict] = None) -> dict:
        notification = {
            "user_id": user_id,
            "business_id": business_id,
            "type": notification_type,
            "title": title,
            "message": message,
            "data": data or {},
            "read": False,
            "created_at": datetime.now(timezone.utc),
        }

        result = db.notifications.insert_one(notification)

        return {
            "id": str(result.inserted_id),
            "type": notification_type,
            "title": title,
            "message": message,
            "data": data or {},
            "read": False,
            "created_at": notification["created_at"].isoformat(),
        }

    def get_notifications(self, user_id: str, business_id: str, unread_only: bool = False) -> list[dict]:
        query = {"user_id": user_id, "business_id": business_id}
        if unread_only:
            query["read"] = False

        notifications = []
        for notification in db.notifications.find(query).sort("created_at", -1):
            notifications.append(self._serialize_notification(notification))

        return notifications

    def mark_as_read(self, user_id: str, notification_id: str) -> dict | None:
        from bson import ObjectId

        notification = db.notifications.find_one({"_id": ObjectId(notification_id), "user_id": user_id})
        if not notification:
            return None

        db.notifications.update_one({"_id": ObjectId(notification_id)}, {"$set": {"read": True}})

        updated = db.notifications.find_one({"_id": ObjectId(notification_id)})
        return self._serialize_notification(updated) if updated else None

    def _serialize_notification(self, notification: dict) -> dict:
        return {
            "id": str(notification["_id"]),
            "type": notification["type"],
            "title": notification["title"],
            "message": notification["message"],
            "data": notification.get("data", {}),
            "read": notification.get("read", False),
            "created_at": notification["created_at"].isoformat() if notification.get("created_at") else None,
        }


notification_service = NotificationService()
