from datetime import date
from pydantic import BaseModel, Field


ALLOWED_INVOICE_SOURCES = {"manual", "upi", "bank", "invoice", "voice", "ocr", "agent"}


class OCRExtraction(BaseModel):
    invoice_number: str | None = None
    customer_name: str | None = None
    business_name: str | None = None
    invoice_date: date | None = None
    due_date: date | None = None
    subtotal: float | None = None
    tax: float | None = None
    total_amount: float | None = None
    currency: str | None = None
    items: list[dict] | None = None
    raw_text: str | None = None


class OCRResponse(BaseModel):
    status: str
    extracted: OCRExtraction | None = None
    raw_text: str | None = None
    message: str | None = None


class OCRConfirmRequest(BaseModel):
    business_id: str
    customer_name: str = Field(min_length=1, max_length=200)
    invoice_number: str | None = None
    amount: float = Field(gt=0)
    due_date: date
    description: str | None = None
    source: str = "ocr"
    reference_id: str | None = None
