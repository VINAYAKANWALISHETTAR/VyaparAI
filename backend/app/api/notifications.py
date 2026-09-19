from fastapi import APIRouter, Depends, HTTPException, Query

from app.core.security import get_current_user
from app.database.mongodb import db
from app.schemas.reminder import NotificationResponse
from app.services.notification_service import notification_service

router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
)


def validate_object_id(value: str, field_name: str):
    from bson import ObjectId
    try:
        return ObjectId(value)
    except Exception:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid {field_name}",
        )


def verify_business_ownership(business_id: str, current_user):
    from bson import ObjectId
    business_object_id = validate_object_id(business_id, "business_id")
    business = db.businesses.find_one({
        "_id": business_object_id,
        "owner_id": str(current_user["_id"]),
    })
    if not business:
        raise HTTPException(
            status_code=404,
            detail="Business not found or access denied",
        )
    return business


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

    verify_business_ownership(business_id, current_user)
    return notification_service.get_notifications(user_id, business_id, unread_only=unread_only)


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_read(
    notification_id: str,
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

    verify_business_ownership(business_id, current_user)
    notification = notification_service.mark_as_read(user_id, notification_id)
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    return notification
