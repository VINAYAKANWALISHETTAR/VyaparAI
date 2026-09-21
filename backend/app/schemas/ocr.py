from datetime import date
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


ALLOWED_INVOICE_SOURCES = {"manual", "upi", "bank", "invoice", "voice", "ocr", "agent"}


class LineItem(BaseModel):
    description: str
    quantity: Optional[float] = None
    unit_price: Optional[float] = None
    amount: Optional[float] = None


class OCRExtraction(BaseModel):
    document_type: Optional[str] = "unsupported"  # invoice, receipt, payment_screenshot, unsupported, unreadable
    invoice_number: Optional[str] = None
    customer_name: Optional[str] = None  # Buyer
    business_name: Optional[str] = None  # Seller
    seller_name: Optional[str] = None
    buyer_name: Optional[str] = None
    seller_gstin: Optional[str] = None
    buyer_gstin: Optional[str] = None
    invoice_date: Optional[date] = None
    due_date: Optional[date] = None
    subtotal: Optional[float] = None
    tax: Optional[float] = None
    cgst: Optional[float] = None
    sgst: Optional[float] = None
    igst: Optional[float] = None
    total_amount: Optional[float] = None
    currency: Optional[str] = None
    items: Optional[List[Dict[str, Any]]] = None
    confidence_score: Optional[float] = 0.0
    validation_warnings: List[str] = []
    raw_text: Optional[str] = None


class OCRResponse(BaseModel):
    status: str  # extracted, needs_review, unsupported, unreadable, engine_unavailable, possible_duplicate
    extracted: Optional[OCRExtraction] = None
    raw_text: Optional[str] = None
    message: Optional[str] = None


class OCRConfirmRequest(BaseModel):
    business_id: Optional[str] = None
    customer_name: str = Field(min_length=1, max_length=200)
    invoice_number: Optional[str] = None
    amount: float = Field(gt=0)
    due_date: Optional[date] = None
    description: Optional[str] = None
    source: str = "ocr"
    reference_id: Optional[str] = None


class PaymentExtraction(BaseModel):
    document_type: Optional[str] = "payment_screenshot"  # payment_screenshot, unsupported, unreadable
    amount: Optional[float] = None
    sender_name: Optional[str] = None
    receiver_name: Optional[str] = None
    transaction_reference: Optional[str] = None  # UPI UTR or ref ID
    transaction_date: Optional[date] = None
    payment_status: Optional[str] = None  # success, completed, failed, pending, unknown
    payment_method: Optional[str] = None  # upi, bank, card, cash, wallet
    bank_or_upi_name: Optional[str] = None
    direction: Optional[str] = None  # received, sent, unknown
    confidence_score: Optional[float] = 0.0
    validation_warnings: List[str] = []
    raw_text: Optional[str] = None


class PaymentResponse(BaseModel):
    status: str  # extracted, needs_confirmation, duplicate_payment, multiple_matches, overpayment_review, no_match, unsupported, unreadable, engine_unavailable
    payment: Optional[PaymentExtraction] = None
    matched_invoice: Optional[dict] = None
    candidates: Optional[list] = None
    after_payment: Optional[dict] = None
    message: Optional[str] = None


class PaymentConfirmRequest(BaseModel):
    business_id: str
    invoice_id: Optional[str] = None
    amount: float = Field(gt=0)
    transaction_reference: Optional[str] = None
    transaction_date: Optional[date] = None
    description: Optional[str] = None
    source: str = "upi"
    direction: str = "received"
