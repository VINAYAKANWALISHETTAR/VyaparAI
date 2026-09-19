from bson import ObjectId

from app.database.mongodb import db


def get_invoice(invoice_id: str, business_id: str) -> dict | None:
    try:
        invoice_object_id = ObjectId(invoice_id)
    except Exception:
        return None

    invoice = db.invoices.find_one({
        "_id": invoice_object_id,
        "business_id": business_id,
    })

    if not invoice:
        return None

    return {
        "id": str(invoice["_id"]),
        "invoice_number": invoice.get("invoice_number"),
        "customer_name": invoice["customer_name"],
        "amount": float(invoice["amount"]),
        "paid_amount": float(invoice.get("paid_amount", 0)),
        "outstanding_amount": float(invoice.get("outstanding_amount", invoice["amount"])),
        "due_date": invoice["due_date"].isoformat() if invoice.get("due_date") else None,
        "status": invoice.get("status", "unpaid"),
        "description": invoice.get("description"),
    }
