from datetime import datetime, timezone, timedelta
from typing import Optional

from bson import ObjectId
from app.database.mongodb import db


class NotificationService:
    def create_notification(
        self,
        user_id: str,
        business_id: str,
        notification_type: str,
        title: str,
        message: str,
        data: Optional[dict] = None,
    ) -> dict:
        now = datetime.now(timezone.utc)

        # Duplicate check: don't create identical notification within 60s
        one_min_ago = now - timedelta(seconds=60)
        existing = db.notifications.find_one({
            "user_id": user_id,
            "type": notification_type,
            "title": title.strip(),
            "created_at": {"$gte": one_min_ago},
        })
        if existing:
            return self._serialize_notification(existing)

        notification = {
            "user_id": user_id,
            "business_id": business_id,
            "type": notification_type,
            "title": title.strip(),
            "message": message.strip(),
            "data": data or {},
            "read": False,
            "created_at": now,
        }

        result = db.notifications.insert_one(notification)
        created = db.notifications.find_one({"_id": result.inserted_id})
        return self._serialize_notification(created)

    def get_notifications(self, user_id: str, business_id: str | None = None, unread_only: bool = False) -> list[dict]:
        query: dict = {
            "$or": [
                {"user_id": user_id},
            ]
        }
        if business_id:
            query["$or"].append({"business_id": business_id})

        if unread_only:
            query["read"] = False

        notifications = []
        for notification in db.notifications.find(query).sort("created_at", -1).limit(100):
            notifications.append(self._serialize_notification(notification))

        return notifications

    def mark_as_read(self, user_id: str, notification_id: str) -> dict | None:
        try:
            oid = ObjectId(notification_id)
        except Exception:
            return None

        notification = db.notifications.find_one({"_id": oid, "user_id": user_id})
        if not notification:
            return None

        db.notifications.update_one({"_id": oid}, {"$set": {"read": True}})
        updated = db.notifications.find_one({"_id": oid})
        return self._serialize_notification(updated) if updated else None

    def mark_all_as_read(self, user_id: str, business_id: str | None = None) -> int:
        query: dict = {"user_id": user_id, "read": False}
        if business_id:
            query = {
                "$or": [{"user_id": user_id}, {"business_id": business_id}],
                "read": False,
            }
        res = db.notifications.update_many(query, {"$set": {"read": True}})
        return res.modified_count

    def delete_notification(self, user_id: str, notification_id: str) -> bool:
        try:
            oid = ObjectId(notification_id)
        except Exception:
            return False

        res = db.notifications.delete_one({"_id": oid, "user_id": user_id})
        return res.deleted_count > 0

    def _serialize_notification(self, notification: dict) -> dict:
        return {
            "id": str(notification["_id"]),
            "type": notification.get("type", "system"),
            "title": notification.get("title", ""),
            "message": notification.get("message", ""),
            "data": notification.get("data", {}),
            "read": bool(notification.get("read", False)),
            "created_at": notification["created_at"].isoformat() if notification.get("created_at") else None,
        }


notification_service = NotificationService()
