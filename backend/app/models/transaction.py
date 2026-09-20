from datetime import datetime, timezone


def transaction_document(
    business_id: str,
    type: str,
    amount: float,
    category: str,
    date,
    description: str | None = None,
    source: str = "manual",
    reference_id: str | None = None,
    user_id: str | None = None,
):
    if date is not None:
        if isinstance(date, datetime):
            if date.tzinfo is None:
                date = date.replace(tzinfo=timezone.utc)
        elif hasattr(date, "year") and hasattr(date, "month") and hasattr(date, "day"):
            date = datetime.combine(date, datetime.min.time()).replace(tzinfo=timezone.utc)

    return {
        "business_id": business_id,
        "user_id": user_id,
        "type": type,
        "amount": amount,
        "category": category,
        "description": description,
        "date": date,
        "source": source,
        "reference_id": reference_id,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }
