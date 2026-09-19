from app.database.mongodb import db
from app.services.financial_service import FinancialService

financial_service = FinancialService()


def get_customer_balance(customer_name: str, business_id: str, user_id: str) -> dict:
    receivables = financial_service.get_receivables(business_id, user_id, customer_id=customer_name)
    return {
        "customer_name": customer_name,
        "total_receivables": receivables["total_receivables"],
        "overdue_amount": receivables["overdue_amount"],
        "invoices": receivables["invoices"],
    }


def get_supplier_balance(supplier_name: str, business_id: str, user_id: str) -> dict:
    transactions = db.transactions.find({
        "business_id": business_id,
        "type": "expense",
        "description": {"$regex": supplier_name, "$options": "i"},
    })

    total = 0.0
    obligations = []
    for txn in transactions:
        amount = float(txn["amount"])
        total += amount
        obligations.append({
            "id": str(txn["_id"]),
            "description": txn.get("description"),
            "amount": amount,
            "date": txn["date"].isoformat() if txn.get("date") else None,
            "source": txn.get("source"),
        })

    return {
        "supplier_name": supplier_name,
        "total_payables": total,
        "transaction_count": len(obligations),
        "obligations": obligations,
    }


def get_payment_history(customer_name: str, business_id: str, user_id: str) -> dict:
    transactions = db.transactions.find({
        "business_id": business_id,
        "type": "income",
        "category": "customer_payment",
        "description": {"$regex": customer_name, "$options": "i"},
    })

    payments = []
    total_received = 0.0
    for txn in transactions:
        amount = float(txn["amount"])
        total_received += amount
        payments.append({
            "id": str(txn["_id"]),
            "amount": amount,
            "date": txn["date"].isoformat() if txn.get("date") else None,
            "description": txn.get("description"),
            "source": txn.get("source"),
            "reference_id": txn.get("reference_id"),
        })

    return {
        "customer_name": customer_name,
        "total_received": total_received,
        "payment_count": len(payments),
        "payments": payments,
    }
