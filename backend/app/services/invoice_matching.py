from typing import Any

from app.database.mongodb import db
from app.schemas.ocr import PaymentExtraction


class InvoiceMatchResult:
    def __init__(self, status: str, invoice: Any | None = None, candidates: list | None = None, after_payment: dict | None = None):
        self.status = status
        self.invoice = invoice
        self.candidates = candidates or []
        self.after_payment = after_payment or {}


class InvoiceMatchingService:
    def find_match(self, business_id: str, payment: PaymentExtraction) -> InvoiceMatchResult:
        if not payment.amount or payment.amount <= 0:
            return InvoiceMatchResult(status="no_match")

        query = {"business_id": business_id}
        candidates = list(db.invoices.find(query))

        if not candidates:
            return InvoiceMatchResult(status="no_match")

        exact_matches = []
        partial_matches = []

        for invoice in candidates:
            score = self._score_invoice(invoice, payment)
            if score >= 80:
                exact_matches.append((score, invoice))
            elif score >= 40:
                partial_matches.append((score, invoice))

        exact_matches.sort(key=lambda x: x[0], reverse=True)
        partial_matches.sort(key=lambda x: x[0], reverse=True)

        if len(exact_matches) > 1:
            candidates = [self._serialize_invoice(invoice) for _, invoice in exact_matches]
            return InvoiceMatchResult(status="multiple_matches", candidates=candidates)

        if exact_matches:
            invoice = exact_matches[0][1]
            return self._build_match_result(invoice, payment)

        if len(partial_matches) == 1:
            invoice = partial_matches[0][1]
            return self._build_match_result(invoice, payment)

        candidates = [self._serialize_invoice(invoice) for _, invoice in partial_matches[:5]]
        return InvoiceMatchResult(status="no_match", candidates=candidates)

    def _score_invoice(self, invoice: dict, payment: PaymentExtraction) -> int:
        score = 0

        customer_name = invoice.get("customer_name", "")
        if payment.receiver_name and payment.receiver_name.lower() in customer_name.lower():
            score += 40
        if payment.sender_name and payment.sender_name.lower() in customer_name.lower():
            score += 40

        invoice_amount = float(invoice.get("amount", 0))
        if payment.amount and invoice_amount > 0:
            if abs(payment.amount - invoice_amount) < 0.01:
                score += 40
            elif 0 < payment.amount < invoice_amount:
                score += 20

        return score

    def _build_match_result(self, invoice: dict, payment: PaymentExtraction) -> InvoiceMatchResult:
        total_amount = float(invoice.get("amount", 0))
        paid_amount = float(invoice.get("paid_amount", 0))
        outstanding = max(0, total_amount - paid_amount)
        payment_amount = float(payment.amount or 0)

        if payment_amount > outstanding:
            after_payment = {
                "total_amount": total_amount,
                "payment_amount": payment_amount,
                "paid_amount": paid_amount,
                "outstanding_amount": 0,
                "overpayment": payment_amount - outstanding,
            }
            return InvoiceMatchResult(
                status="overpayment_review",
                invoice=self._serialize_invoice(invoice),
                after_payment=after_payment,
            )

        new_paid = paid_amount + payment_amount
        new_outstanding = max(0, total_amount - new_paid)

        after_payment = {
            "total_amount": total_amount,
            "payment_amount": payment_amount,
            "paid_amount": new_paid,
            "outstanding_amount": new_outstanding,
        }

        if new_outstanding == 0:
            status = "match"
        else:
            status = "match"

        return InvoiceMatchResult(
            status=status,
            invoice=self._serialize_invoice(invoice),
            after_payment=after_payment,
        )

    def _serialize_invoice(self, invoice: dict) -> dict:
        return {
            "id": str(invoice["_id"]),
            "business_id": invoice["business_id"],
            "customer_name": invoice["customer_name"],
            "invoice_number": invoice.get("invoice_number"),
            "amount": float(invoice["amount"]),
            "paid_amount": float(invoice.get("paid_amount", 0)),
            "outstanding_amount": float(invoice.get("outstanding_amount", invoice["amount"])),
            "due_date": invoice["due_date"].isoformat() if invoice.get("due_date") else None,
            "status": invoice.get("status", "unpaid"),
        }


invoice_matching_service = InvoiceMatchingService()
