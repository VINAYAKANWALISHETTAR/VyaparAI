from fastapi import APIRouter, Depends, HTTPException, Query

from app.core.security import get_current_user
from app.schemas.reminder import MorningBriefingResponse, ReminderCreate, ReminderResponse, ReminderUpdate
from app.services.reminder_service import reminder_service

router = APIRouter(
    prefix="/reminders",
    tags=["Reminders"],
)


@router.get("/morning-briefing", response_model=MorningBriefingResponse)
def get_morning_briefing(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if not business_id:
        from app.services.financial_service import FinancialService
        financial_service = FinancialService()
        business_ids = financial_service._get_user_business_ids(user_id)
        if not business_ids:
            raise HTTPException(status_code=400, detail="No business found for user")
        business_id = business_ids[0]

    return reminder_service.get_morning_briefing(user_id, business_id)


@router.post("/", response_model=ReminderResponse)
def create_reminder(
    reminder: ReminderCreate,
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if not business_id:
        from app.services.financial_service import FinancialService
        financial_service = FinancialService()
        business_ids = financial_service._get_user_business_ids(user_id)
        if not business_ids:
            raise HTTPException(status_code=400, detail="No business found for user")
        business_id = business_ids[0]

    return reminder_service.create_reminder(
        user_id=user_id,
        business_id=business_id,
        title=reminder.title,
        description=reminder.description,
        due_at=reminder.due_at,
        amount=reminder.amount,
        party_name=reminder.party_name,
        reminder_type=reminder.reminder_type,
    )


@router.get("/", response_model=list[ReminderResponse])
def get_reminders(
    current_user=Depends(get_current_user),
    status: str | None = None,
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if not business_id:
        from app.services.financial_service import FinancialService
        financial_service = FinancialService()
        business_ids = financial_service._get_user_business_ids(user_id)
        if not business_ids:
            return []
        business_id = business_ids[0]

    return reminder_service.get_reminders(user_id, business_id, status=status)


@router.get("/{reminder_id}", response_model=ReminderResponse)
def get_reminder(
    reminder_id: str,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    reminder = reminder_service.get_reminder(user_id, reminder_id)
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")
    return reminder


@router.patch("/{reminder_id}", response_model=ReminderResponse)
def update_reminder(
    reminder_id: str,
    update_data: ReminderUpdate,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    reminder = reminder_service.update_reminder(user_id, reminder_id, update_data.model_dump(exclude_none=True))
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")
    return reminder


@router.delete("/{reminder_id}")
def delete_reminder(
    reminder_id: str,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    success = reminder_service.delete_reminder(user_id, reminder_id)
    if not success:
        raise HTTPException(status_code=404, detail="Reminder not found")
    return {"message": "Reminder deleted"}
