import re
from datetime import datetime, timezone
from decimal import Decimal

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
from app.database.mongodb import db
from app.models.transaction import transaction_document
from app.services.financial_service import FinancialService

financial_service = FinancialService()


def parse_transaction_voice(message: str) -> dict | None:
    text = message.strip()
    text_lower = text.lower()

    # Match Income patterns:
    # 1. "Ramesh paid 5000", "Sharma paid me 12000"
    m = re.search(r'([A-Za-z]+)\s+(?:paid|transferred|gave)(?:\s+me)?\s+(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d+)?)', text, re.IGNORECASE)
    if m:
        party = m.group(1).strip()
        amt_str = m.group(2).replace(',', '')
        try:
            amt = float(amt_str)
            if amt > 0:
                return {
                    "type": "income",
                    "amount": amt,
                    "category": "Customer Payment",
                    "party_name": party.capitalize(),
                    "description": f"Payment from {party.capitalize()}",
                }
        except ValueError:
            pass

    # 2. "Received 5000 from Ramesh", "Received payment of 3000 from Anil"
    m = re.search(r'received\s+(?:payment\s+of\s+)?(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d+)?)\s+from\s+([A-Za-z]+)', text, re.IGNORECASE)
    if m:
        amt_str = m.group(1).replace(',', '')
        party = m.group(2).strip()
        try:
            amt = float(amt_str)
            if amt > 0:
                return {
                    "type": "income",
                    "amount": amt,
                    "category": "Sale",
                    "party_name": party.capitalize(),
                    "description": f"Received from {party.capitalize()}",
                }
        except ValueError:
            pass

    # 3. "Add sale 4500", "Record sale of 6000", "Made a sale of 1500"
    m = re.search(r'(?:add|record|made)(?:\s+a)?\s+sale(?:\s+of)?\s+(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d+)?)', text, re.IGNORECASE)
    if m:
        amt_str = m.group(1).replace(',', '')
        try:
            amt = float(amt_str)
            if amt > 0:
                return {
                    "type": "income",
                    "amount": amt,
                    "category": "Sale",
                    "description": "General Sale",
                }
        except ValueError:
            pass

    # Match Expense patterns:
    # 1. "Spent 500 on chai and snacks", "Spent 1200 on diesel"
    m = re.search(r'spent\s+(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d+)?)\s+(?:on|for)\s+(.+)', text, re.IGNORECASE)
    if m:
        amt_str = m.group(1).replace(',', '')
        cat = m.group(2).strip().capitalize()
        try:
            amt = float(amt_str)
            if amt > 0:
                return {
                    "type": "expense",
                    "amount": amt,
                    "category": cat,
                    "description": f"Expense for {cat}",
                }
        except ValueError:
            pass

    # 2. "Paid 1500 for electricity", "Paid 800 for transport"
    m = re.search(r'paid\s+(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d+)?)\s+(?:for|to|on)\s+(.+)', text, re.IGNORECASE)
    if m:
        amt_str = m.group(1).replace(',', '')
        cat = m.group(2).strip().capitalize()
        try:
            amt = float(amt_str)
            if amt > 0:
                return {
                    "type": "expense",
                    "amount": amt,
                    "category": cat,
                    "description": f"Payment for {cat}",
                }
        except ValueError:
            pass

    # 3. "Add expense of 800", "Record expense 450"
    m = re.search(r'(?:add|record)\s+(?:an?\s+)?expense(?:\s+of)?\s+(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d+)?)', text, re.IGNORECASE)
    if m:
        amt_str = m.group(1).replace(',', '')
        try:
            amt = float(amt_str)
            if amt > 0:
                return {
                    "type": "expense",
                    "amount": amt,
                    "category": "General Expense",
                    "description": "General Expense",
                }
        except ValueError:
            pass

    return None


