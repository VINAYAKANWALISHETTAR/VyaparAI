import re
from datetime import date, datetime
from typing import Optional

from app.schemas.ocr import OCRExtraction


class InvoiceExtractor:
    INVOICE_NUMBER_PATTERNS = [
        r"(?i)(?:invoice|inv)[\s\.#:\-]*no[\s\.#:\-]*([A-Z0-9\-\/]+)",
        r"(?i)(?:invoice|inv)[\s\.#:\-]*([A-Z0-9\-\/]{2,})",
        r"(?i)(?:invoice\s+no\.?\s*[:\-]?\s*)([A-Z0-9\-\/]+)",
    ]

    AMOUNT_PATTERNS = [
        r"(?i)(total\s*[:\-]?\s*)(?:₹|rs\.?|inr)?\s*([0-9,]+\.?\d*)",
        r"(?i)(grand\s+total\s*[:\-]?\s*)(?:₹|rs\.?|inr)?\s*([0-9,]+\.?\d*)",
        r"(?i)(amount\s+due\s*[:\-]?\s*)(?:₹|rs\.?|inr)?\s*([0-9,]+\.?\d*)",
        r"(?i)(₹|rs\.?|inr)\s*([0-9,]+\.?\d*)",
    ]

    DATE_PATTERNS = [
        r"(?i)(invoice\s+date\s*[:\-]?\s*)(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})",
        r"(?i)(date\s*[:\-]?\s*)(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})",
        r"(?i)(date\s*[:\-]?\s*)(\d{1,2}\s+[A-Za-z]+\s+\d{4})",
        r"\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b",
        r"\b(\d{1,2}\s+[A-Za-z]+\s+\d{4})\b",
    ]

    DUE_DATE_PATTERNS = [
        r"(?i)(due\s+date\s*[:\-]?\s*)(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})",
        r"(?i)(due\s+date\s*[:\-]?\s*)(\d{1,2}\s+[A-Za-z]+\s+\d{4})",
        r"(?i)(pay\s+by\s*[:\-]?\s*)(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})",
        r"(?i)(pay\s+by\s*[:\-]?\s*)(\d{1,2}\s+[A-Za-z]+\s+\d{4})",
    ]

    CUSTOMER_PATTERNS = [
        r"(?i)(bill\s+to\s*[:\-]?\s*)([A-Za-z][A-Za-z0-9\s\.\,\&\-]+?)(?:\n|$)",
        r"(?i)(customer\s*[:\-]?\s*)([A-Za-z][A-Za-z0-9\s\.\,\&\-]+?)(?:\n|$)",
        r"(?i)(client\s*[:\-]?\s*)([A-Za-z][A-Za-z0-9\s\.\,\&\-]+?)(?:\n|$)",
    ]

    def extract(self, raw_text: str) -> OCRExtraction:
        invoice_number = self._extract_invoice_number(raw_text)
        customer_name = self._extract_customer_name(raw_text)
        invoice_date = self._extract_date(raw_text, self.DATE_PATTERNS)
        due_date = self._extract_date(raw_text, self.DUE_DATE_PATTERNS)
        total_amount = self._extract_total_amount(raw_text)
        currency = self._detect_currency(raw_text)

        return OCRExtraction(
            invoice_number=invoice_number,
            customer_name=customer_name,
            invoice_date=invoice_date,
            due_date=due_date,
            total_amount=total_amount,
            currency=currency,
            raw_text=raw_text,
        )

    def _extract_invoice_number(self, text: str) -> Optional[str]:
        for pattern in self.INVOICE_NUMBER_PATTERNS:
            match = re.search(pattern, text)
            if match:
                group_index = 2 if len(match.groups()) >= 2 else 1
                value = match.group(group_index).strip()
                if value and value.lower() not in {"no", "number", "no."}:
                    return value
        return None

    def _extract_customer_name(self, text: str) -> Optional[str]:
        for pattern in self.CUSTOMER_PATTERNS:
            match = re.search(pattern, text, re.IGNORECASE | re.MULTILINE)
            if match:
                name = match.group(2).strip()
                name = re.sub(r"\s+", " ", name)
                name = name.strip(".,- ")
                if len(name) >= 2:
                    return name
        return None

    def _extract_date(self, text: str, patterns: list) -> Optional[date]:
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                date_str = match.group(2) if len(match.groups()) > 1 else match.group(1)
                parsed = self._parse_date(date_str)
                if parsed:
                    return parsed
        return None

    def _extract_total_amount(self, text: str) -> Optional[float]:
        amounts = []
        for pattern in self.AMOUNT_PATTERNS:
            matches = re.findall(pattern, text, re.IGNORECASE)
            for match in matches:
                amount_str = match[1] if len(match) > 1 else match[0]
                amount_str = amount_str.replace(",", "").strip()
                try:
                    amounts.append(float(amount_str))
                except ValueError:
                    continue

        if amounts:
            return max(amounts)
        return None

    def _detect_currency(self, text: str) -> Optional[str]:
        text_lower = text.lower()
        if "₹" in text or "rs." in text_lower or "inr" in text_lower:
            return "INR"
        if "$" in text:
            return "USD"
        if "€" in text or "eur" in text_lower:
            return "EUR"
        if "£" in text or "gbp" in text_lower:
            return "GBP"
        return None

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


invoice_extractor = InvoiceExtractor()
