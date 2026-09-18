import re
from datetime import date, datetime
from typing import Optional

from app.schemas.ocr import PaymentExtraction


class PaymentExtractor:
    AMOUNT_PATTERNS = [
        r"(?i)(?:₹|rs\.?|inr)\s*([0-9,]+\.?\d*)",
        r"(?i)(?:paid|payment|received)\s*(?:₹|rs\.?|inr)?\s*([0-9,]+\.?\d*)",
        r"(?i)(?:amount|total)\s*[:\-]?\s*(?:₹|rs\.?|inr)?\s*([0-9,]+\.?\d*)",
    ]

    REFERENCE_PATTERNS = [
        r"(?i)(?:transaction\s*id|txn\s*id|reference\s*id|upi\s*ref)\s*[:\-]?\s*([A-Za-z0-9]+)",
        r"(?i)(?:transaction\s*#|txn\s*#|ref\s*#)\s*[:\-]?\s*([A-Za-z0-9]+)",
    ]

    DATE_PATTERNS = [
        r"(?i)(?:date|paid\s+date|payment\s+date)\s*[:\-]?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})",
        r"(?i)(?:date|paid\s+date|payment\s+date)\s*[:\-]?\s*(\d{1,2}\s+[A-Za-z]+\s+\d{4})",
        r"\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b",
        r"\b(\d{1,2}\s+[A-Za-z]+\s+\d{4})\b",
    ]

    STATUS_PATTERNS = [
        r"(?i)(?:payment\s+status|status)\s*[:\-]?\s*(success|completed|failed|pending|unknown)",
        r"(?i)\b(success|completed|failed|pending)\b",
    ]

    METHOD_PATTERNS = [
        r"(?i)(?:payment\s+method|via|through)\s*[:\-]?\s*(upi|bank|card|cash|wallet)",
        r"(?i)\b(upi|bank transfer|card|cash|wallet)\b",
    ]

    SENDER_PATTERNS = [
        r"(?i)(?:from|paid by|sender)\s*[:\-]?\s*([A-Za-z][A-Za-z0-9\s\.]+?)(?:\n|$)",
        r"(?i)(?:from|paid by|sender)\s*[:\-]?\s*([A-Za-z][A-Za-z0-9\s\.]+)",
    ]

    RECEIVER_PATTERNS = [
        r"(?i)(?:to|paid to|receiver|beneficiary)\s*[:\-]?\s*([A-Za-z][A-Za-z0-9\s\.]+?)(?:\n|$)",
        r"(?i)(?:to|paid to|receiver|beneficiary)\s*[:\-]?\s*([A-Za-z][A-Za-z0-9\s\.]+)",
    ]

    BANK_PATTERNS = [
        r"(?i)(?:bank|upi\s*id|app)\s*[:\-]?\s*([A-Za-z0-9\s\.]+?)(?:\n|$)",
        r"(?i)(?:via|through)\s+([A-Za-z0-9\s\.]+?)(?:\n|$)",
    ]

    def extract(self, raw_text: str) -> PaymentExtraction:
        amount = self._extract_amount(raw_text)
        transaction_reference = self._extract_reference(raw_text)
        transaction_date = self._extract_date(raw_text)
        payment_status = self._extract_status(raw_text)
        payment_method = self._extract_method(raw_text)
        sender_name = self._extract_sender(raw_text)
        receiver_name = self._extract_receiver(raw_text)
        bank_name = self._extract_bank(raw_text)
        direction = self._detect_direction(raw_text, sender_name, receiver_name)

        return PaymentExtraction(
            amount=amount,
            sender_name=sender_name,
            receiver_name=receiver_name,
            transaction_reference=transaction_reference,
            transaction_date=transaction_date,
            payment_status=payment_status,
            payment_method=payment_method,
            bank_or_upi_name=bank_name,
            direction=direction,
            raw_text=raw_text,
        )

    def _extract_amount(self, text: str) -> Optional[float]:
        amounts = []
        for pattern in self.AMOUNT_PATTERNS:
            matches = re.findall(pattern, text, re.IGNORECASE)
            for match in matches:
                amount_str = match if isinstance(match, str) else match[0]
                amount_str = amount_str.replace(",", "").strip()
                try:
                    amounts.append(float(amount_str))
                except ValueError:
                    continue

        if amounts:
            return max(amounts)
        return None

    def _extract_reference(self, text: str) -> Optional[str]:
        for pattern in self.REFERENCE_PATTERNS:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        return None

    def _extract_date(self, text: str) -> Optional[date]:
        for pattern in self.DATE_PATTERNS:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                date_str = match.group(1).strip()
                parsed = self._parse_date(date_str)
                if parsed:
                    return parsed
        return None

    def _extract_status(self, text: str) -> Optional[str]:
        for pattern in self.STATUS_PATTERNS:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                status = match.group(1).lower()
                if status in {"success", "completed", "failed", "pending"}:
                    return status
        return "unknown"

    def _extract_method(self, text: str) -> Optional[str]:
        for pattern in self.METHOD_PATTERNS:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                method = match.group(1).lower()
                if method == "upi":
                    return "upi"
                if method == "bank transfer":
                    return "bank"
                if method in {"card", "cash", "wallet"}:
                    return method
        return None

    def _extract_sender(self, text: str) -> Optional[str]:
        for pattern in self.SENDER_PATTERNS:
            match = re.search(pattern, text, re.IGNORECASE | re.MULTILINE)
            if match:
                name = match.group(1).strip()
                name = re.sub(r"\s+", " ", name)
                name = name.strip(".,- ")
                if len(name) >= 2:
                    return name
        return None

    def _extract_receiver(self, text: str) -> Optional[str]:
        for pattern in self.RECEIVER_PATTERNS:
            match = re.search(pattern, text, re.IGNORECASE | re.MULTILINE)
            if match:
                name = match.group(1).strip()
                name = re.sub(r"\s+", " ", name)
                name = name.strip(".,- ")
                if len(name) >= 2:
                    return name
        return None

    def _extract_bank(self, text: str) -> Optional[str]:
        for pattern in self.BANK_PATTERNS:
            match = re.search(pattern, text, re.IGNORECASE | re.MULTILINE)
            if match:
                name = match.group(1).strip()
                name = re.sub(r"\s+", " ", name)
                name = name.strip(".,- ")
                if len(name) >= 2:
                    return name
        return None

    def _detect_direction(self, text: str, sender: Optional[str], receiver: Optional[str]) -> str:
        text_lower = text.lower()
        if "paid to" in text_lower or "transferred to" in text_lower or "sent to" in text_lower:
            return "sent"
        if "received from" in text_lower or "paid by" in text_lower or "credited from" in text_lower:
            return "received"
        if sender and receiver:
            return "received"
        return "unknown"

    def _parse_date(self, date_str: str) -> Optional[date]:
        date_str = date_str.strip()
        formats = [
            "%d/%m/%Y",
            "%d-%m-%Y",
            "%d.%m.%Y",
            "%m/%d/%Y",
            "%m-%d-%Y",
            "%Y-%m-%d",
            "%d %b %Y",
            "%d %B %Y",
            "%b %d, %Y",
            "%B %d, %Y",
            "%d %B %Y",
            "%B %d %Y",
        ]

        for fmt in formats:
            try:
                return datetime.strptime(date_str, fmt).date()
            except ValueError:
                continue

        return None


payment_extractor = PaymentExtractor()
