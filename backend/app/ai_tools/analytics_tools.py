from app.services.financial_service import FinancialService

financial_service = FinancialService()


def get_anomalies(user_id: str) -> dict:
    return financial_service.get_anomalies(user_id)


def get_insights(user_id: str) -> dict:
    return financial_service.get_insights(user_id)


def get_business_summary(user_id: str, business_id: str | None = None) -> dict:
    income = financial_service.get_income(business_id, "today", user_id)
    expenses = financial_service.get_expenses(business_id, "today", user_id)
    profit = financial_service.get_profit(business_id, "today", user_id)
    cash_position = financial_service.get_cash_position(user_id)
    receivables = financial_service.get_receivables(business_id, user_id)
    liabilities = financial_service.get_liabilities(user_id, upcoming_only=True)
    cash_flow = financial_service.get_cash_flow(user_id)

    return {
        "today_income": income["total_income"],
        "today_expenses": expenses["total_expenses"],
        "today_profit": profit["profit"],
        "cash_position": cash_position,
        "receivables": {
            "total": receivables["total_receivables"],
            "overdue": receivables["overdue_amount"],
        },
        "liabilities": {
            "upcoming": liabilities["upcoming_amount"],
            "overdue": liabilities["overdue_amount"],
        },
        "cash_flow_forecast": cash_flow,
    }
