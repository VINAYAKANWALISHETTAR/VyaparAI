from app.ai_tools.analytics_tools import get_business_summary
from app.ai_tools.customer_tools import get_customer_balance, get_payment_history
from app.ai_tools.financial_tools import (
    get_cash_flow_forecast,
    get_cash_position,
    get_liabilities,
    get_overdue_receivables,
    get_receivables,
    get_today_expenses,
    get_today_income,
    get_today_profit,
    get_upcoming_liabilities,
)
from app.ai_tools.invoice_tools import get_invoice
from app.services.financial_service import FinancialService

financial_service = FinancialService()


def classify_intent(message: str) -> tuple[str, dict | None]:
    text = message.strip().lower()

    if "profit" in text and "today" in text:
        return "get_today_profit", {}
    if "income" in text and "today" in text:
        return "get_today_income", {}
    if "expense" in text and "today" in text:
        return "get_today_expenses", {}
    if "cash position" in text or "current cash" in text:
        return "get_cash_position", {}
    if "cash flow" in text or "forecast" in text:
        return "get_cash_flow_forecast", {}
    if "receivable" in text and "overdue" in text:
        return "get_overdue_receivables", {}
    if "receivable" in text or "who owes" in text:
        return "get_receivables", {}
    if "liability" in text and "upcoming" in text:
        return "get_upcoming_liabilities", {}
    if "liability" in text or "what do i owe" in text:
        return "get_liabilities", {}
    if "invoice" in text:
        return "get_invoice", {}
    if "customer" in text and "balance" in text:
        return "get_customer_balance", {}
    if "payment history" in text or "received from" in text:
        return "get_payment_history", {}
    if "summary" in text or "overview" in text or "business" in text:
        return "get_business_summary", {}

    return "unknown", {}


def generate_answer(intent: str, data: dict, message: str) -> str:
    if intent == "get_today_profit":
        return f"Your recorded profit today is ₹{data['profit']:.2f}."
    if intent == "get_today_income":
        return f"Your income today is ₹{data['total_income']:.2f}."
    if intent == "get_today_expenses":
        return f"Your expenses today are ₹{data['total_expenses']:.2f}."
    if intent == "get_cash_position":
        return f"Your recorded cash position is ₹{data['recorded_cash_position']:.2f}."
    if intent == "get_cash_flow_forecast":
        return f"Your projected cash balance is ₹{data['projected_balance']:.2f} with risk indicator: {data['risk_indicator']}."
    if intent == "get_receivables":
        return f"You have ₹{data['total_receivables']:.2f} in outstanding receivables."
    if intent == "get_overdue_receivables":
        return f"You have ₹{data['overdue_amount']:.2f} in overdue receivables."
    if intent == "get_liabilities":
        return f"You have ₹{data['total_liabilities']:.2f} in liabilities. Upcoming: ₹{data['upcoming_amount']:.2f}, Overdue: ₹{data['overdue_amount']:.2f}."
    if intent == "get_upcoming_liabilities":
        return f"You have ₹{data['upcoming_amount']:.2f} in upcoming liabilities."
    if intent == "get_invoice":
        if data:
            return f"Invoice {data['invoice_number']} for {data['customer_name']} is ₹{data['amount']:.2f} with ₹{data['outstanding_amount']:.2f} outstanding."
        return "Invoice not found."
    if intent == "get_customer_balance":
        return f"{data['customer_name']} owes you ₹{data['total_receivables']:.2f}."
    if intent == "get_payment_history":
        return f"You received ₹{data['total_received']:.2f} from {data['customer_name']} across {data['payment_count']} payments."
    if intent == "get_business_summary":
        return f"Today: ₹{data['today_income']:.2f} income, ₹{data['today_expenses']:.2f} expenses, ₹{data['today_profit']:.2f} profit. Cash position: ₹{data['cash_position']['recorded_cash_position']:.2f}."
    return "I can help you with income, expenses, profit, cash position, receivables, liabilities, invoices, and business summaries. What would you like to know?"


class CopilotService:
    def __init__(self):
        self._intent_handlers = {
            "get_today_profit": self._handle_today_profit,
            "get_today_income": self._handle_today_income,
            "get_today_expenses": self._handle_today_expenses,
            "get_cash_position": self._handle_cash_position,
            "get_cash_flow_forecast": self._handle_cash_flow_forecast,
            "get_receivables": self._handle_receivables,
            "get_overdue_receivables": self._handle_overdue_receivables,
            "get_liabilities": self._handle_liabilities,
            "get_upcoming_liabilities": self._handle_upcoming_liabilities,
            "get_invoice": self._handle_invoice,
            "get_customer_balance": self._handle_customer_balance,
            "get_payment_history": self._handle_payment_history,
            "get_business_summary": self._handle_business_summary,
        }

    def chat(self, user_id: str, message: str, business_id: str | None = None) -> dict:
        intent, params = classify_intent(message)
        handler = self._intent_handlers.get(intent)

        if handler:
            try:
                data = handler(user_id, business_id, **params)
                answer = generate_answer(intent, data, message)
                return {"answer": answer, "intent": intent, "data": data}
            except Exception as exc:
                return {
                    "answer": f"I encountered an error while processing your request: {exc}",
                    "intent": intent,
                    "data": None,
                }

        return {
            "answer": "I'm not sure how to help with that yet. I can answer questions about today's income, expenses, profit, cash position, receivables, liabilities, invoices, and business summaries.",
            "intent": "unknown",
            "data": None,
        }

    def _handle_today_profit(self, user_id: str, business_id: str | None, **kwargs):
        return get_today_profit(business_id, user_id)

    def _handle_today_income(self, user_id: str, business_id: str | None, **kwargs):
        return get_today_income(business_id, user_id)

    def _handle_today_expenses(self, user_id: str, business_id: str | None, **kwargs):
        return get_today_expenses(business_id, user_id)

    def _handle_cash_position(self, user_id: str, business_id: str | None, **kwargs):
        return get_cash_position(user_id)

    def _handle_cash_flow_forecast(self, user_id: str, business_id: str | None, **kwargs):
        return get_cash_flow_forecast(user_id)

    def _handle_receivables(self, user_id: str, business_id: str | None, **kwargs):
        return get_receivables(business_id, user_id)

    def _handle_overdue_receivables(self, user_id: str, business_id: str | None, **kwargs):
        return get_overdue_receivables(business_id, user_id)

    def _handle_liabilities(self, user_id: str, business_id: str | None, **kwargs):
        return get_liabilities(user_id)

    def _handle_upcoming_liabilities(self, user_id: str, business_id: str | None, **kwargs):
        return get_upcoming_liabilities(user_id)

    def _handle_invoice(self, user_id: str, business_id: str | None, **kwargs):
        return {}

    def _handle_customer_balance(self, user_id: str, business_id: str | None, customer_name: str = "", **kwargs):
        if not customer_name:
            return {"customer_name": customer_name, "total_receivables": 0, "overdue_amount": 0, "invoices": []}
        return get_customer_balance(customer_name, business_id or "", user_id)

    def _handle_payment_history(self, user_id: str, business_id: str | None, customer_name: str = "", **kwargs):
        if not customer_name:
            return {"customer_name": customer_name, "total_received": 0, "payment_count": 0, "payments": []}
        return get_payment_history(customer_name, business_id or "", user_id)

    def _handle_business_summary(self, user_id: str, business_id: str | None, **kwargs):
        return get_business_summary(user_id, business_id)


copilot_service = CopilotService()
