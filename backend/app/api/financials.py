from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.security import get_current_user
from app.database.mongodb import db
from app.schemas.financial import (
    AnomaliesListResponse,
    AnomalyResponse,
    CashFlowResponse,
    CashPositionResponse,
    CustomerSummaryResponse,
    ExpenseResponse,
    IncomeResponse,
    LiabilityResponse,
    ProfitResponse,
    ReceivableAgingResponse,
    ReceivableResponse,
    SupplierSummaryResponse,
)
from app.services.financial_service import FinancialService
from bson import ObjectId

router = APIRouter(
    prefix="/financials",
    tags=["Financials"],
)

financial_service = FinancialService()


def validate_object_id(value: str, field_name: str):
    try:
        return ObjectId(value)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid {field_name}",
        )


def verify_business_ownership(business_id: str, current_user):
    business_object_id = validate_object_id(business_id, "business_id")
    business = db.businesses.find_one({
        "_id": business_object_id,
        "owner_id": str(current_user["_id"]),
    })
    if not business:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Business not found or access denied",
        )
    return business


@router.get("/income/today", response_model=IncomeResponse)
def get_income_today(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_income(business_id, "today", user_id)


@router.get("/income/week", response_model=IncomeResponse)
def get_income_week(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_income(business_id, "week", user_id)


@router.get("/income/month", response_model=IncomeResponse)
def get_income_month(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_income(business_id, "month", user_id)


@router.get("/expenses/today", response_model=ExpenseResponse)
def get_expenses_today(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_expenses(business_id, "today", user_id)


@router.get("/expenses/week", response_model=ExpenseResponse)
def get_expenses_week(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_expenses(business_id, "week", user_id)


@router.get("/expenses/month", response_model=ExpenseResponse)
def get_expenses_month(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_expenses(business_id, "month", user_id)


@router.get("/profit/today", response_model=ProfitResponse)
def get_profit_today(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_profit(business_id, "today", user_id)


@router.get("/profit/week", response_model=ProfitResponse)
def get_profit_week(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_profit(business_id, "week", user_id)


@router.get("/profit/month", response_model=ProfitResponse)
def get_profit_month(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_profit(business_id, "month", user_id)


@router.get("/receivables", response_model=ReceivableResponse)
def get_receivables(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_receivables(business_id, user_id)


@router.get("/receivables/overdue", response_model=ReceivableResponse)
def get_receivables_overdue(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_receivables(business_id, user_id, overdue_only=True)


@router.get("/receivables/customer/{customer_id}", response_model=ReceivableResponse)
def get_receivables_by_customer(
    customer_id: str,
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_receivables(business_id, user_id, customer_id=customer_id)


@router.get("/liabilities", response_model=LiabilityResponse)
def get_liabilities(
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    return financial_service.get_liabilities(user_id)


@router.get("/liabilities/upcoming", response_model=LiabilityResponse)
def get_liabilities_upcoming(
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    return financial_service.get_liabilities(user_id, upcoming_only=True)


@router.get("/liabilities/overdue", response_model=LiabilityResponse)
def get_liabilities_overdue(
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    return financial_service.get_liabilities(user_id, overdue_only=True)


@router.get("/anomalies", response_model=AnomaliesListResponse)
def get_anomalies(
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    return financial_service.get_anomalies(user_id)


@router.get("/cash-flow", response_model=CashFlowResponse)
def get_cash_flow(
    current_user=Depends(get_current_user),
    days: int = Query(default=7, ge=1, le=365),
):
    user_id = str(current_user["_id"])
    return financial_service.get_cash_flow(user_id, days=days)


@router.get("/cash-position", response_model=CashPositionResponse)
def get_cash_position(
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    return financial_service.get_cash_position(user_id)


@router.get("/receivables/aging", response_model=ReceivableAgingResponse)
def get_receivable_aging(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_receivable_aging(business_id, user_id)


@router.get("/receivables/customer-summary", response_model=CustomerSummaryResponse)
def get_customer_summary(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_customer_summary(business_id, user_id)


@router.get("/liabilities/supplier-summary", response_model=SupplierSummaryResponse)
def get_supplier_summary(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_supplier_summary(business_id, user_id)
