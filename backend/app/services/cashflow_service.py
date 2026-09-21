from datetime import datetime, timedelta, timezone
from app.services.financial_service import FinancialService

financial_service = FinancialService()


def get_cash_flow(user_id: str, days: int = 30):
    cash_position = financial_service.get_cash_position(user_id)
    receivables = financial_service.get_receivables(None, user_id)
    liabilities = financial_service.get_liabilities(user_id, upcoming_only=True)

    current_cash = cash_position["recorded_cash_position"]
    expected_receivables = receivables["total_receivables"]
    upcoming_liabilities = liabilities["upcoming_amount"]

    projected_balance = current_cash + expected_receivables - upcoming_liabilities

    if current_cash > 0:
        growth_rate = round(((projected_balance - current_cash) / current_cash) * 100.0, 1)
    else:
        growth_rate = 0.0

    if upcoming_liabilities == 0:
        risk_indicator = "low"
    elif projected_balance >= 0:
        risk_indicator = "medium"
    else:
        risk_indicator = "high"

    timeline = []
    now = datetime.now(timezone.utc)
    if current_cash > 0 or expected_receivables > 0 or upcoming_liabilities > 0:
        steps = 4
        step_days = max(1, days // steps)
        start_balance = current_cash
        projected_balance = current_cash + expected_receivables - upcoming_liabilities
        delta_step = (projected_balance - start_balance) / steps if steps else 0.0

        months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        for i in range(steps + 1):
            pt_date = now + timedelta(days=i * step_days)
            bal = round(start_balance + (delta_step * i), 2)
            timeline.append({
                "date": pt_date.strftime("%Y-%m-%d"),
                "label": f"{pt_date.day} {months[pt_date.month]}",
                "full_date": pt_date.strftime("%d %b %Y"),
                "balance": max(0.0, bal),
            })

    return {
        "days": days,
        "current_cash": current_cash,
        "expected_receivables": expected_receivables,
        "upcoming_liabilities": upcoming_liabilities,
        "projected_balance": projected_balance,
        "risk_indicator": risk_indicator,
        "growth_rate": growth_rate,
        "timeline": timeline,
    }
