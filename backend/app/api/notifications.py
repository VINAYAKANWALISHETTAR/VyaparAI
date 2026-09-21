from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.security import get_current_user
from app.database.mongodb import db
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
    return notification_service.get_notifications(user_id, business_id, unread_only=unread_only)


@router.patch("/mark-all-read")
def mark_all_notifications_read(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    count = notification_service.mark_all_as_read(user_id, business_id)
    return {"message": "All notifications marked as read", "modified_count": count}


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


@router.delete("/{notification_id}")
def delete_notification(
    notification_id: str,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    deleted = notification_service.delete_notification(user_id, notification_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Notification not found")
    return {"message": "Notification deleted successfully", "id": notification_id}
