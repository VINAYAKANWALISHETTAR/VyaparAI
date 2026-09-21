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
    currency: str = "INR",
):
    if date is None:
        date = datetime.now(timezone.utc)
    elif isinstance(date, str):
        try:
            date = datetime.fromisoformat(date.replace("Z", "+00:00"))
            if date.tzinfo is None:
                date = date.replace(tzinfo=timezone.utc)
        except Exception:
            date = datetime.now(timezone.utc)
    elif isinstance(date, datetime):
        if date.tzinfo is None:
            date = date.replace(tzinfo=timezone.utc)
    elif hasattr(date, "year") and hasattr(date, "month") and hasattr(date, "day"):
        date = datetime.combine(date, datetime.min.time()).replace(tzinfo=timezone.utc)

    now = datetime.now(timezone.utc)
    return {
        "business_id": business_id,
        "user_id": user_id,
        "type": type.strip().lower(),
        "amount": round(float(amount), 2),
        "category": category.strip(),
        "description": description.strip() if description else None,
        "date": date,
        "currency": (currency or "INR").strip().upper(),
        "source": source.strip().lower(),
        "reference_id": reference_id.strip() if reference_id else None,
        "created_at": now,
        "updated_at": now,
    }
