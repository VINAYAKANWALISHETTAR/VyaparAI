from app.database.mongodb import db
from app.services.financial_service import FinancialService

financial_service = FinancialService()


def get_anomalies(user_id: str):
    business_ids = financial_service._get_user_business_ids(user_id)
    anomalies = []

    anomalies.extend(_check_duplicate_invoices(business_ids))
    anomalies.extend(_check_overpayments(business_ids))
    anomalies.extend(_check_unusual_expenses(business_ids))

    return {
        "anomaly_count": len(anomalies),
        "anomalies": anomalies,
    }


def _check_duplicate_invoices(business_ids: list[str]):
    anomalies = []
    invoices = db.invoices.find({"business_id": {"$in": business_ids}})

    seen = {}
    for invoice in invoices:
        invoice_number = invoice.get("invoice_number")
        if not invoice_number:
            continue

        key = (str(invoice["business_id"]), invoice_number.strip().lower())
        if key in seen:
            anomalies.append({
                "id": str(invoice["_id"]),
                "type": "invoice",
                "severity": "medium",
                "message": "Duplicate invoice number detected. Please review.",
                "data": {
                    "invoice_number": invoice_number,
                    "business_id": str(invoice["business_id"]),
                    "existing_invoice_id": seen[key],
                    "duplicate_invoice_id": str(invoice["_id"]),
                },
            })
        else:
            seen[key] = str(invoice["_id"])

    return anomalies


def _check_overpayments(business_ids: list[str]):
    anomalies = []
    invoices = db.invoices.find({
        "business_id": {"$in": business_ids},
        "outstanding_amount": {"$lt": 0},
    })

    for invoice in invoices:
        anomalies.append({
            "id": str(invoice["_id"]),
            "type": "invoice",
            "severity": "high",
            "message": "Payment exceeds invoice amount. Please review.",
            "data": {
                "invoice_number": invoice.get("invoice_number"),
                "amount": float(invoice["amount"]),
                "paid_amount": float(invoice.get("paid_amount", 0)),
                "outstanding_amount": float(invoice.get("outstanding_amount", 0)),
            },
        })

    return anomalies


def _check_unusual_expenses(business_ids: list[str]):
    anomalies = []
    transactions = db.transactions.find({
        "business_id": {"$in": business_ids},
        "type": "expense",
    })

    category_stats = {}
    for txn in transactions:
        category = txn.get("category", "unknown")
        amount = float(txn["amount"])
        if category not in category_stats:
            category_stats[category] = []
        category_stats[category].append(amount)

    category_avg = {}
    for category, amounts in category_stats.items():
        if amounts:
            category_avg[category] = sum(amounts) / len(amounts)

    for txn in transactions:
        category = txn.get("category", "unknown")
        amount = float(txn["amount"])
        avg = category_avg.get(category)

        if avg and avg > 0 and amount > avg * 3:
            anomalies.append({
                "id": str(txn["_id"]),
                "type": "transaction",
                "severity": "medium",
                "message": "Unusually large expense detected. Please review.",
                "data": {
                    "category": category,
                    "amount": amount,
                    "average_for_category": avg,
                    "description": txn.get("description"),
                },
            })

    return anomalies