def classify_intent(message: str) -> tuple[str, dict | None]:
    text = message.strip().lower()

    # Check for greetings
    greetings = ["hello", "hi", "hey", "good morning", "good evening", "namaste", "who are you", "what can you do", "help"]
    if any(text == g or text.startswith(g + " ") or text.startswith(g + ",") or text.startswith(g + "!") for g in greetings):
        return "greeting", {}

    # Check for voice transaction recording
    txn_parsed = parse_transaction_voice(message)
    if txn_parsed:
        return "record_transaction", txn_parsed

    if "profit" in text and ("today" in text or "now" in text or "current" in text or len(text.split()) <= 4):
        return "get_today_profit", {}
    if ("income" in text or "revenue" in text or "sales" in text) and ("today" in text or len(text.split()) <= 4):
        return "get_today_income", {}
    if "expense" in text and ("today" in text or len(text.split()) <= 4):
        return "get_today_expenses", {}
    if "cash position" in text or "current cash" in text or "balance" in text:
        return "get_cash_position", {}
    if "cash flow" in text or "forecast" in text or "projection" in text:
        return "get_cash_flow_forecast", {}
    if ("receivable" in text or "overdue" in text) and "overdue" in text:
        return "get_overdue_receivables", {}
    if "receivable" in text or "who owes" in text or "pending payment" in text or "customers owe" in text:
        return "get_receivables", {}
    if ("liability" in text or "payables" in text or "what do i owe" in text or "supplier due" in text) and "upcoming" in text:
        return "get_upcoming_liabilities", {}
    if "liability" in text or "payables" in text or "what do i owe" in text or "supplier due" in text:
        return "get_liabilities", {}
    if "invoice" in text:
        return "get_invoice", {}
    if "customer" in text and "balance" in text:
        return "get_customer_balance", {}
    if "payment history" in text or "received from" in text:
        return "get_payment_history", {}
    if "summary" in text or "overview" in text or "business" in text or "doing" in text:
        return "get_business_summary", {}

    return "unknown", {}


