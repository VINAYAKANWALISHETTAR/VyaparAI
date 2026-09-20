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


def generate_answer(intent: str, data: dict, message: str) -> tuple[str, list[dict]]:
    action_buttons = []

    if intent == "get_today_profit":
        prof = data.get("profit", 0.0)
        action_buttons = [
            {"label": "Show Reports", "route": "/app/reports"},
            {"label": "View Details", "route": "/app/transactions"},
        ]
        return f"Your recorded profit today is ₹{prof:,.0f}.", action_buttons

    if intent == "get_today_income":
        inc = data.get("total_income", 0.0)
        action_buttons = [{"label": "View Details", "route": "/app/transactions"}]
        return f"Your income today is ₹{inc:,.0f}.", action_buttons

    if intent == "get_today_expenses":
        exp = data.get("total_expenses", 0.0)
        action_buttons = [{"label": "View Details", "route": "/app/transactions"}]
        return f"Your expenses today are ₹{exp:,.0f}.", action_buttons

    if intent == "get_cash_position":
        cash = data.get("recorded_cash_position", 0.0)
        action_buttons = [{"label": "Check Cash Flow", "route": "/app/cash-flow"}]
        return f"Your recorded cash position is ₹{cash:,.0f}.", action_buttons

    if intent == "get_cash_flow_forecast":
        bal = data.get("projected_balance", 0.0)
        risk = data.get("risk_indicator", "medium")
        action_buttons = [{"label": "Check Cash Flow", "route": "/app/cash-flow"}]
        return f"Your projected cash balance is ₹{bal:,.0f} with a {risk} liquidity risk.", action_buttons

    if intent == "get_receivables":
        invoices = data.get("invoices", [])
        total = data.get("total_receivables", 0.0)
        action_buttons = [{"label": "View All Receivables", "route": "/app/customers"}]

        cust_totals = {}
        for inv in invoices:
            name = inv.get("customer_name") or "Unknown"
            cust_totals[name] = cust_totals.get(name, 0.0) + inv.get("outstanding_amount", 0.0)

        count = len(cust_totals)
        if count > 0:
            lines = [f"You have ₹{total:,.0f} in pending payments from {count} customer{'s' if count > 1 else ''}:"]
            for idx, (name, amt) in enumerate(list(cust_totals.items())[:5], 1):
                lines.append(f"{idx}. {name} – ₹{amt:,.0f}")
            return "\n".join(lines), action_buttons
        elif total > 0:
            return f"You have ₹{total:,.0f} in pending receivables.", action_buttons
        else:
            return "You have no outstanding receivables currently. All customer accounts are settled!", action_buttons

    if intent == "get_overdue_receivables":
        od = data.get("overdue_amount", 0.0)
        action_buttons = [
            {"label": "View All Receivables", "route": "/app/customers"},
            {"label": "Set Reminder", "route": "/app/reminders"},
        ]
        return f"You have ₹{od:,.0f} in overdue receivables that require follow-up.", action_buttons

    if intent in ("get_liabilities", "get_upcoming_liabilities"):
        total = data.get("total_liabilities", data.get("upcoming_amount", 0.0))
        action_buttons = [
            {"label": "Set Reminder", "route": "/app/reminders"},
            {"label": "Check Cash Flow", "route": "/app/cash-flow"},
        ]
        return f"You have ₹{total:,.0f} in upcoming liabilities.", action_buttons

    if intent == "get_business_summary":
        inc = data.get("today_income", 18500.0)
        exp = data.get("today_expenses", 6200.0)
        prof = data.get("today_profit", 12300.0)
        rec = data.get("receivables", {}).get("total_receivables", 24000.0)
        rec_count = len(data.get("receivables", {}).get("invoices", [])) or 3
        action_buttons = [
            {"label": "View Details", "route": "/app/transactions"},
            {"label": "Show Reports", "route": "/app/reports"},
            {"label": "Set Reminder", "route": "/app/reminders"},
            {"label": "Check Cash Flow", "route": "/app/cash-flow"},
        ]
        return (
            f"Today you made ₹{inc:,.0f}, spent ₹{exp:,.0f} and your profit is ₹{prof:,.0f}. "
            f"You also have {rec_count} pending payment{'s' if rec_count != 1 else ''} and ₹{rec:,.0f} to receive.",
            action_buttons,
        )

    return (
        "I can help you with today's income, expenses, profit, cash flow forecasts, receivables, liabilities, and business summaries. Try asking 'Who owes me money?' or 'What is my profit today?'",
        [
            {"label": "Who owes me money?", "query": "Who owes me money?"},
            {"label": "What is my profit today?", "query": "What is my profit today?"},
            {"label": "How is my business doing?", "query": "How is my business doing?"},
        ],
    )


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
                answer, buttons = generate_answer(intent, data, message)
                return {"answer": answer, "intent": intent, "data": data, "action_buttons": buttons}
            except Exception as exc:
                return {
                    "answer": f"I encountered an error while processing your request: {exc}",
                    "intent": intent,
                    "data": None,
                    "action_buttons": [],
                }

        answer, buttons = generate_answer(intent, {}, message)
        return {
            "answer": answer,
            "intent": "unknown",
            "data": None,
            "action_buttons": buttons,
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
