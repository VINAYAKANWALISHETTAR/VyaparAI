from pydantic import BaseModel


class ReminderCreate(BaseModel):
    title: str
    description: str
    due_at: str | None = None
    amount: float | None = None
    party_name: str | None = None
    reminder_type: str | None = None
    recurrence: str | None = None


class ReminderUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    due_at: str | None = None
    status: str | None = None
    amount: float | None = None
    party_name: str | None = None
    reminder_type: str | None = None
    recurrence: str | None = None


class ReminderResponse(BaseModel):
    id: str
    title: str
    description: str
    due_at: str | None = None
    status: str
    amount: float | None = None
    party_name: str | None = None
    reminder_type: str | None = None
    recurrence: str | None = None
    created_at: str | None = None


class NotificationResponse(BaseModel):
    id: str
    type: str
    title: str
    message: str
    data: dict | None = None
    read: bool = False
    created_at: str | None = None


class MorningBriefingResponse(BaseModel):
    date: str
    today_income: float
    today_expenses: float
    notifications: list[dict]
