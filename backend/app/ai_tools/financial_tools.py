from app.services.financial_service import FinancialService

financial_service = FinancialService()


def get_today_income(business_id: str, user_id: str) -> dict:
    return financial_service.get_income(business_id, "today", user_id)


def get_today_expenses(business_id: str, user_id: str) -> dict:
    return financial_service.get_expenses(business_id, "today", user_id)


def get_today_profit(business_id: str, user_id: str) -> dict:
    return financial_service.get_profit(business_id, "today", user_id)


def get_cash_position(user_id: str) -> dict:
    return financial_service.get_cash_position(user_id)


def get_receivables(business_id: str | None, user_id: str, overdue_only: bool = False, customer_id: str | None = None) -> dict:
    return financial_service.get_receivables(business_id, user_id, overdue_only=overdue_only, customer_id=customer_id)


def get_overdue_receivables(business_id: str | None, user_id: str) -> dict:
    return financial_service.get_receivables(business_id, user_id, overdue_only=True)


def get_liabilities(user_id: str, upcoming_only: bool = False, overdue_only: bool = False) -> dict:
    return financial_service.get_liabilities(user_id, upcoming_only=upcoming_only, overdue_only=overdue_only)


def get_upcoming_liabilities(user_id: str) -> dict:
    return financial_service.get_liabilities(user_id, upcoming_only=True)


def get_cash_flow_forecast(user_id: str, days: int = 7) -> dict:
    return financial_service.get_cash_flow(user_id, days=days)
