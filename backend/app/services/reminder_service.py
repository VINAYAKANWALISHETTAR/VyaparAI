from datetime import datetime, timezone, timedelta
from typing import Optional

from app.database.mongodb import db
from app.services.notification_service import notification_service


class ReminderService:
    def create_reminder(
        self,
        user_id: str,
        business_id: str,
        title: str,
        description: str,
        due_at: Optional[str] = None,
        amount: Optional[float] = None,
        party_name: Optional[str] = None,
        reminder_type: Optional[str] = None,
        recurrence: Optional[str] = None,
    ) -> dict:
        due_datetime = None
        if due_at:
            try:
                due_datetime = datetime.fromisoformat(due_at)
                if due_datetime.tzinfo is None:
                    due_datetime = due_datetime.replace(tzinfo=timezone.utc)
            except Exception:
                due_datetime = None

        now = datetime.now(timezone.utc)
        reminder = {
            "user_id": user_id,
            "business_id": business_id,
            "title": title.strip(),
            "description": description.strip() if description else "",
            "due_at": due_datetime,
            "amount": round(float(amount), 2) if amount is not None else None,
            "party_name": party_name.strip() if party_name else None,
            "reminder_type": reminder_type or "general",
            "recurrence": recurrence.strip().lower() if recurrence else None,
            "status": "pending",
            "created_at": now,
            "updated_at": now,
        }

        result = db.reminders.insert_one(reminder)
        created_id = str(result.inserted_id)

        # Trigger notification for reminder creation
        try:
            notification_service.create_notification(
                user_id=user_id,
                business_id=business_id,
                notification_type="reminder_created",
                title=f"Reminder: {title}",
                message=description or f"Due on {due_datetime.strftime('%b %d, %Y') if due_datetime else 'soon'}",
                data={"reminder_id": created_id, "amount": reminder["amount"]},
            )
        except Exception:
            pass

        return {
            "id": created_id,
            "title": reminder["title"],
            "description": reminder["description"],
            "due_at": reminder["due_at"].isoformat() if reminder["due_at"] else None,
            "status": "pending",
            "amount": reminder["amount"],
            "party_name": reminder["party_name"],
            "reminder_type": reminder["reminder_type"],
            "recurrence": reminder["recurrence"],
            "created_at": reminder["created_at"].isoformat(),
        }

    def get_reminders(self, user_id: str, business_id: str, status: Optional[str] = None) -> list[dict]:
        query: dict = {
            "$or": [
                {"business_id": business_id},
                {"user_id": user_id},
            ]
        }
        if status:
            query["status"] = status.strip().lower()

        reminders = []
        for reminder in db.reminders.find(query).sort("due_at", 1):
            reminders.append(self._serialize_reminder(reminder))

        return reminders

    def get_reminder(self, user_id: str, reminder_id: str) -> dict | None:
        try:
            from bson import ObjectId
            reminder = db.reminders.find_one({
                "_id": ObjectId(reminder_id),
                "user_id": user_id,
            })
            return self._serialize_reminder(reminder) if reminder else None
        except Exception:
            return None

    def update_reminder(self, user_id: str, reminder_id: str, update_data: dict) -> dict | None:
        try:
            from bson import ObjectId
            oid = ObjectId(reminder_id)
        except Exception:
            return None

        reminder = db.reminders.find_one({"_id": oid, "user_id": user_id})
        if not reminder:
            reminder = db.reminders.find_one({"_id": oid})
            if not reminder:
                return None

        allowed_fields = {"title", "description", "due_at", "status", "amount", "party_name", "reminder_type", "recurrence"}
        update_fields = {}

        for field, value in update_data.items():
            if field in allowed_fields and value is not None:
                if field == "due_at" and isinstance(value, str):
                    try:
                        value = datetime.fromisoformat(value)
                        if value.tzinfo is None:
                            value = value.replace(tzinfo=timezone.utc)
                    except Exception:
                        pass
                if field == "amount" and value is not None:
                    value = round(float(value), 2)
                update_fields[field] = value

        if not update_fields:
            return self._serialize_reminder(reminder)

        now = datetime.now(timezone.utc)
        update_fields["updated_at"] = now

        db.reminders.update_one({"_id": oid}, {"$set": update_fields})

        # Recurrence handling: when a recurring reminder is marked completed, generate the next occurrence
        if update_fields.get("status") == "completed":
            rec = update_fields.get("recurrence") or reminder.get("recurrence")
            base_due = reminder.get("due_at")
            if base_due and isinstance(base_due, datetime) and base_due.tzinfo is None:
                base_due = base_due.replace(tzinfo=timezone.utc)
            if rec and base_due:
                next_due = None
                if rec == "daily":
                    next_due = base_due + timedelta(days=1)
                elif rec == "weekly":
                    next_due = base_due + timedelta(weeks=1)
                elif rec == "monthly":
                    next_due = base_due + timedelta(days=30)

                if next_due and next_due.tzinfo is None:
                    next_due = next_due.replace(tzinfo=timezone.utc)

                if next_due and next_due > now:
                    next_reminder = {
                        "user_id": user_id,
                        "business_id": reminder.get("business_id"),
                        "title": reminder.get("title", ""),
                        "description": reminder.get("description", ""),
                        "due_at": next_due,
                        "amount": reminder.get("amount"),
                        "party_name": reminder.get("party_name"),
                        "reminder_type": reminder.get("reminder_type", "general"),
                        "recurrence": rec,
                        "status": "pending",
                        "created_at": now,
                        "updated_at": now,
                    }
                    db.reminders.insert_one(next_reminder)

        updated = db.reminders.find_one({"_id": oid})
        return self._serialize_reminder(updated) if updated else None

    def delete_reminder(self, user_id: str, reminder_id: str) -> bool:
        try:
            from bson import ObjectId
            oid = ObjectId(reminder_id)
        except Exception:
            return False

        result = db.reminders.delete_one({"_id": oid, "user_id": user_id})
        if result.deleted_count == 0:
            result = db.reminders.delete_one({"_id": oid})
        return result.deleted_count > 0

    def get_morning_briefing(self, user_id: str, business_id: str) -> dict:
        reminders = self.get_reminders(user_id, business_id, status="pending")

        from app.services.financial_service import FinancialService
        financial_service = FinancialService()

        today_income = financial_service.get_income(business_id, "today", user_id)
        today_expenses = financial_service.get_expenses(business_id, "today", user_id)
        receivables = financial_service.get_receivables(business_id, user_id)
        liabilities = financial_service.get_liabilities(user_id, business_id=business_id, upcoming_only=True)

        pending_reminders = []
        now_date = datetime.now(timezone.utc).date()
        for reminder in reminders:
            due_at = reminder.get("due_at")
            if due_at:
                due_at_dt = datetime.fromisoformat(due_at) if isinstance(due_at, str) else due_at
                if due_at_dt.date() == now_date:
                    pending_reminders.append(reminder)

        notifications = []

        if receivables["overdue_amount"] > 0:
            notifications.append({
                "type": "payment_overdue",
                "title": "Overdue Payments",
                "message": f"You have ₹{receivables['overdue_amount']:.2f} in overdue receivables.",
                "data": {"overdue_amount": receivables["overdue_amount"]},
            })

        if liabilities["upcoming_amount"] > 0:
            notifications.append({
                "type": "payment_due",
                "title": "Upcoming Payments",
                "message": f"You have ₹{liabilities['upcoming_amount']:.2f} in upcoming liabilities.",
                "data": {"upcoming_amount": liabilities["upcoming_amount"]},
            })

        for reminder in pending_reminders:
            notifications.append({
                "type": "reminder",
                "title": reminder["title"],
                "message": reminder["description"],
                "data": {"reminder_id": reminder["id"]},
            })

        return {
            "date": now_date.isoformat(),
            "today_income": today_income["total_income"],
            "today_expenses": today_expenses["total_expenses"],
            "notifications": notifications,
        }

    def _serialize_reminder(self, reminder: dict) -> dict:
        return {
            "id": str(reminder["_id"]),
            "title": reminder.get("title", ""),
            "description": reminder.get("description", ""),
            "due_at": reminder["due_at"].isoformat() if reminder.get("due_at") else None,
            "status": reminder.get("status", "pending"),
            "amount": reminder.get("amount"),
            "party_name": reminder.get("party_name"),
            "reminder_type": reminder.get("reminder_type", "general"),
            "recurrence": reminder.get("recurrence"),
            "created_at": reminder["created_at"].isoformat() if reminder.get("created_at") else None,
        }


reminder_service = ReminderService()
