from app.database.mongodb import db


def create_indexes():
    db.users.create_index(
        "email",
        unique=True
    )

    db.businesses.create_index(
        "owner_id"
    )

    db.invoices.create_index(
        "business_id"
    )

    db.invoices.create_index(
        [
            ("business_id", 1),
            ("status", 1)
        ]
    )

    db.invoices.create_index(
        [
            ("business_id", 1),
            ("due_date", 1)
        ]
    )

    db.invoices.create_index(
        [
            ("business_id", 1),
            ("invoice_number", 1),
            ("customer_name", 1),
            ("amount", 1)
        ]
    )

    db.transactions.create_index(
        "business_id"
    )

    db.transactions.create_index(
        [
            ("business_id", 1),
            ("type", 1)
        ]
    )

    db.transactions.create_index(
        [
            ("business_id", 1),
            ("date", 1)
        ]
    )

    db.transactions.create_index(
        [
            ("business_id", 1),
            ("category", 1)
        ]
    )

    db.transactions.create_index(
        "reference_id"
    )
