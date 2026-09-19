from calendar import monthrange
from datetime import date, datetime, timezone

from app.database.mongodb import db
from app.services.financial_service import FinancialService
from app.services.anomaly_service import _check_duplicate_invoices, _check_overpayments, _check_unusual_expenses

financial_service = FinancialService()


def get_insights(user_id: str):
    business_ids = financial_service._get_user_business_ids(user_id)
    insights = []

    insights.extend(_check_revenue_trends(business_ids))
    insights.extend(_check_expense_trends(business_ids))
    insights.extend(_check_receivable_alerts(business_ids))
    insights.extend(_check_cash_flow_warnings(user_id))
    insights.extend(_check_anomaly_flags(business_ids))

    return {
        "insight_count": len(insights),
        "insights": insights,
    }


def _check_revenue_trends(business_ids: list[str]):
    insights = []
    today = date.today()
    start_of_month = today.replace(day=1)
    last_day = monthrange(today.year, today.month)[1]
    end_of_month = today.replace(day=last_day)

    pipeline = [
        {
            "$match": {
                "business_id": {"$in": business_ids},
                "type": "income",
                "date": {
                    "$gte": datetime.combine(start_of_month, datetime.min.time()).replace(tzinfo=timezone.utc),
                    "$lte": datetime.combine(end_of_month, datetime.max.time()).replace(tzinfo=timezone.utc),
                },
            }
        },
        {
            "$group": {
                "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$date"}},
                "daily_income": {"$sum": "$amount"},
            }
        },
        {"$sort": {"_id": 1}},
    ]

    results = list(db.transactions.aggregate(pipeline))
    if len(results) >= 2:
        first_day = results[0]["daily_income"]
        last_day = results[-1]["daily_income"]
        if first_day > 0 and last_day < first_day * 0.5:
            insights.append({
                "type": "revenue_trend",
                "title": "Revenue declining",
                "description": f"Daily income has decreased from {first_day:.2f} to {last_day:.2f} this month.",
                "severity": "medium",
                "related_entities": [],
            })

    return insights


def _check_expense_trends(business_ids: list[str]):
    insights = []
    today = date.today()
    start_of_month = today.replace(day=1)

    pipeline = [
        {
            "$match": {
                "business_id": {"$in": business_ids},
                "type": "expense",
                "date": {"$gte": datetime.combine(start_of_month, datetime.min.time()).replace(tzinfo=timezone.utc)},
            }
        },
        {
            "$group": {
                "_id": "$category",
                "total_expense": {"$sum": "$amount"},
            }
        },
    ]

    results = list(db.transactions.aggregate(pipeline))
    for result in results:
        if result["total_expense"] > 50000:
            insights.append({
                "type": "expense_trend",
                "title": f"High {result['_id']} expenses",
                "description": f"Total {result['_id']} expenses this month: {result['total_expense']:.2f}",
                "severity": "low",
                "related_entities": [{"category": result["_id"], "amount": result["total_expense"]}],
            })

    return insights


def _check_receivable_alerts(business_ids: list[str]):
    insights = []
    invoices = db.invoices.find({
        "business_id": {"$in": business_ids},
        "outstanding_amount": {"$gt": 0},
    })

    today = date.today()
    overdue_amount = 0.0
    overdue_count = 0

    for invoice in invoices:
        due_date = invoice.get("due_date")
        if hasattr(due_date, "date"):
            due_date = due_date.date()

        outstanding = float(invoice.get("outstanding_amount", 0))

        if due_date and due_date < today and outstanding > 0:
            overdue_amount += outstanding
            overdue_count += 1

    if overdue_amount > 0:
        insights.append({
            "type": "receivable_alert",
            "title": "Overdue receivables",
            "description": f"You have {overdue_amount:.2f} in overdue receivables.",
            "severity": "medium",
            "related_entities": [{"overdue_amount": overdue_amount, "count": overdue_count}],
        })
    return insights


def _check_cash_flow_warnings(user_id: str):
    insights = []
    from app.services.cashflow_service import get_cash_flow
    cash_flow = get_cash_flow(user_id)
    if cash_flow["projected_balance"] < 0:
        insights.append({
            "type": "cash_flow_warning",
            "title": "Potential cash shortfall",
            "description": f"Projected balance is {cash_flow['projected_balance']:.2f}. Consider collecting receivables or delaying payments.",
            "severity": "high",
            "related_entities": [{"projected_balance": cash_flow["projected_balance"]}],
        })
    return insights


def _check_anomaly_flags(business_ids: list[str]):
    insights = []
    anomalies = _check_duplicate_invoices(business_ids) + _check_overpayments(business_ids) + _check_unusual_expenses(business_ids)
    if anomalies:
        insights.append({
            "type": "anomaly_flag",
            "title": "Anomalies detected",
            "description": f"{len(anomalies)} anomalies require your attention.",
            "severity": "medium",
            "related_entities": [{"anomaly_count": len(anomalies)}],
        })
    return insights
