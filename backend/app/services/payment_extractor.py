import logging
import re
from datetime import date, datetime
from typing import Optional, Tuple, List

from app.schemas.ocr import PaymentExtraction

logger = logging.getLogger(__name__)


class PaymentExtractor:
    AMOUNT_PATTERNS = [
        r"(?i)(?:paid|transferred|sent|received|amount|total)[\s\.:\-]*[₹\s]*(?:rs\.?|inr)?[\s:]*([0-9,]+\.?\d*)",
        r"(?i)[₹\s]*(?:rs\.?|inr)[\s:]*([0-9,]+\.?\d*)",
    ]

    REFERENCE_PATTERNS = [
        r"(?i)(?:upi\s*ref(?:\s*no)?|ref(?:\s*no)?|rrn|utr)[\s\.:\-]*([0-9]{10,16})",
        r"(?i)(?:transaction\s*id|txn\s*id|reference\s*id)[\s\.:\-]*([A-Za-z0-9]{8,35})",
        r"(?i)(?:google\s*transaction\s*id)[\s\.:\-]*([A-Za-z0-9\-]+)",
    ]

    DATE_PATTERNS = [
        r"(?i)(?:date|paid\s+on|completed\s+on|transferred\s+on)[\s\.:\-]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})",
        r"(?i)(?:date|paid\s+on|completed\s+on)[\s\.:\-]*(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})",
        r"\b(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})\b",
        r"\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b",
    ]

    STATUS_PATTERNS = [
        r"(?i)\b(paid\s+successfully|payment\s+successful|successful|completed|success)\b",
        r"(?i)\b(payment\s+failed|failed|declined)\b",
        r"(?i)\b(pending|processing)\b",
    ]

    SENDER_PATTERNS = [
        r"(?i)(?:from|debited\s+from|sender|paid\s+by)[\s\.:\-]+([A-Za-z0-9\s\.\,\&\-]{2,40})(?:\n|$)",
    ]

    RECEIVER_PATTERNS = [
        r"(?i)(?:paid\s+to|transferred\s+to|to|receiver|beneficiary)[\s\.:\-]+([A-Za-z0-9\s\.\,\&\-]{2,40})(?:\n|$)",
    ]

    BANK_OR_UPI_PATTERNS = [
        r"(?i)(?:upi\s*id|vpa)[\s\.:\-]*([a-zA-Z0-9\.\-_]+@[a-zA-Z0-9]+)",
        r"(?i)(?:bank|app)[\s\.:\-]*([A-Za-z\s]+?)(?:bank|ltd|account|a\/c|\n|$)",
    ]

    def classify_payment_document(self, text: str) -> str:
        if not text or len(text.strip()) < 10:
            return "unreadable"

        lower = text.lower()
        signals = [
            "paid to", "transferred to", "upi ref", "utr", "google pay", "phonepe",
            "paytm", "bhim", "gpay", "payment successful", "debited from",
            "credited to", "transaction id", "successful",
        ]
        matches = sum(1 for sig in signals if sig in lower)
        if matches >= 1 or re.search(r"(?i)upi\s*ref", text) or re.search(r"(?i)transaction\s*id", text):
            return "payment_screenshot"
        return "unsupported"

    def extract(self, raw_text: str) -> PaymentExtraction:
        if not raw_text or not raw_text.strip():
            return PaymentExtraction(
                document_type="unreadable",
                raw_text="",
                confidence_score=0.0,
                validation_warnings=["No readable text found in image."],
            )

        doc_type = self.classify_payment_document(raw_text)
        if doc_type != "payment_screenshot":
            return PaymentExtraction(
                document_type="unsupported",
                raw_text=raw_text,
                confidence_score=0.0,
                validation_warnings=["Document does not appear to be a payment screenshot."],
            )

        warnings: List[str] = []
        amount = self._extract_amount(raw_text)
        if not amount:
            warnings.append("Payment amount could not be extracted.")

        transaction_reference = self._extract_reference(raw_text)
        if not transaction_reference:
            warnings.append("Transaction reference / UTR not found.")

        transaction_date = self._extract_date(raw_text)
        payment_status = self._extract_status(raw_text)
        sender_name = self._extract_party(raw_text, self.SENDER_PATTERNS)
        receiver_name = self._extract_party(raw_text, self.RECEIVER_PATTERNS)
        bank_name = self._extract_bank_or_upi(raw_text)
        direction = self._detect_direction(raw_text, sender_name, receiver_name)

        confidence = self._calculate_confidence(
            amount=amount,
            reference=transaction_reference,
            status=payment_status,
            party=receiver_name or sender_name,
        )

        return PaymentExtraction(
            document_type="payment_screenshot",
            amount=amount,
            sender_name=sender_name,
            receiver_name=receiver_name,
            transaction_reference=transaction_reference,
            transaction_date=transaction_date,
            payment_status=payment_status,
            payment_method="upi",
            bank_or_upi_name=bank_name,
            direction=direction,
            confidence_score=confidence,
            validation_warnings=warnings,
            raw_text=raw_text,
        )

    def _extract_amount(self, text: str) -> Optional[float]:
        # Contextual search: look for lines mentioning amount or ₹
        for pattern in self.AMOUNT_PATTERNS:
            match = re.search(pattern, text)
            if match:
                amt_str = match.group(1).replace(",", "").strip()
                try:
                    val = float(amt_str)
                    if 0 < val < 10000000:
                        return val
                except ValueError:
                    continue

        # Look for standalone rupee amount near top
        standalone_match = re.search(r"₹\s*([0-9,]+(?:\.\d{2})?)", text)
        if standalone_match:
            try:
                return float(standalone_match.group(1).replace(",", ""))
            except ValueError:
                pass

        return None

    def _extract_reference(self, text: str) -> Optional[str]:
        for pattern in self.REFERENCE_PATTERNS:
            match = re.search(pattern, text)
            if match:
                ref = match.group(1).strip()
                if len(ref) >= 8:
                    return ref
        return None

    def _extract_date(self, text: str) -> Optional[date]:
        for pattern in self.DATE_PATTERNS:
            match = re.search(pattern, text)
            if match:
                date_str = match.group(1).strip().replace(".", "/").replace("-", "/")
                for fmt in ["%d/%m/%Y", "%d/%m/%y", "%d %b %Y", "%d %B %Y"]:
                    try:
                        dt = datetime.strptime(date_str, fmt).date()
                        if 2020 <= dt.year <= 2030:
                            return dt
                    except ValueError:
                        continue
        return None

    def _extract_status(self, text: str) -> str:
        for pattern in self.STATUS_PATTERNS:
            match = re.search(pattern, text)
            if match:
                m = match.group(1).lower()
                if any(w in m for w in ["success", "successful", "completed", "paid"]):
                    return "success"
                if any(w in m for w in ["fail", "declined"]):
                    return "failed"
                if any(w in m for w in ["pending", "processing"]):
                    return "pending"
        return "success"  # If screenshot exists with paid details, default is success

    def _extract_party(self, text: str, patterns: List[str]) -> Optional[str]:
        for pattern in patterns:
            match = re.search(pattern, text, re.MULTILINE)
            if match:
                name = match.group(1).strip()
                # Clean up punctuation and numbers
                name = re.sub(r"[^A-Za-z0-9\s\.\&\-]", "", name).strip(" .,-")
                if len(name) >= 2 and not any(w in name.lower() for w in ["bank", "account", "upi", "ref", "rs"]):
                    return name
        return None

    def _extract_bank_or_upi(self, text: str) -> Optional[str]:
        for pattern in self.BANK_OR_UPI_PATTERNS:
            match = re.search(pattern, text)
            if match:
                val = match.group(1).strip()
                if len(val) >= 3:
                    return val
        return None

    def _detect_direction(self, text: str, sender: Optional[str], receiver: Optional[str]) -> str:
        text_lower = text.lower()
        if any(w in text_lower for w in ["paid to", "transferred to", "sent to", "debited from"]):
            return "sent"
        if any(w in text_lower for w in ["received from", "paid by", "credited from", "received"]):
            return "received"
        return "received"

    def _calculate_confidence(
        self,
        amount: Optional[float],
        reference: Optional[str],
        status: Optional[str],
        party: Optional[str],
    ) -> float:
        score = 0.20  # Base screenshot match
        if amount and amount > 0:
            score += 0.35
        if reference:
            score += 0.25
        if party:
            score += 0.10
        if status == "success":
            score += 0.10
        return min(round(score, 2), 1.0)


payment_extractor = PaymentExtractor()
