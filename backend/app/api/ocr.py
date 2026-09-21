import os
from datetime import date, datetime, timezone
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.background import BackgroundTasks

from app.core.security import get_current_user
from app.database.mongodb import db
from app.models.invoice import invoice_document
from app.models.transaction import transaction_document
from app.schemas.invoice import InvoiceCreate
from app.schemas.ocr import (
    OCRConfirmRequest,
    OCRResponse,
    OCRExtraction,
    PaymentConfirmRequest,
    PaymentExtraction,
    PaymentResponse,
)
from app.services.invoice_extractor import invoice_extractor
from app.services.invoice_matching import invoice_matching_service
from app.services.ocr_service import ocr_service
from app.services.payment_extractor import payment_extractor
from app.services.payment_processing import payment_processing_service

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
    user_id = str(current_user["_id"])
    business_id = payload.business_id
    if not business_id:
        businesses = list(db.businesses.find({"owner_id": user_id}))
        if not businesses:
            from app.models.business import business_document
            default_biz = business_document(
                name="Vyapar Business",
                business_type="Retail",
                owner_id=user_id,
            )
            res = db.businesses.insert_one(default_biz)
            business_id = str(res.inserted_id)
        else:
            business_id = str(businesses[0]["_id"])
    else:
        verify_business_ownership(business_id, current_user)

    effective_due_date = payload.due_date or datetime.now(timezone.utc).date()

    invoice_create = InvoiceCreate(
        business_id=business_id,
        customer_name=payload.customer_name,
        invoice_number=payload.invoice_number,
        amount=payload.amount,
        due_date=effective_due_date,
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

    # Sync with transactions collection so dashboard & transaction history update immediately
    tx_doc = transaction_document(
        business_id=business_id,
        type="income",
        amount=payload.amount,
        category="Sales / Invoice",
        description=f"Invoice #{payload.invoice_number} - {payload.customer_name}" if payload.invoice_number else (payload.description or f"Sale to {payload.customer_name}"),
        date=datetime.now(timezone.utc).date(),
        source="ocr_invoice",
        reference_id=payload.invoice_number,
        user_id=str(current_user["_id"]),
    )
    db.transactions.insert_one(tx_doc)

    # Upsert customer in parties collection
    if payload.customer_name:
        db.parties.update_one(
            {"business_id": payload.business_id, "name": payload.customer_name, "type": "customer"},
            {
                "$setOnInsert": {
                    "business_id": payload.business_id,
                    "name": payload.customer_name,
                    "type": "customer",
                    "created_at": datetime.now(timezone.utc),
                },
                "$inc": {"total_sales": payload.amount, "balance": payload.amount},
            },
            upsert=True,
        )

    created_invoice = db.invoices.find_one({
        "_id": result.inserted_id
    })

    from app.api.invoices import serialize_invoice
    return serialize_invoice(created_invoice)


@router.post("/payment", response_model=PaymentResponse)
async def extract_payment(
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

    extracted = payment_extractor.extract(raw_text)

    if not extracted.amount or extracted.amount <= 0:
        return PaymentResponse(
            status="needs_confirmation",
            payment=extracted,
            message="Could not extract payment amount. Please review.",
        )

    if extracted.payment_status in {"failed", "pending"}:
        return PaymentResponse(
            status="needs_confirmation",
            payment=extracted,
            message=f"Payment status is {extracted.payment_status}. Please review before recording.",
        )

    is_duplicate = payment_processing_service.check_duplicate_payment(
        business_id, extracted.transaction_reference, extracted.amount, extracted.sender_name or extracted.receiver_name
    )

    if is_duplicate:
        return PaymentResponse(
            status="duplicate_payment",
            payment=extracted,
            message="A payment with this transaction reference already exists.",
        )

    match_result = invoice_matching_service.find_match(business_id, extracted)

    if match_result.status == "multiple_matches":
        return PaymentResponse(
            status="multiple_matches",
            payment=extracted,
            candidates=match_result.candidates,
            message="Multiple invoices match this payment. Please select one.",
        )

    if match_result.status == "overpayment_review":
        return PaymentResponse(
            status="overpayment_review",
            payment=extracted,
            matched_invoice=match_result.invoice,
            after_payment=match_result.after_payment,
            message="Payment exceeds invoice amount. Please review.",
        )

    if match_result.status == "no_match":
        return PaymentResponse(
            status="no_match",
            payment=extracted,
            message="No matching invoice found. You can record this as standalone income.",
        )

    return PaymentResponse(
        status="needs_confirmation",
        payment=extracted,
        matched_invoice=match_result.invoice,
        after_payment=match_result.after_payment,
        message="Payment extracted. Please confirm to record.",
    )


@router.post("/payment/confirm", status_code=status.HTTP_201_CREATED)
def confirm_payment(
    payload: PaymentConfirmRequest,
    current_user=Depends(get_current_user),
):
    verify_business_ownership(payload.business_id, current_user)

    invoice_object_id = validate_object_id(payload.invoice_id, "invoice_id") if payload.invoice_id else None

    if invoice_object_id:
        invoice = db.invoices.find_one({"_id": invoice_object_id})
        if not invoice:
            raise HTTPException(status_code=404, detail="Invoice not found")

        if invoice.get("business_id") != payload.business_id:
            raise HTTPException(status_code=404, detail="Invoice not found or access denied")

    if invoice_object_id:
        result = payment_processing_service.record_payment(
            business_id=payload.business_id,
            invoice_id=str(invoice_object_id),
            amount=payload.amount,
            description=payload.description,
            source=payload.source,
            direction=payload.direction,
            transaction_reference=payload.transaction_reference,
            user_id=str(current_user["_id"]),
        )
    else:
        new_transaction = transaction_document(
            business_id=payload.business_id,
            type="income" if payload.direction == "received" else "expense",
            amount=payload.amount,
            category="customer_payment" if payload.direction == "received" else "supplier_payment",
            description=payload.description or "Standalone payment",
            date=payload.transaction_date or datetime.now(timezone.utc).date(),
            source=payload.source,
            reference_id=payload.transaction_reference,
            user_id=str(current_user["_id"]),
        )

        transaction_result = db.transactions.insert_one(new_transaction)
        result = {
            "transaction_id": str(transaction_result.inserted_id),
            "invoice_id": None,
            "payment_amount": payload.amount,
            "remaining_outstanding": None,
            "invoice_status": None,
        }

    return {
        "status": "recorded",
        **result,
    }
