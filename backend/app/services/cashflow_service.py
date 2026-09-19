from app.services.financial_service import FinancialService

financial_service = FinancialService()


def get_cash_flow(user_id: str, days: int = 7):
    cash_position = financial_service.get_cash_position(user_id)
    receivables = financial_service.get_receivables(None, user_id)
    liabilities = financial_service.get_liabilities(user_id, upcoming_only=True)

    current_cash = cash_position["recorded_cash_position"]
    expected_receivables = receivables["total_receivables"]
    upcoming_liabilities = liabilities["upcoming_amount"]

    projected_balance = current_cash + expected_receivables - upcoming_liabilities

    if upcoming_liabilities == 0:
        risk_indicator = "low"
    elif projected_balance >= 0:
        risk_indicator = "medium"
    else:
        risk_indicator = "high"

    return {
        "days": days,
        "current_cash": current_cash,
        "expected_receivables": expected_receivables,
        "upcoming_liabilities": upcoming_liabilities,
        "projected_balance": projected_balance,
        "risk_indicator": risk_indicator,
    }
