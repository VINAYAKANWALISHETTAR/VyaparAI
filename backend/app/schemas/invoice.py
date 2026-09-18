from datetime import date
from pydantic import BaseModel, Field


class InvoiceCreate(BaseModel):
    business_id: str
    customer_name: str = Field(min_length=1, max_length=200)
    invoice_number: str | None = None
    amount: float = Field(gt=0)
    due_date: date
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

    due_date: date | None = None

    description: str | None = None


class InvoiceStatusUpdate(BaseModel):
    status: str
