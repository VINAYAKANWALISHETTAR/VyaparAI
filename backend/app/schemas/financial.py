from pydantic import BaseModel


class IncomeResponse(BaseModel):
    period: str
    total_income: float
    transaction_count: int
    breakdown: list[dict]


class ExpenseResponse(BaseModel):
    period: str
    total_expenses: float
    transaction_count: int
    breakdown: list[dict]


class ProfitResponse(BaseModel):
    period: str
    total_income: float
    total_expenses: float
    profit: float
    transaction_count: int


class ReceivableResponse(BaseModel):
    total_receivables: float
    overdue_amount: float
    invoices: list[dict]


class LiabilityResponse(BaseModel):
    total_liabilities: float
    upcoming_amount: float
    overdue_amount: float
    obligations: list[dict]


class CashPositionResponse(BaseModel):
    recorded_cash_position: float
    total_income: float
    total_expenses: float
    net_cash_flow: float
    pending_receivables: float
    pending_liabilities: float
    available_cash: float


class CashFlowResponse(BaseModel):
    days: int
    current_cash: float
    expected_receivables: float
    upcoming_liabilities: float
    projected_balance: float
    risk_indicator: str
