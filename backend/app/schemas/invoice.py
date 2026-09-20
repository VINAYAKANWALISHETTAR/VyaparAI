import datetime as dt
from pydantic import BaseModel, Field, field_validator


class InvoiceCreate(BaseModel):
    business_id: str
    customer_name: str = Field(min_length=1, max_length=200)
    invoice_number: str | None = None
    amount: float = Field(gt=0)
    due_date: dt.date = Field(default_factory=dt.date.today)
    description: str | None = None


class InvoiceUpdate(BaseModel):
    customer_name: str | None = Field(
        default=None,
        min_length=1,
        max_length=200
    )

    invoice_number: str | None = None

    amount: float | None = Field(
        default=None,
        gt=0
    )

    paid_amount: float | None = Field(
        default=None,
        ge=0
    )

    due_date: dt.date | None = None

    description: str | None = None

    status: str | None = None


class InvoiceStatusUpdate(BaseModel):
    status: str

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str) -> str:
        allowed = {"draft", "issued", "unpaid", "partially_paid", "paid", "overdue", "cancelled"}
        value_lower = value.strip().lower()
        if value_lower not in allowed:
            raise ValueError(f"status must be one of: {', '.join(sorted(allowed))}")
        return value_lower
