import os
from datetime import date, datetime, timezone
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.background import BackgroundTasks

from app.core.security import get_current_user
from app.database.mongodb import db
from app.models.invoice import invoice_document
from app.schemas.invoice import InvoiceCreate
from app.schemas.ocr import OCRConfirmRequest, OCRResponse, OCRExtraction
from app.services.invoice_extractor import invoice_extractor
from app.services.ocr_service import ocr_service

router = APIRouter(
    prefix="/ocr",
    tags=["OCR"],
)


def validate_object_id(value: str, field_name: str):
    try:
        return ObjectId(value)
    except Exception:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid {field_name}",
        )


def verify_business_ownership(business_id: str, current_user):
    business_object_id = validate_object_id(business_id, "business_id")

    business = db.businesses.find_one({
        "_id": business_object_id,
        "owner_id": str(current_user["_id"]),
    })

    if not business:
        raise HTTPException(
            status_code=404,
            detail="Business not found or access denied",
        )

    return business


def detect_duplicate_invoice(business_id: str, extracted: OCRExtraction) -> bool:
    if not extracted.invoice_number or not extracted.customer_name or not extracted.total_amount:
        return False

    existing = db.invoices.find_one({
        "business_id": business_id,
        "invoice_number": extracted.invoice_number,
        "customer_name": extracted.customer_name,
        "amount": extracted.total_amount,
    })

    return existing is not None


def serialize_ocr_extraction(extracted: OCRExtraction) -> dict:
    return {
        "invoice_number": extracted.invoice_number,
        "customer_name": extracted.customer_name,
        "business_name": extracted.business_name,
        "invoice_date": extracted.invoice_date.isoformat() if extracted.invoice_date else None,
        "due_date": extracted.due_date.isoformat() if extracted.due_date else None,
        "subtotal": extracted.subtotal,
        "tax": extracted.tax,
        "total_amount": extracted.total_amount,
        "currency": extracted.currency,
        "items": extracted.items,
        "raw_text": extracted.raw_text,
    }


@router.post("/invoice", response_model=OCRResponse)
async def extract_invoice(
    business_id: str = Form(...),
    file: UploadFile = File(...),
    current_user=Depends(get_current_user),
):
    verify_business_ownership(business_id, current_user)

    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="File must be an image",
        )

    content = await file.read()

    try:
        ocr_service.validate_file(file.filename or "upload", content, file.content_type or "application/octet-stream")
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    try:
        raw_text = ocr_service.extract_text(content)
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    extracted = invoice_extractor.extract(raw_text)

    is_duplicate = detect_duplicate_invoice(business_id, extracted)

    response_status = "needs_confirmation"
    message = None

    if is_duplicate:
        response_status = "possible_duplicate"
        message = "A similar invoice already exists for this business."

    if not extracted.customer_name or not extracted.total_amount:
        response_status = "needs_confirmation"
        message = "Some fields could not be extracted confidently. Please review."

    return OCRResponse(
        status=response_status,
        extracted=extracted,
        raw_text=raw_text,
        message=message,
    )


@router.post("/invoice/confirm", status_code=status.HTTP_201_CREATED)
def confirm_invoice(
    payload: OCRConfirmRequest,
    current_user=Depends(get_current_user),
):
    verify_business_ownership(payload.business_id, current_user)

    invoice_create = InvoiceCreate(
        business_id=payload.business_id,
        customer_name=payload.customer_name,
        invoice_number=payload.invoice_number,
        amount=payload.amount,
        due_date=payload.due_date,
        description=payload.description,
    )

    new_invoice = invoice_document(
        business_id=invoice_create.business_id,
        customer_name=invoice_create.customer_name,
        invoice_number=invoice_create.invoice_number,
        amount=invoice_create.amount,
        due_date=invoice_create.due_date,
        description=invoice_create.description,
    )

    result = db.invoices.insert_one(new_invoice)

    created_invoice = db.invoices.find_one({
        "_id": result.inserted_id
    })

    from app.api.invoices import serialize_invoice
    return serialize_invoice(created_invoice)
