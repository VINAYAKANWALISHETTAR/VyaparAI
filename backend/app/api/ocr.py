import logging
import os
from datetime import date, datetime, timezone
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status

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

logger = logging.getLogger(__name__)

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
        "document_type": extracted.document_type,
        "invoice_number": extracted.invoice_number,
        "customer_name": extracted.customer_name,
        "business_name": extracted.business_name,
        "seller_name": extracted.seller_name,
        "buyer_name": extracted.buyer_name,
        "seller_gstin": extracted.seller_gstin,
        "buyer_gstin": extracted.buyer_gstin,
        "invoice_date": extracted.invoice_date.isoformat() if extracted.invoice_date else None,
        "due_date": extracted.due_date.isoformat() if extracted.due_date else None,
        "subtotal": extracted.subtotal,
        "tax": extracted.tax,
        "cgst": extracted.cgst,
        "sgst": extracted.sgst,
        "igst": extracted.igst,
        "total_amount": extracted.total_amount,
        "currency": extracted.currency,
        "items": extracted.items,
        "confidence_score": extracted.confidence_score,
        "validation_warnings": extracted.validation_warnings,
        "raw_text": extracted.raw_text,
    }


@router.post("/invoice", response_model=OCRResponse)
async def extract_invoice(
    business_id: str = Form(...),
    file: UploadFile = File(...),
    language: str | None = Form(None),
    current_user=Depends(get_current_user),
):
    verify_business_ownership(business_id, current_user)

    if not file.content_type or not (
        file.content_type.startswith("image/") or file.content_type == "application/octet-stream"
    ):
        raise HTTPException(
            status_code=400,
            detail="File must be a supported image format (JPG, PNG, WebP)",
        )

    content = await file.read()

    try:
        ocr_service.validate_file(file.filename or "upload", content, file.content_type or "image/jpeg")
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    try:
        raw_text, avg_conf = ocr_service.extract_text_with_details(content, language=language)
    except RuntimeError as exc:
        logger.warning(f"OCR engine unavailable: {exc}")
        return OCRResponse(
            status="engine_unavailable",
            extracted=None,
            raw_text="",
            message="OCR engine is unavailable on the server. Please enter details manually.",
        )
    except Exception as exc:
        logger.error(f"OCR processing failed: {exc}")
        return OCRResponse(
            status="failed",
            extracted=None,
            raw_text="",
            message="Failed to process image. Please try again with a clearer picture.",
        )

    extracted = invoice_extractor.extract(raw_text)

    # Document type handling
    if extracted.document_type == "unreadable":
        return OCRResponse(
            status="unreadable",
            extracted=extracted,
            raw_text=raw_text,
            message="Could not detect readable text in this image. Please ensure good lighting and clear focus.",
        )

    if extracted.document_type == "unsupported":
        return OCRResponse(
            status="unsupported",
            extracted=extracted,
            raw_text=raw_text,
            message="This image does not appear to contain an invoice or receipt.",
        )

    is_duplicate = detect_duplicate_invoice(business_id, extracted)

    response_status = "extracted"
    message = None

    if is_duplicate:
        response_status = "possible_duplicate"
        message = "A similar invoice already exists for this business."
    elif not extracted.customer_name or not extracted.total_amount:
        response_status = "needs_confirmation"
        message = "Some invoice details could not be extracted automatically. Please verify before saving."
    elif extracted.validation_warnings:
        response_status = "needs_confirmation"
        message = "; ".join(extracted.validation_warnings)
    else:
        message = "Invoice details successfully extracted."

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

    customer_clean = payload.customer_name.strip()
    if not customer_clean:
        raise HTTPException(
            status_code=422,
            detail="Customer or Vendor name is required to confirm invoice.",
        )

    if payload.amount <= 0:
        raise HTTPException(
            status_code=422,
            detail="Amount must be greater than zero.",
        )

    effective_due_date = payload.due_date or datetime.now(timezone.utc).date()

    # Duplicate check for invoice number
    if payload.invoice_number and payload.invoice_number.strip():
        existing_tx = db.transactions.find_one({
            "$or": [{"business_id": business_id}, {"user_id": user_id}],
            "reference_id": payload.invoice_number.strip(),
        })
        if existing_tx:
            from app.api.invoices import serialize_invoice
            existing_inv = db.invoices.find_one({
                "$or": [{"business_id": business_id}, {"customer_name": customer_clean}],
                "invoice_number": payload.invoice_number.strip(),
            })
            if existing_inv:
                return serialize_invoice(existing_inv)

    invoice_create = InvoiceCreate(
        business_id=business_id,
        customer_name=customer_clean,
        invoice_number=payload.invoice_number.strip() if payload.invoice_number else None,
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
        description=f"Invoice #{payload.invoice_number} - {customer_clean}" if payload.invoice_number else (payload.description or f"Sale to {customer_clean}"),
        date=datetime.now(timezone.utc).date(),
        source="ocr_invoice",
        reference_id=payload.invoice_number,
        user_id=str(current_user["_id"]),
    )
    db.transactions.insert_one(tx_doc)

    # Trigger notification for OCR invoice
    try:
        from app.services.notification_service import notification_service
        notification_service.create_notification(
            user_id=user_id,
            business_id=business_id,
            notification_type="ocr_processed",
            title=f"Invoice saved: ₹{payload.amount:,.0f}",
            message=f"Invoice for {customer_clean} successfully confirmed and added to ledger.",
            data={"invoice_number": payload.invoice_number, "amount": payload.amount},
        )
    except Exception:
        pass

    # Upsert customer in parties collection safely
    db.parties.update_one(
        {"business_id": business_id, "name": customer_clean, "type": "customer"},
        {
            "$setOnInsert": {
                "business_id": business_id,
                "name": customer_clean,
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

    if not file.content_type or not (
        file.content_type.startswith("image/") or file.content_type == "application/octet-stream"
    ):
        raise HTTPException(
            status_code=400,
            detail="File must be a supported image format",
        )

    content = await file.read()

    try:
        ocr_service.validate_file(file.filename or "upload", content, file.content_type or "image/jpeg")
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    try:
        raw_text, _ = ocr_service.extract_text_with_details(content)
    except RuntimeError as exc:
        logger.warning(f"OCR engine unavailable: {exc}")
        return PaymentResponse(
            status="engine_unavailable",
            payment=None,
            message="OCR engine is unavailable on the server.",
        )
    except Exception as exc:
        logger.error(f"OCR execution failed: {exc}")
        return PaymentResponse(
            status="failed",
            payment=None,
            message="Failed to process image.",
        )

    extracted = payment_extractor.extract(raw_text)

    if extracted.document_type == "unreadable":
        return PaymentResponse(
            status="unreadable",
            payment=extracted,
            message="Could not detect readable text in this image.",
        )

    if extracted.document_type == "unsupported":
        return PaymentResponse(
            status="unsupported",
            payment=extracted,
            message="This image does not appear to be a payment screenshot.",
        )

    if not extracted.amount or extracted.amount <= 0:
        return PaymentResponse(
            status="needs_confirmation",
            payment=extracted,
            message="Could not extract payment amount. Please review and enter amount manually.",
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
        status="extracted",
        payment=extracted,
        matched_invoice=match_result.invoice,
        after_payment=match_result.after_payment,
        message="Payment extracted successfully. Please confirm to record.",
    )


@router.post("/payment/confirm", status_code=status.HTTP_201_CREATED)
def confirm_payment(
    payload: PaymentConfirmRequest,
    current_user=Depends(get_current_user),
):
    verify_business_ownership(payload.business_id, current_user)

    if payload.amount <= 0:
        raise HTTPException(status_code=422, detail="Amount must be greater than zero.")

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
