from datetime import datetime, timezone


def transaction_document(
    business_id: str,
    transaction_type: str,
    amount: float,
    category: str,
    transaction_date,
    description: str | None = None,
    source: str = "manual",
    reference: str | None = None,
):
    if hasattr(transaction_date, "isoformat"):
        transaction_date = datetime.combine(
            transaction_date,
            datetime.min.time(),
        ).replace(tzinfo=timezone.utc)

    return {
        "business_id": business_id,
        "transaction_type": transaction_type,
        "amount": amount,
        "category": category,
        "description": description,
        "transaction_date": transaction_date,
        "source": source,
        "reference": reference,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }
