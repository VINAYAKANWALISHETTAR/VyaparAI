from datetime import date

from app.database.mongodb import db
from app.services.financial_service import FinancialService

financial_service = FinancialService()


def get_receivable_aging(business_id: str | None, user_id: str):
    business_ids = financial_service._get_user_business_ids(user_id)
    if business_id:
        financial_service._verify_business_access(business_id, user_id)
        business_ids = [business_id]

    invoices = db.invoices.find({
        "business_id": {"$in": business_ids},
        "outstanding_amount": {"$gt": 0},
    })

    today = date.today()
    aging_buckets = {
        "0-30": 0.0,
        "31-60": 0.0,
        "61-90": 0.0,
        "90+": 0.0,
    }
    invoice_list = []
    total_receivables = 0.0

    for invoice in invoices:
        amount = float(invoice["amount"])
        paid_amount = float(invoice.get("paid_amount", 0))
        outstanding = float(invoice.get("outstanding_amount", amount - paid_amount))
        due_date = invoice.get("due_date")

        if hasattr(due_date, "date"):
            due_date = due_date.date()

        days_outstanding = 0
        if due_date:
            days_outstanding = (today - due_date).days
            if days_outstanding < 0:
                days_outstanding = 0

        if days_outstanding <= 30:
            bucket = "0-30"
        elif days_outstanding <= 60:
            bucket = "31-60"
        elif days_outstanding <= 90:
            bucket = "61-90"
        else:
            bucket = "90+"

        aging_buckets[bucket] += outstanding
        total_receivables += outstanding

        invoice_list.append({
            "id": str(invoice["_id"]),
            "invoice_number": invoice.get("invoice_number"),
            "customer_name": invoice["customer_name"],
            "amount": amount,
            "paid_amount": paid_amount,
            "outstanding_amount": outstanding,
            "due_date": due_date.isoformat() if due_date else None,
            "days_outstanding": days_outstanding,
            "aging_bucket": bucket,
        })

    return {
        "total_receivables": total_receivables,
        "aging_buckets": aging_buckets,
        "invoices": invoice_list,
    }


def get_customer_summary(business_id: str | None, user_id: str):
    business_ids = financial_service._get_user_business_ids(user_id)
    if business_id:
        financial_service._verify_business_access(business_id, user_id)
        business_ids = [business_id]

    invoices = db.invoices.find({
        "business_id": {"$in": business_ids},
        "outstanding_amount": {"$gt": 0},
    })

    customer_map = {}
    total_receivables = 0.0

    for invoice in invoices:
        customer_name = invoice["customer_name"]
        amount = float(invoice["amount"])
        paid_amount = float(invoice.get("paid_amount", 0))
        outstanding = float(invoice.get("outstanding_amount", amount - paid_amount))

        if customer_name not in customer_map:
            customer_map[customer_name] = {
                "customer_name": customer_name,
                "amount": 0.0,
                "paid_amount": 0.0,
                "outstanding_amount": 0.0,
                "invoice_count": 0,
            }

        customer_map[customer_name]["amount"] += amount
        customer_map[customer_name]["paid_amount"] += paid_amount
        customer_map[customer_name]["outstanding_amount"] += outstanding
        customer_map[customer_name]["invoice_count"] += 1
        total_receivables += outstanding

    return {
        "total_receivables": total_receivables,
        "customers": list(customer_map.values()),
    }


def get_supplier_summary(business_id: str | None, user_id: str):
    business_ids = financial_service._get_user_business_ids(user_id)
    if business_id:
        financial_service._verify_business_access(business_id, user_id)
        business_ids = [business_id]

    transactions = db.transactions.find({
        "business_id": {"$in": business_ids},
        "type": "expense",
    })

    supplier_map = {}
    total_payables = 0.0

    for txn in transactions:
        supplier_name = txn.get("description") or txn.get("category", "unknown")
        amount = float(txn["amount"])

        if supplier_name not in supplier_map:
            supplier_map[supplier_name] = {
                "name": supplier_name,
                "amount": 0.0,
                "paid_amount": 0.0,
                "outstanding_amount": 0.0,
                "transaction_count": 0,
            }

        supplier_map[supplier_name]["amount"] += amount
        supplier_map[supplier_name]["paid_amount"] += amount
        supplier_map[supplier_name]["outstanding_amount"] += amount
        supplier_map[supplier_name]["transaction_count"] += 1
        total_payables += amount

    return {
        "total_payables": total_payables,
        "suppliers": list(supplier_map.values()),
    }
