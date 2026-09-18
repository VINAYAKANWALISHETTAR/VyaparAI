from datetime import datetime, timezone


def business_document(
    name: str,
    business_type: str,
    owner_id,
):
    return {
        "name": name,
        "business_type": business_type,
        "owner_id": owner_id,
        "created_at": datetime.now(timezone.utc),
    }