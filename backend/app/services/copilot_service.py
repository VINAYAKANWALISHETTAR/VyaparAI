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

    # 4. Flexible English & Multilingual Income: "Sale 500", "500 sale", "Sold goods 1500", "500 ಮಾರಾಟ", "500 की बिक्री"
    m = re.search(r'(?:(?:add|record|made|enter|log)\s+(?:a\s+)?)?(?:sale|income|revenue|ಮಾರಾಟ|ಆದಾಯ|बिक्री|आय|कमाई)\s+(?:of\s+)?(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d+)?)', text, re.IGNORECASE)
    if not m:
        m = re.search(r'(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d+)?)\s*(?:rs|rupees|ರೂಪಾಯಿ|रुपये)?\s+(?:sale|income|ಮಾರಾಟ|ಆದಾಯ|बिक्री|आय)', text, re.IGNORECASE)
    if not m:
        m = re.search(r'sold\s+(?:goods|items)?\s*(?:for)?\s*(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d+)?)', text, re.IGNORECASE)
    if m:
        amt_str = m.group(1).replace(',', '')
        try:
            amt = float(amt_str)
            if amt > 0:
                return {
                    "type": "income",
                    "amount": amt,
                    "category": "Sale",
                    "description": "Sale Transaction",
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

    # 3. Flexible English & Multilingual Expense: "Add expense 800", "500 expense", "500 ಖರ್ಚು", "500 खर्च"
    m = re.search(r'(?:add|record|enter|log)\s+(?:an?\s+)?(?:expense|spending|cost|ಖರ್ಚು|ವೆಚ್ಚ|खर्च|व्यय)(?:\s+of)?\s+(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d+)?)', text, re.IGNORECASE)
    if not m:
        m = re.search(r'(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d+)?)\s*(?:rs|rupees|ರೂಪಾಯಿ|रुपये)?\s+(?:expense|spending|ಖರ್ಚು|ವೆಚ್ಚ|खर्च|व्यय)', text, re.IGNORECASE)
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

    # Check for greetings in English, Kannada, and Hindi
    greetings = [
        "hello", "hi", "hey", "good morning", "good evening", "namaste", "who are you",
        "what can you do", "help", "ನಮಸ್ಕಾರ", "ಹಲೋ", "ಶುಭೋದಯ", "ನಮಸ್ತೆ", "नमस्ते", "नमस्कार", "सुप्रभात"
    ]
    if any(text == g or text.startswith(g + " ") or text.startswith(g + ",") or text.startswith(g + "!") for g in greetings):
        return "greeting", {}

    # Check for voice transaction recording (English, Kannada, Hindi)
    txn_parsed = parse_transaction_voice(message)
    if txn_parsed:
        return "record_transaction", txn_parsed

    # 1. Profit queries (English, Kannada, Hindi)
    profit_keywords = ["profit", "margins", "earnings", "ಲಾಭ", "लाभ", "मुनाफा"]
    if any(k in text for k in profit_keywords):
        return "get_today_profit", {}

    # 2. Income / Revenue / Sales queries (English, Kannada, Hindi)
    income_keywords = [
        "income", "revenue", "sale", "sales", "made today", "earned", "turnover",
        "ಮಾರಾಟ", "ಆದಾಯ", "ಬಂದ ಹಣ", "आय", "राजस्व", "बिक्री", "कमाई"
    ]
    if any(k in text for k in income_keywords):
        return "get_today_income", {}

    # 3. Expense / Spending queries (English, Kannada, Hindi)
    expense_keywords = [
        "expense", "expenses", "spend", "spent", "spending", "cost", "costs",
        "ಖರ್ಚು", "ವೆಚ್ಚ", "ಹೋದ ಹಣ", "खर्च", "व्यय", "खर्चा"
    ]
    if any(k in text for k in expense_keywords):
        return "get_today_expenses", {}

    # 4. Cash position queries
    cash_keywords = ["cash position", "current cash", "balance", "how much cash", "ನಗದು", "ಬ್ಯಾಲೆನ್ಸ್", "रोकड़", "बैलेंस", "तिजोरी"]
    if any(k in text for k in cash_keywords):
        return "get_cash_position", {}

    # 5. Cash flow forecast
    forecast_keywords = ["cash flow", "forecast", "projection", "next 30 days", "ನಗದು ಹರಿವು", "ಮುಂದಿನ", "रोकड़ प्रवाह", "पूर्वानुमान"]
    if any(k in text for k in forecast_keywords):
        return "get_cash_flow_forecast", {}

    # 6. Overdue receivables
    overdue_keywords = ["overdue", "late payment", "delayed", "ಮಿತಿಮೀರಿದ", "ಅವಧಿ ಮೀರಿದ", "ಅತಿ ಹೆಚ್ಚು ಬಾಕಿ", "अतिदेय", "देरी"]
    if any(k in text for k in overdue_keywords):
        return "get_overdue_receivables", {}

    # 7. Receivables / Who owes me money
    receivable_keywords = [
        "receivable", "receivables", "who owes", "pending payment", "customers owe", "due from", "owe me", "who has to pay",
        "ಕೊಡಬೇಕು", "ಬಾಕಿ", "ನನಗೆ ಯಾರು ಹಣ ಕೊಡಬೇಕು", "ಯಾರು ಕೊಡಬೇಕು", "ಬರಬೇಕಾದ",
        "बकाया", "पाना है", "किसका बकाया", "मुझ पर किसका", "किसने पैसे नहीं दिए", "किससे लेना है"
    ]
    if any(k in text for k in receivable_keywords):
        return "get_receivables", {}

    # 8. Liabilities / What do I owe to suppliers/others
    liability_keywords = [
        "liability", "liabilities", "payables", "what do i owe", "supplier due", "whom do i owe", "i have to pay", "pay to supplier",
        "ನಾನು ಕೊಡಬೇಕು", "ಸಾಲ", "ದೇಯತೆ", "ಪಾವತಿಸಬೇಕು",
        "देना है", "देनदारी", "किसको देना है", "उधार"
    ]
    if any(k in text for k in liability_keywords):
        return "get_liabilities", {}

    # 9. Invoice lookup
    if "invoice" in text or "bill" in text or "ರಶೀದಿ" in text or "ಇನ್‌ವಾಯ್ಸ್" in text or "बिल" in text or "बीजक" in text:
        return "get_invoice", {}

    # 10. Customer balance
    if ("customer" in text or "party" in text or "ಗ್ರಾಹಕ" in text or "ग्राहक" in text) and ("balance" in text or "ಬಾಕಿ" in text or "बैलेंस" in text):
        return "get_customer_balance", {}

    # 11. Payment history
    if "payment history" in text or "received from" in text or "ಇತಿಹಾಸ" in text or "इतिहास" in text:
        return "get_payment_history", {}

    # 12. Business summary / General overview
    summary_keywords = [
        "summary", "overview", "business", "doing", "how is", "store", "shop", "status", "performance",
        "ಅವಲೋಕನ", "ಸಾರಾಂಶ", "ಹೇಗಿದೆ", "ವಿವರಣೆ", "ಪರಿಸ್ಥಿತಿ",
        "सारांश", "अवलोकन", "कैसा चल रहा", "स्थिति", "दुकान", "कारोबार"
    ]
    if any(k in text for k in summary_keywords):
        return "get_business_summary", {}

    # 13. Recent transactions / history
    recent_keywords = [
        "recent", "latest", "last transaction", "last payment", "transactions today",
        "show transactions", "history", "records", "ಇತ್ತೀಚಿನ", "ಕೊನೆಯ", "ದಾಖಲೆಗಳು",
        "हाल के", "अंतिम लेनदेन", "इतिहास", "रिकॉर्ड"
    ]
    if any(k in text for k in recent_keywords):
        return "get_recent_transactions", {}

    return "unknown", {}


def generate_answer(intent: str, data: dict, message: str, language: str = "en") -> tuple[str, list[dict]]:
    lang = (language or "en").lower()
    action_buttons = []

    if intent == "greeting":
        if lang == "kn":
            return (
                "ನಮಸ್ಕಾರ! ಇಂದು ನಿಮ್ಮ ವ್ಯವಹಾರಕ್ಕೆ ನಾನು ಹೇಗೆ ಸಹಾಯ ಮಾಡಲಿ?",
                [
                    {"label": "ಇಂದು ನನ್ನ ಲಾಭ ಎಷ್ಟು?", "query": "ಇಂದು ನನ್ನ ಲಾಭ ಎಷ್ಟು?"},
                    {"label": "ನನಗೆ ಯಾರು ಹಣ ಕೊಡಬೇಕು?", "query": "ನನಗೆ ಯಾರು ಹಣ ಕೊಡಬೇಕು?"},
                    {"label": "ವ್ಯಾಪಾರ ಅವಲೋಕನ ತೋರಿಸಿ", "query": "ವ್ಯಾಪಾರ ಅವಲೋಕನ ತೋರಿಸಿ"},
                ],
            )
        elif lang == "hi":
            return (
                "नमस्ते! आज मैं आपके व्यवसाय में कैसे मदद कर सकता हूँ?",
                [
                    {"label": "आज मेरा लाभ कितना है?", "query": "आज मेरा लाभ कितना है?"},
                    {"label": "मुझ पर किसका बकाया है?", "query": "मुझ पर किसका बकाया है?"},
                    {"label": "व्यवसाय सारांश दिखाएं", "query": "व्यवसाय सारांश दिखाएं"},
                ],
            )
        return (
            "Hello! How can I help your business today?",
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

        if lang == "kn":
            if ttype == "income":
                return (
                    f"₹{amt:,.0f} ಆದಾಯ ದಾಖಲಿಸಲಾಗಿದೆ. ಇಂದಿನ ಒಟ್ಟು ಮಾರಾಟ ₹{today_income:,.0f}.",
                    action_buttons,
                )
            else:
                return (
                    f"₹{amt:,.0f} ವೆಚ್ಚ ದಾಖಲಿಸಲಾಗಿದೆ. ಇಂದಿನ ಒಟ್ಟು ವೆಚ್ಚ ₹{today_expense:,.0f}.",
                    action_buttons,
                )
        elif lang == "hi":
            if ttype == "income":
                return (
                    f"₹{amt:,.0f} की आय दर्ज की गई। आज का कुल राजस्व ₹{today_income:,.0f} है।",
                    action_buttons,
                )
            else:
                return (
                    f"₹{amt:,.0f} का खर्च दर्ज किया गया। आज का कुल खर्च ₹{today_expense:,.0f} है।",
                    action_buttons,
                )

        if ttype == "income":
            return (
                f"Recorded sale of ₹{amt:,.0f} ({desc}). Today's total sales are ₹{today_income:,.0f}.",
                action_buttons,
            )
        else:
            return (
                f"Recorded expense of ₹{amt:,.0f} ({desc}). Today's total expenses are ₹{today_expense:,.0f}.",
                action_buttons,
            )

    if intent == "get_today_profit":
        prof = data.get("profit", 0.0)
        action_buttons = [
            {"label": "Show Reports", "route": "/app/reports"},
            {"label": "View Details", "route": "/app/transactions"},
        ]
        if lang == "kn":
            return f"ಇಂದು ನಿಮ್ಮ ದಾಖಲಾದ ನಿವ್ವಳ ಲಾಭ ₹{prof:,.0f}.", action_buttons
        elif lang == "hi":
            return f"आज आपका दर्ज किया गया शुद्ध लाभ ₹{prof:,.0f} है।", action_buttons
        return f"Your recorded profit today is ₹{prof:,.0f}.", action_buttons

    if intent == "get_today_income":
        inc = data.get("total_income", 0.0)
        action_buttons = [{"label": "View Details", "route": "/app/transactions"}]
        if lang == "kn":
            return f"ಇಂದು ನಿಮ್ಮ ಒಟ್ಟು ಆದಾಯ/ಮಾರಾಟ ₹{inc:,.0f}.", action_buttons
        elif lang == "hi":
            return f"आज आपकी कुल आय/राजस्व ₹{inc:,.0f} है।", action_buttons
        return f"Your revenue/income today is ₹{inc:,.0f}.", action_buttons

    if intent == "get_today_expenses":
        exp = data.get("total_expenses", 0.0)
        action_buttons = [{"label": "View Details", "route": "/app/transactions"}]
        if lang == "kn":
            return f"ಇಂದು ನಿಮ್ಮ ಒಟ್ಟು ವೆಚ್ಚ ₹{exp:,.0f}.", action_buttons
        elif lang == "hi":
            return f"आज आपका कुल खर्च ₹{exp:,.0f} है।", action_buttons
        return f"Your expenses today are ₹{exp:,.0f}.", action_buttons

    if intent == "get_cash_position":
        cash = data.get("recorded_cash_position", 0.0)
        action_buttons = [{"label": "Check Cash Flow", "route": "/app/cash-flow"}]
        if lang == "kn":
            return f"ನಿಮ್ಮ ದಾಖಲಾದ ನಿವ್ವಳ ನಗದು ಸ್ಥಿತಿ ₹{cash:,.0f} ಆಗಿದೆ.", action_buttons
        elif lang == "hi":
            return f"आपकी दर्ज की गई शुद्ध नकद स्थिति ₹{cash:,.0f} है।", action_buttons
        return f"Your recorded net cash position is ₹{cash:,.0f}.", action_buttons

    if intent == "get_cash_flow_forecast":
        bal = data.get("projected_balance", 0.0)
        risk = data.get("risk_indicator", "low")
        action_buttons = [{"label": "Check Cash Flow", "route": "/app/cash-flow"}]
        if lang == "kn":
            return f"ನಿಮ್ಮ 30 ದಿನಗಳ ಅಂದಾಜು ನಗದು ಬಾಕಿ ₹{bal:,.0f} ಆಗಿದೆ ({risk} ಅಪಾಯ).", action_buttons
        elif lang == "hi":
            return f"आपका 30 दिनों का अनुमानित नकद शेष ₹{bal:,.0f} है ({risk} जोखिम)।", action_buttons
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
            if lang == "kn":
                lines = [f"ನಿಮ್ಮ {count} ಗ್ರಾಹಕರಿಂದ ಒಟ್ಟು ₹{total:,.0f} ಬಾಕಿ ಪಾವತಿಗಳಿವೆ:"]
                for idx, (name, amt) in enumerate(list(cust_totals.items())[:5], 1):
                    lines.append(f"{idx}. {name} – ₹{amt:,.0f}")
                return "\n".join(lines), action_buttons
            elif lang == "hi":
                lines = [f"आपके पास {count} ग्राहकों से कुल ₹{total:,.0f} का बकाया है:"]
                for idx, (name, amt) in enumerate(list(cust_totals.items())[:5], 1):
                    lines.append(f"{idx}. {name} – ₹{amt:,.0f}")
                return "\n".join(lines), action_buttons
            lines = [f"You have ₹{total:,.0f} in pending payments from {count} customer{'s' if count > 1 else ''}:"]
            for idx, (name, amt) in enumerate(list(cust_totals.items())[:5], 1):
                lines.append(f"{idx}. {name} – ₹{amt:,.0f}")
            return "\n".join(lines), action_buttons
        elif total > 0:
            if lang == "kn":
                return f"ನಿಮ್ಮ ಗ್ರಾಹಕರಿಂದ ಒಟ್ಟು ₹{total:,.0f} ಬಾಕಿ ಹಣವಿದೆ.", action_buttons
            elif lang == "hi":
                return f"आपके पास कुल ₹{total:,.0f} का प्राप्य बकाया है।", action_buttons
            return f"You have ₹{total:,.0f} in pending receivables.", action_buttons
        else:
            if lang == "kn":
                return "ಪ್ರಸ್ತುತ ಯಾವುದೇ ಬಾಕಿ ಪಾವತಿಗಳಿಲ್ಲ. ಎಲ್ಲಾ ಖಾತೆಗಳು ಪಾವತಿಯಾಗಿವೆ!", action_buttons
            elif lang == "hi":
                return "वर्तमान में कोई बकाया प्राप्य नहीं है। सभी खाते चुकता हैं!", action_buttons
            return "You have no outstanding receivables currently. All customer accounts are settled!", action_buttons

    if intent == "get_overdue_receivables":
        od = data.get("overdue_amount", 0.0)
        action_buttons = [
            {"label": "View All Receivables", "route": "/app/customers"},
            {"label": "Set Reminder", "route": "/app/reminders"},
        ]
        if lang == "kn":
            return f"ನೀವು ವಸೂಲಿ ಮಾಡಬೇಕಾದ ₹{od:,.0f} ಮಿತಿಮೀರಿದ ಬಾಕಿ ಹಣವಿದೆ.", action_buttons
        elif lang == "hi":
            return f"आपके पास ₹{od:,.0f} की अतिदेय प्राप्य राशि है।", action_buttons
        return f"You have ₹{od:,.0f} in overdue receivables that require follow-up.", action_buttons

    if intent in ("get_liabilities", "get_upcoming_liabilities"):
        total = data.get("total_liabilities", data.get("upcoming_amount", 0.0))
        action_buttons = [
            {"label": "Set Reminder", "route": "/app/reminders"},
            {"label": "Check Cash Flow", "route": "/app/cash-flow"},
        ]
        if lang == "kn":
            return f"ನೀವು ಪಾವತಿಸಬೇಕಾದ ಮುಂಬರುವ ಬಾಧ್ಯತೆಗಳು ₹{total:,.0f}.", action_buttons
        elif lang == "hi":
            return f"आपकी आगामी देयताएं ₹{total:,.0f} हैं।", action_buttons
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
        if lang == "kn":
            return (
                f"ನಿಮ್ಮ ವ್ಯಾಪಾರ ಅವಲೋಕನ: ಇಂದಿನ ಆದಾಯ ₹{inc:,.0f}, ವೆಚ್ಚ ₹{exp:,.0f}, ಮತ್ತು ನಿವ್ವಳ ಲಾಭ ₹{prof:,.0f}. "
                f"ನಿಮ್ಮಲ್ಲಿ ಒಟ್ಟು ₹{rec:,.0f} ಮೊತ್ತದ {rec_count} ಬಾಕಿ ಪಾವತಿಗಳಿವೆ.",
                action_buttons,
            )
        elif lang == "hi":
            return (
                f"आपके व्यवसाय का विवरण: आज का राजस्व ₹{inc:,.0f}, खर्च ₹{exp:,.0f}, और शुद्ध लाभ ₹{prof:,.0f} है। "
                f"आपके पास कुल ₹{rec:,.0f} की {rec_count} बकाया राशियां हैं।",
                action_buttons,
            )
        return (
            f"Here is your business overview: Today's revenue is ₹{inc:,.0f}, expenses are ₹{exp:,.0f}, "
            f"and net profit is ₹{prof:,.0f}. "
            f"You have {rec_count} pending receivable{'s' if rec_count != 1 else ''} totaling ₹{rec:,.0f}.",
            action_buttons,
        )

    if intent == "get_recent_transactions":
        txns = data.get("transactions", [])
        action_buttons = [{"label": "View Details", "route": "/app/transactions"}]
        if txns:
            t = txns[0]
            amt = t.get("amount", 0.0)
            desc = t.get("description", "Transaction")
            if lang == "kn":
                return f"ನಿಮ್ಮ ಇತ್ತೀಚಿನ ವಹಿವಾಟು {desc} ಗಾಗಿ ₹{amt:,.0f}.", action_buttons
            elif lang == "hi":
                return f"आपका अंतिम लेनदेन {desc} के लिए ₹{amt:,.0f} था।", action_buttons
            return f"Your latest transaction was ₹{amt:,.0f} for {desc}.", action_buttons
        else:
            if lang == "kn":
                return "ಯಾವುದೇ ವಹಿವಾಟು ದಾಖಲಾಗಿಲ್ಲ. ಮೊದಲ ಮಾರಾಟ ದಾಖಲಿಸಲು 'Add sale 500' ಎಂದು ಹೇಳಿ.", action_buttons
            elif lang == "hi":
                return "कोई लेनदेन नहीं मिला। पहली बिक्री दर्ज करने के लिए 'Add sale 500' कहें।", action_buttons
            return "No transactions found. Say 'Add sale 500' to record one.", action_buttons

    # Dynamic Real-time Snapshot for general & fallback queries (Live Database Data)
    inc = float(data.get("today_income", 0.0))
    exp = float(data.get("today_expenses", 0.0))
    prof = float(data.get("today_profit", inc - exp))
    last_txn = data.get("last_transaction")
    action_buttons = [
        {"label": "View Details", "route": "/app/transactions"},
        {"label": "Show Reports", "route": "/app/reports"},
    ]
    if inc > 0 or exp > 0:
        if lang == "kn":
            return f"ಇಂದು: ಮಾರಾಟ ₹{inc:,.0f}, ವೆಚ್ಚ ₹{exp:,.0f}, ನಿವ್ವಳ ಲಾಭ ₹{prof:,.0f}.", action_buttons
        elif lang == "hi":
            return f"आज: बिक्री ₹{inc:,.0f}, खर्च ₹{exp:,.0f}, शुद्ध लाभ ₹{prof:,.0f}।", action_buttons
        return f"Today: Sales ₹{inc:,.0f}, Expenses ₹{exp:,.0f}, Net Profit ₹{prof:,.0f}.", action_buttons
    elif last_txn:
        amt = float(last_txn.get("amount", 0.0))
        desc = last_txn.get("description", "Transaction")
        if lang == "kn":
            return f"ಇಂದು ಇನ್ನೂ ಹೊಸ ಮಾರಾಟವಿಲ್ಲ. ಕೊನೆಯ ದಾಖಲೆ {desc} ಗಾಗಿ ₹{amt:,.0f}.", action_buttons
        elif lang == "hi":
            return f"आज कोई नया लेनदेन नहीं है। अंतिम लेनदेन {desc} के लिए ₹{amt:,.0f} था।", action_buttons
        return f"No sales recorded today yet. Your last record was ₹{amt:,.0f} for {desc}.", action_buttons
    else:
        if lang == "kn":
            return "ಯಾವುದೇ ವಹಿವಾಟು ದಾಖಲಾಗಿಲ್ಲ. ಮೊದಲ ಮಾರಾಟ ದಾಖಲಿಸಲು 'Add sale 500' ಎಂದು ಹೇಳಿ.", action_buttons
        elif lang == "hi":
            return "कोई लेनदेन दर्ज नहीं है। पहली बिक्री दर्ज करने के लिए 'Add sale 500' कहें।", action_buttons
        return "No transactions recorded yet. Say 'Add sale 500' to record your first sale.", action_buttons


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
            "get_recent_transactions": self._handle_recent_transactions,
            "realtime_snapshot": self._handle_realtime_snapshot,
        }

    def chat(self, user_id: str, message: str, business_id: str | None = None, language: str = "en") -> dict:
        intent, params = classify_intent(message)
        if intent == "unknown":
            intent = "realtime_snapshot"
            handler = self._handle_realtime_snapshot
        else:
            handler = self._intent_handlers.get(intent)

        if handler:
            try:
                data = handler(user_id, business_id, **(params or {}))
                answer, buttons = generate_answer(intent, data, message, language=language)
                return {"answer": answer, "intent": intent, "data": data, "action_buttons": buttons}
            except Exception as exc:
                try:
                    data = self._handle_realtime_snapshot(user_id, business_id)
                    answer, buttons = generate_answer("realtime_snapshot", data, message, language=language)
                    return {"answer": answer, "intent": "realtime_snapshot", "data": data, "action_buttons": buttons}
                except Exception:
                    return {
                        "answer": "Could not access records right now. Please try again.",
                        "intent": "error",
                        "data": None,
                        "action_buttons": [],
                    }

        data = self._handle_realtime_snapshot(user_id, business_id)
        answer, buttons = generate_answer("realtime_snapshot", data, message, language=language)
        return {
            "answer": answer,
            "intent": "realtime_snapshot",
            "data": data,
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

    def _handle_recent_transactions(self, user_id: str, business_id: str | None, **kwargs):
        filter_query = {"user_id": user_id}
        if business_id:
            filter_query = {"$or": [{"business_id": business_id}, {"user_id": user_id}]}
        txns = list(db.transactions.find(filter_query).sort("date", -1).limit(3))
        results = []
        for t in txns:
            results.append({
                "amount": float(t.get("amount", 0.0)),
                "type": t.get("type", "income"),
                "description": t.get("description") or t.get("category") or "Transaction",
                "party_name": t.get("party_name"),
            })
        return {"transactions": results}

    def _handle_realtime_snapshot(self, user_id: str, business_id: str | None, **kwargs):
        inc_res = get_today_income(business_id, user_id)
        exp_res = get_today_expenses(business_id, user_id)
        prof_res = get_today_profit(business_id, user_id)
        inc = float(inc_res.get("total_income", 0.0))
        exp = float(exp_res.get("total_expenses", 0.0))
        prof = float(prof_res.get("profit", inc - exp))

        filter_query = {"user_id": user_id}
        if business_id:
            filter_query = {"$or": [{"business_id": business_id}, {"user_id": user_id}]}
        txns = list(db.transactions.find(filter_query).sort("date", -1).limit(1))
        last_txn = None
        if txns:
            t = txns[0]
            last_txn = {
                "amount": float(t.get("amount", 0.0)),
                "type": t.get("type", "income"),
                "description": t.get("description") or t.get("category") or "Transaction",
            }
        return {
            "today_income": inc,
            "today_expenses": exp,
            "today_profit": prof,
            "last_transaction": last_txn,
        }


copilot_service = CopilotService()