def generate_answer(intent: str, data: dict, message: str) -> tuple[str, list[dict]]:
    action_buttons = []

    if intent == "greeting":
        return (
            "Hello! I am your VyaparAI bot. How can I assist your business today? "
            "You can ask about your profit, revenue, expenses, who owes you money, "
            "or tell me to record a transaction like 'Ramesh paid 5000' or 'Add expense 500 for tea'.",
            [
                {"label": "What is my profit today?", "query": "What is my profit today?"},
                {"label": "Who owes me money?", "query": "Who owes me money?"},
                {"label": "How is my business doing?", "query": "How is my business doing?"},
            ],
        )

    if intent == "record_transaction":
        txn = data.get("transaction", {})
        amt = txn.get("amount", 0.0)
        ttype = txn.get("type", "income")
        desc = txn.get("description", "")
        today_income = data.get("today_income", amt if ttype == "income" else 0.0)
        today_expense = data.get("today_expenses", amt if ttype == "expense" else 0.0)

        action_buttons = [
            {"label": "View Details", "route": "/app/transactions"},
            {"label": "Show Reports", "route": "/app/reports"},
        ]

        if ttype == "income":
            return (
                f"I have recorded a sale/income of ₹{amt:,.0f} ({desc}) into your records! ✓\n"
                f"Your today's revenue is now ₹{today_income:,.0f}.",
                action_buttons,
            )
        else:
            return (
                f"I have recorded an expense of ₹{amt:,.0f} ({desc}) into your records! ✓\n"
                f"Your today's total expenses are now ₹{today_expense:,.0f}.",
                action_buttons,
            )

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
        return f"Your revenue/income today is ₹{inc:,.0f}.", action_buttons

    if intent == "get_today_expenses":
        exp = data.get("total_expenses", 0.0)
        action_buttons = [{"label": "View Details", "route": "/app/transactions"}]
        return f"Your expenses today are ₹{exp:,.0f}.", action_buttons

    if intent == "get_cash_position":
        cash = data.get("recorded_cash_position", 0.0)
        action_buttons = [{"label": "Check Cash Flow", "route": "/app/cash-flow"}]
        return f"Your recorded net cash position is ₹{cash:,.0f}.", action_buttons

    if intent == "get_cash_flow_forecast":
        bal = data.get("projected_balance", 0.0)
        risk = data.get("risk_indicator", "low")
        action_buttons = [{"label": "Check Cash Flow", "route": "/app/cash-flow"}]
        return f"Your projected 30-day cash balance is ₹{bal:,.0f} with a {risk} liquidity risk.", action_buttons

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
        inc = data.get("today_income", 0.0)
        exp = data.get("today_expenses", 0.0)
        prof = data.get("today_profit", inc - exp)
        rec = data.get("receivables", {}).get("total_receivables", 0.0)
        rec_count = len(data.get("receivables", {}).get("invoices", []))
        action_buttons = [
            {"label": "View Details", "route": "/app/transactions"},
            {"label": "Show Reports", "route": "/app/reports"},
            {"label": "Set Reminder", "route": "/app/reminders"},
            {"label": "Check Cash Flow", "route": "/app/cash-flow"},
        ]
        return (
            f"Here is your business overview: Today's revenue is ₹{inc:,.0f}, expenses are ₹{exp:,.0f}, "
            f"and net profit is ₹{prof:,.0f}. "
            f"You have {rec_count} pending receivable{'s' if rec_count != 1 else ''} totaling ₹{rec:,.0f}.",
            action_buttons,
        )

    return (
        "Hello! I am your VyaparAI bot. I can help analyze your income, expenses, profit, cash flow forecasts, receivables, liabilities, or record transactions directly by voice. Try asking 'What is my profit today?' or say 'Ramesh paid 5000'.",
        [
            {"label": "What is my profit today?", "query": "What is my profit today?"},
            {"label": "Who owes me money?", "query": "Who owes me money?"},
            {"label": "How is my business doing?", "query": "How is my business doing?"},
        ],
    )


class CopilotService:
    def __init__(self):
        self._intent_handlers = {
            "greeting": self._handle_greeting,
            "record_transaction": self._handle_record_transaction,
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
                data = handler(user_id, business_id, **(params or {}))
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

    def _handle_greeting(self, user_id: str, business_id: str | None, **kwargs):
        return {}

    def _handle_record_transaction(self, user_id: str, business_id: str | None, **kwargs):
        # Resolve active business_id
        if not business_id:
            businesses = list(db.businesses.find({"owner_id": user_id}))
            if businesses:
                business_id = str(businesses[0]["_id"])
            else:
                # Create a default business for the user if none exists
                res = db.businesses.insert_one({
                    "owner_id": user_id,
                    "name": "My Business",
                    "currency": "INR",
                    "created_at": datetime.now(timezone.utc),
                    "updated_at": datetime.now(timezone.utc),
                })
                business_id = str(res.inserted_id)

        ttype = kwargs.get("type", "income")
        amount = float(kwargs.get("amount", 0.0))
        category = kwargs.get("category", "Sale" if ttype == "income" else "General Expense")
        desc = kwargs.get("description")
        now = datetime.now(timezone.utc)

        # Create and insert transaction document
        doc = transaction_document(
            business_id=business_id,
            type=ttype,
            amount=amount,
            category=category,
            description=desc,
            date=now,
            source="voice",
            user_id=user_id,
        )
        db.transactions.insert_one(doc)

        # Compute updated today's summary
        inc_res = get_today_income(business_id, user_id)
        exp_res = get_today_expenses(business_id, user_id)

        return {
            "transaction": {
                "type": ttype,
                "amount": amount,
                "category": category,
                "description": desc,
            },
            "today_income": inc_res.get("total_income", amount if ttype == "income" else 0.0),
            "today_expenses": exp_res.get("total_expenses", amount if ttype == "expense" else 0.0),
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
