from datetime import datetime, timezone


def invoice_document(
    business_id: str,
    customer_name: str,
    amount: float,
    due_date,
    description: str | None = None,
    invoice_number: str | None = None,
    paid_amount: float = 0.0,
    outstanding_amount: float | None = None,
    status: str = "unpaid",
):
    if due_date is not None:
        if isinstance(due_date, datetime):
            if due_date.tzinfo is None:
                due_date = due_date.replace(tzinfo=timezone.utc)
        elif hasattr(due_date, "year") and hasattr(due_date, "month") and hasattr(due_date, "day"):
            due_date = datetime.combine(due_date, datetime.min.time()).replace(tzinfo=timezone.utc)

    if outstanding_amount is None:
        outstanding_amount = amount

    return {
        "business_id": business_id,
        "customer_name": customer_name,
        "invoice_number": invoice_number,
        "amount": amount,
        "paid_amount": paid_amount,
        "outstanding_amount": outstanding_amount,
        "due_date": due_date,
        "description": description,
        "status": status,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }
