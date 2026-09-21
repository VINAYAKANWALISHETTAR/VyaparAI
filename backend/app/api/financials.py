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
    InsightResponse,
    InsightsListResponse,
    LiabilityResponse,
    ProfitResponse,
    ReceivableAgingResponse,
    ReceivableResponse,
    SupplierSummaryResponse,
)
from app.services.financial_service import FinancialService
from app.services import (
    anomaly_service,
    insight_service,
    cashflow_service,
    reconciliation_service,
)
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


@router.get("/income/{period}", response_model=IncomeResponse)
def get_income_period(
    period: str,
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_income(business_id, period, user_id, start_date=start_date, end_date=end_date)


@router.get("/expenses/{period}", response_model=ExpenseResponse)
def get_expenses_period(
    period: str,
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_expenses(business_id, period, user_id, start_date=start_date, end_date=end_date)


@router.get("/profit/{period}", response_model=ProfitResponse)
def get_profit_period(
    period: str,
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return financial_service.get_profit(business_id, period, user_id, start_date=start_date, end_date=end_date)



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
    return anomaly_service.get_anomalies(user_id)


@router.get("/insights", response_model=InsightsListResponse)
def get_insights(
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    return insight_service.get_insights(user_id)


@router.get("/cash-flow", response_model=CashFlowResponse)
def get_cash_flow(
    current_user=Depends(get_current_user),
    days: int = Query(default=7, ge=1, le=365),
):
    user_id = str(current_user["_id"])
    return cashflow_service.get_cash_flow(user_id, days=days)


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
    return reconciliation_service.get_receivable_aging(business_id, user_id)


@router.get("/receivables/customer-summary", response_model=CustomerSummaryResponse)
def get_customer_summary(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return reconciliation_service.get_customer_summary(business_id, user_id)


@router.get("/liabilities/supplier-summary", response_model=SupplierSummaryResponse)
def get_supplier_summary(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    if business_id:
        verify_business_ownership(business_id, current_user)
    return reconciliation_service.get_supplier_summary(business_id, user_id)


@router.get("/export/csv")
def export_financial_report_csv(
    current_user=Depends(get_current_user),
    period: str = Query(default="month"),
    business_id: str | None = Query(default=None),
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
):
    import csv
    import io
    from datetime import datetime, timezone
    from fastapi.responses import Response

    user_id = str(current_user["_id"])
    business_ids = financial_service._get_user_business_ids(user_id)
    if business_id:
        verify_business_ownership(business_id, current_user)
    else:
        business_id = business_ids[0] if business_ids else None

    business_name = "My Business"
    if business_id:
        biz = db.businesses.find_one({"_id": ObjectId(business_id)})
        if biz:
            business_name = biz.get("name", "My Business")

    start, end = financial_service._get_date_range(period, start_date=start_date, end_date=end_date)
    inc_data = financial_service.get_income(business_id, period, user_id, start_date=start_date, end_date=end_date)
    exp_data = financial_service.get_expenses(business_id, period, user_id, start_date=start_date, end_date=end_date)
    prof_data = financial_service.get_profit(business_id, period, user_id, start_date=start_date, end_date=end_date)

    total_inc = inc_data.get("total_income", 0.0)
    total_exp = exp_data.get("total_expenses", 0.0)
    net_profit = prof_data.get("profit", total_inc - total_exp)

    query = {
        "$or": [
            {"business_id": {"$in": business_ids}},
            {"user_id": user_id},
        ]
    }
    if start and end:
        query["date"] = {"$gte": start, "$lte": end}
    elif start:
        query["date"] = {"$gte": start}
    elif end:
        query["date"] = {"$lte": end}

    txns = list(db.transactions.find(query).sort("date", -1))

    output = io.StringIO()
    writer = csv.writer(output)

    # Header section
    writer.writerow(["VYAPARAI FINANCIAL STATEMENT & REPORT"])
    writer.writerow(["Business Name", business_name])
    writer.writerow(["Period", period.capitalize()])
    writer.writerow(["Generated Date", datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")])
    writer.writerow([])

    # Financial Summary
    writer.writerow(["FINANCIAL SUMMARY"])
    writer.writerow(["Total Income (₹)", f"{total_inc:,.2f}"])
    writer.writerow(["Total Expenses (₹)", f"{total_exp:,.2f}"])
    writer.writerow(["Net Profit / Loss (₹)", f"{net_profit:,.2f}"])
    writer.writerow(["Total Transactions", len(txns)])
    writer.writerow([])

    # Transactions Ledger
    writer.writerow(["TRANSACTION LEDGER"])
    writer.writerow(["Transaction ID", "Date", "Type", "Category", "Amount", "Description", "Reference ID", "Source"])

    for tx in txns:
        date_str = ""
        raw_date = tx.get("date") or tx.get("created_at")
        if isinstance(raw_date, datetime):
            date_str = raw_date.strftime("%Y-%m-%d %H:%M")
        elif raw_date:
            date_str = str(raw_date)

        writer.writerow([
            str(tx.get("_id", "")),
            date_str,
            tx.get("type", "").upper(),
            tx.get("category", ""),
            f"{float(tx.get('amount', 0.0)):,.2f}",
            tx.get("description", ""),
            tx.get("reference_id", ""),
            tx.get("source", "manual"),
        ])

    csv_content = output.getvalue()
    filename = f"vyapar_financial_report_{period}_{datetime.now().strftime('%Y%m%d')}.csv"

    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Access-Control-Expose-Headers": "Content-Disposition",
        },
    )

