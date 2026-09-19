from fastapi import APIRouter, Depends, HTTPException, Query

from app.core.security import get_current_user
from app.schemas.reminder import NotificationResponse
from app.services.notification_service import notification_service

router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
)


@router.get("/", response_model=list[NotificationResponse])
def get_notifications(
    current_user=Depends(get_current_user),
    unread_only: bool = False,
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

    return notification_service.get_notifications(user_id, business_id, unread_only=unread_only)


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_read(
    notification_id: str,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    notification = notification_service.mark_as_read(user_id, notification_id)
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    return notification
