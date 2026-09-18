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


class PaymentExtraction(BaseModel):
    amount: float | None = None
    sender_name: str | None = None
    receiver_name: str | None = None
    transaction_reference: str | None = None
    transaction_date: date | None = None
    payment_status: str | None = None
    payment_method: str | None = None
    bank_or_upi_name: str | None = None
    direction: str | None = None
    raw_text: str | None = None


class PaymentResponse(BaseModel):
    status: str
    payment: PaymentExtraction | None = None
    matched_invoice: dict | None = None
    after_payment: dict | None = None
    message: str | None = None


class PaymentConfirmRequest(BaseModel):
    business_id: str
    invoice_id: str | None = None
    amount: float = Field(gt=0)
    transaction_reference: str | None = None
    transaction_date: date | None = None
    description: str | None = None
    source: str = "upi"
    direction: str = "received"
