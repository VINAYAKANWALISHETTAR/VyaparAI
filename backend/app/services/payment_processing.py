from datetime import datetime, timezone
from decimal import Decimal

from bson import ObjectId
from app.database.mongodb import db
from app.models.transaction import transaction_document


class PaymentProcessingService:
    def record_payment(self, business_id: str, invoice_id: str, amount: float, description: str | None = None, source: str = "upi", direction: str = "received", transaction_reference: str | None = None, user_id: str | None = None):
        try:
            invoice_object_id = ObjectId(invoice_id)
        except Exception:
            raise ValueError("Invalid invoice ID")

        invoice = db.invoices.find_one({"_id": invoice_object_id})
        if not invoice:
            raise ValueError("Invoice not found")

        if invoice.get("business_id") != business_id:
            raise ValueError("Invoice does not belong to this business")

        current_paid = float(invoice.get("paid_amount", 0))
        total_amount = float(invoice["amount"])
        new_paid = current_paid + amount
        outstanding = max(0, total_amount - new_paid)

        if outstanding < 0:
            raise ValueError(f"Payment exceeds outstanding amount. Outstanding: {total_amount - current_paid}")

        if outstanding == 0:
            new_status = "paid"
        else:
            new_status = "partially_paid"

        transaction_type = "income" if direction == "received" else "expense"
        category = "customer_payment" if direction == "received" else "supplier_payment"

        new_transaction = transaction_document(
            business_id=business_id,
            type=transaction_type,
            amount=amount,
            category=category,
            description=description or f"Payment for invoice {invoice.get('invoice_number', invoice_id)}",
            date=datetime.now(timezone.utc).date(),
            source=source,
            reference_id=transaction_reference,
            user_id=user_id,
        )

        transaction_result = db.transactions.insert_one(new_transaction)

        db.invoices.update_one(
            {"_id": invoice_object_id},
            {
                "$set": {
                    "paid_amount": new_paid,
                    "outstanding_amount": outstanding,
                    "status": new_status,
                    "updated_at": datetime.now(timezone.utc),
                }
            },
        )

        return {
            "transaction_id": str(transaction_result.inserted_id),
            "invoice_id": str(invoice_id),
            "payment_amount": amount,
            "remaining_outstanding": outstanding,
            "invoice_status": new_status,
        }

    def check_duplicate_payment(self, business_id: str, transaction_reference: str | None, amount: float | None, party_name: str | None) -> bool:
        if not transaction_reference:
            return False

        existing = db.transactions.find_one({
            "business_id": business_id,
            "reference_id": transaction_reference,
        })

        return existing is not None


payment_processing_service = PaymentProcessingService()
