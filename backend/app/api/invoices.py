from datetime import date, datetime, timezone

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.security import get_current_user
from app.database.mongodb import db
from app.models.invoice import invoice_document
from app.schemas.invoice import (
    InvoiceCreate,
    InvoiceUpdate,
    InvoiceStatusUpdate,
)


router = APIRouter(
    prefix="/invoices",
    tags=["Invoices"],
)


def validate_object_id(value: str, field_name: str):
    try:
        return ObjectId(value)
    except Exception:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid {field_name}",
        )


def verify_business_ownership(
    business_id: str,
    current_user,
):
    business_object_id = validate_object_id(
        business_id,
        "business_id",
    )

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


def calculate_status(invoice):
    if invoice["status"] == "paid":
        return "paid"

    due_date = invoice.get("due_date")

    if due_date:
        if hasattr(due_date, "date"):
            due_date = due_date.date()

        if due_date < date.today():
            return "overdue"

    return "unpaid"


def serialize_invoice(invoice):
    return {
        "id": str(invoice["_id"]),
        "business_id": invoice["business_id"],
        "customer_name": invoice["customer_name"],
        "invoice_number": invoice.get("invoice_number"),
        "amount": float(invoice["amount"]),
        "due_date": invoice["due_date"].isoformat()
        if invoice.get("due_date")
        else None,
        "description": invoice.get("description"),
        "status": calculate_status(invoice),
        "created_at": invoice["created_at"].isoformat()
        if invoice.get("created_at")
        else None,
        "updated_at": invoice["updated_at"].isoformat()
        if invoice.get("updated_at")
        else None,
    }


@router.post("/", status_code=status.HTTP_201_CREATED)
def create_invoice(
    invoice: InvoiceCreate,
    current_user=Depends(get_current_user),
):
    verify_business_ownership(
        invoice.business_id,
        current_user,
    )

    new_invoice = invoice_document(
        business_id=invoice.business_id,
        customer_name=invoice.customer_name,
        invoice_number=invoice.invoice_number,
        amount=invoice.amount,
        due_date=invoice.due_date,
        description=invoice.description,
    )

    result = db.invoices.insert_one(new_invoice)

    created_invoice = db.invoices.find_one({
        "_id": result.inserted_id
    })

    return serialize_invoice(created_invoice)


@router.get("/")
def get_invoices(
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])

    businesses = db.businesses.find({
        "owner_id": user_id
    })

    business_ids = [
        str(business["_id"])
        for business in businesses
    ]

    invoices = db.invoices.find({
        "business_id": {
            "$in": business_ids
        }
    })

    return [
        serialize_invoice(invoice)
        for invoice in invoices
    ]


@router.get("/{invoice_id}")
def get_invoice(
    invoice_id: str,
    current_user=Depends(get_current_user),
):
    invoice_object_id = validate_object_id(
        invoice_id,
        "invoice_id",
    )

    invoice = db.invoices.find_one({
        "_id": invoice_object_id
    })

    if not invoice:
        raise HTTPException(
            status_code=404,
            detail="Invoice not found",
        )

    verify_business_ownership(
        invoice["business_id"],
        current_user,
    )

    return serialize_invoice(invoice)


@router.put("/{invoice_id}")
def update_invoice(
    invoice_id: str,
    invoice_data: InvoiceUpdate,
    current_user=Depends(get_current_user),
):
    invoice_object_id = validate_object_id(
        invoice_id,
        "invoice_id",
    )

    invoice = db.invoices.find_one({
        "_id": invoice_object_id
    })

    if not invoice:
        raise HTTPException(
            status_code=404,
            detail="Invoice not found",
        )

    verify_business_ownership(
        invoice["business_id"],
        current_user,
    )

    update_data = {
        key: value
        for key, value in invoice_data.model_dump().items()
        if value is not None
    }

    if not update_data:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update",
        )

    update_data["updated_at"] = datetime.now(timezone.utc)

    db.invoices.update_one(
        {"_id": invoice_object_id},
        {"$set": update_data},
    )

    updated_invoice = db.invoices.find_one({
        "_id": invoice_object_id
    })

    return serialize_invoice(updated_invoice)


@router.delete("/{invoice_id}")
def delete_invoice(
    invoice_id: str,
    current_user=Depends(get_current_user),
):
    invoice_object_id = validate_object_id(
        invoice_id,
        "invoice_id",
    )

    invoice = db.invoices.find_one({
        "_id": invoice_object_id
    })

    if not invoice:
        raise HTTPException(
            status_code=404,
            detail="Invoice not found",
        )

    verify_business_ownership(
        invoice["business_id"],
        current_user,
    )

    db.invoices.delete_one({
        "_id": invoice_object_id
    })

    return {
        "message": "Invoice deleted successfully"
    }


@router.patch("/{invoice_id}/status")
def update_invoice_status(
    invoice_id: str,
    status_data: InvoiceStatusUpdate,
    current_user=Depends(get_current_user),
):
    if status_data.status not in ["paid", "unpaid"]:
        raise HTTPException(
            status_code=400,
            detail="Status must be 'paid' or 'unpaid'",
        )

    invoice_object_id = validate_object_id(
        invoice_id,
        "invoice_id",
    )

    invoice = db.invoices.find_one({
        "_id": invoice_object_id
    })

    if not invoice:
        raise HTTPException(
            status_code=404,
            detail="Invoice not found",
        )

    verify_business_ownership(
        invoice["business_id"],
        current_user,
    )

    db.invoices.update_one(
        {"_id": invoice_object_id},
        {
            "$set": {
                "status": status_data.status,
                "updated_at": datetime.now(timezone.utc),
            }
        },
    )

    updated_invoice = db.invoices.find_one({
        "_id": invoice_object_id
    })

    return serialize_invoice(updated_invoice)
