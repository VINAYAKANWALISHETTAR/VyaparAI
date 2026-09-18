from datetime import datetime, timezone


def invoice_document(
    business_id: str,
    customer_name: str,
    amount: float,
    due_date,
    description: str | None = None,
    invoice_number: str | None = None,
):
    if hasattr(due_date, "isoformat"):
        due_date = datetime.combine(
            due_date,
            datetime.min.time(),
        ).replace(tzinfo=timezone.utc)

    return {
        "business_id": business_id,
        "customer_name": customer_name,
        "invoice_number": invoice_number,
        "amount": amount,
        "due_date": due_date,
        "description": description,
        "status": "unpaid",
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }
