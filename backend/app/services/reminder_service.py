from datetime import datetime, timezone
from typing import Optional

from app.database.mongodb import db


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
    ) -> dict:
        due_datetime = None
        if due_at:
            try:
                due_datetime = datetime.fromisoformat(due_at)
            except Exception:
                due_datetime = None

        reminder = {
            "user_id": user_id,
            "business_id": business_id,
            "title": title,
            "description": description,
            "due_at": due_datetime,
            "amount": amount,
            "party_name": party_name,
            "reminder_type": reminder_type or "general",
            "status": "pending",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc),
        }

        result = db.reminders.insert_one(reminder)

        return {
            "id": str(result.inserted_id),
            "title": title,
            "description": description,
            "due_at": reminder["due_at"].isoformat() if reminder["due_at"] else None,
            "status": "pending",
            "amount": amount,
            "party_name": party_name,
            "reminder_type": reminder["reminder_type"],
            "created_at": reminder["created_at"].isoformat(),
        }

    def get_reminders(self, user_id: str, business_id: str, status: Optional[str] = None) -> list[dict]:
        query = {"business_id": business_id}
        if status:
            query["status"] = status

        total_count = db.reminders.count_documents({"business_id": business_id})
        if total_count == 0:
            # Seed intelligent business reminders
            from datetime import timedelta
            now = datetime.now(timezone.utc)
            initial_reminders = [
                {
                    "user_id": user_id,
                    "business_id": business_id,
                    "title": "Pay Supplier",
                    "description": "ABC Traders",
                    "due_at": now + timedelta(days=1),
                    "amount": 8000.0,
                    "party_name": "ABC Traders",
                    "reminder_type": "supplier",
                    "status": "pending",
                    "created_at": now,
                    "updated_at": now,
                },
                {
                    "user_id": user_id,
                    "business_id": business_id,
                    "title": "Follow up with Ramesh",
                    "description": "Payment due",
                    "due_at": now + timedelta(days=2),
                    "amount": 18000.0,
                    "party_name": "Ramesh Textiles",
                    "reminder_type": "customer",
                    "status": "pending",
                    "created_at": now,
                    "updated_at": now,
                },
                {
                    "user_id": user_id,
                    "business_id": business_id,
                    "title": "Rent Payment",
                    "description": "Office Rent",
                    "due_at": now + timedelta(days=5),
                    "amount": 12000.0,
                    "party_name": "Office Landlord",
                    "reminder_type": "rent",
                    "status": "pending",
                    "created_at": now,
                    "updated_at": now,
                },
                {
                    "user_id": user_id,
                    "business_id": business_id,
                    "title": "Electricity Bill",
                    "description": "BESCOM Utility Bill",
                    "due_at": now + timedelta(days=7),
                    "amount": 2500.0,
                    "party_name": "Electricity Board",
                    "reminder_type": "utility",
                    "status": "pending",
                    "created_at": now,
                    "updated_at": now,
                },
            ]
            db.reminders.insert_many(initial_reminders)

        reminders = []
        for reminder in db.reminders.find(query).sort("due_at", 1):
            reminders.append(self._serialize_reminder(reminder))

        return reminders

    def get_reminder(self, user_id: str, reminder_id: str) -> dict | None:
        try:
            from bson import ObjectId
            reminder = db.reminders.find_one({"_id": ObjectId(reminder_id), "user_id": user_id})
            return self._serialize_reminder(reminder) if reminder else None
        except Exception:
            return None

    def update_reminder(self, user_id: str, reminder_id: str, update_data: dict) -> dict | None:
        from bson import ObjectId

        reminder = db.reminders.find_one({"_id": ObjectId(reminder_id), "user_id": user_id})
        if not reminder:
            return None

        allowed_fields = {"title", "description", "due_at", "status", "amount", "party_name", "reminder_type"}
        update_fields = {}

        for field, value in update_data.items():
            if field in allowed_fields and value is not None:
                if field == "due_at" and isinstance(value, str):
                    value = datetime.fromisoformat(value)
                update_fields[field] = value

        if not update_fields:
            return self._serialize_reminder(reminder)

        update_fields["updated_at"] = datetime.now(timezone.utc)

        db.reminders.update_one({"_id": ObjectId(reminder_id)}, {"$set": update_fields})

        updated = db.reminders.find_one({"_id": ObjectId(reminder_id)})
        return self._serialize_reminder(updated) if updated else None

    def delete_reminder(self, user_id: str, reminder_id: str) -> bool:
        from bson import ObjectId

        result = db.reminders.delete_one({"_id": ObjectId(reminder_id), "user_id": user_id})
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
        for reminder in reminders:
            due_at = reminder.get("due_at")
            if due_at:
                due_at = datetime.fromisoformat(due_at) if isinstance(due_at, str) else due_at
                if due_at.date() == datetime.now(timezone.utc).date():
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
            "date": datetime.now(timezone.utc).date().isoformat(),
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
            "created_at": reminder["created_at"].isoformat() if reminder.get("created_at") else None,
        }


reminder_service = ReminderService()
