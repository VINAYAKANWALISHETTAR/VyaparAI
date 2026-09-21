import logging
import re
from datetime import date, datetime
from typing import Any, Dict, List, Optional, Tuple

from app.schemas.ocr import OCRExtraction

logger = logging.getLogger(__name__)

# Indian GSTIN Regex: 2 digits state code + 5 chars PAN + 4 digits + 1 char entity + 1 char checksum + Z + 1 char
GSTIN_REGEX = r"\b\d{2}[A-Z]{5}\d{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}\b"

# Noise / stopwords that must not be treated as customer or vendor names
INVALID_NAME_PATTERNS = {
    "invoice", "tax invoice", "bill of supply", "retail invoice", "cash memo",
    "original for recipient", "duplicate for supplier", "triplicate for transporter",
    "gstin", "pan no", "date", "subtotal", "total", "amount", "phone", "email",
    "address", "terms and conditions", "authorized signatory", "thank you",
    "signature", "description", "qty", "quantity", "rate", "hsn", "sac",
}


class InvoiceExtractor:
    INVOICE_NUM_KEYWORDS = [
        r"(?i)\b(?:tax[ \t]*invoice|invoice|inv|bill)[ \t.:#\/-]*(?:no|na|number|num|id|#|:)[ \t.:#\/-]*([A-Za-z0-9\-\/]{3,30})",
        r"(?i)\b(?:invoice|inv|bill)[ \t]*:[ \t]*([A-Za-z0-9\-\/]{3,30})",
        r"(?i)\b(?:inv|bill)[\.:#\/-]+([A-Za-z0-9\-\/]{3,20})\b",
    ]

    TOTAL_PATTERNS = [
        r"(?i)(?:grand[ \t]*total|invoice[ \t]*total|net[ \t]*payable|total[ \t]*amount|amount[ \t]*due|net[ \t]*amount|total[ \t]*due|total[ \t]*value)[ \t.:\-]*[₹]?[ \t]*(?:rs\.?|inr)?[ \t:]*([0-9,]+\.?\d*)",
        r"(?i)\b(?:total)[ \t.:\-]+[₹]?[ \t]*(?:rs\.?|inr)?[ \t:]*([0-9,]+\.?\d*)",
    ]

    SUBTOTAL_PATTERNS = [
        r"(?i)(?:sub\s*total|taxable\s+amount|taxable\s+value)[\s\.:\-]*[₹\s]*(?:rs\.?|inr)?[\s:]*([0-9,]+\.?\d*)",
    ]

    TAX_PATTERNS = [
        r"(?i)(?:total\s+tax|tax\s+amount|gst\s+total)[\s\.:\-]*[₹\s]*(?:rs\.?|inr)?[\s:]*([0-9,]+\.?\d*)",
    ]

    CGST_PATTERNS = [
        r"(?i)(?:cgst)[\s\.:\-%0-9]*[₹\s]*(?:rs\.?|inr)?[\s:]*([0-9,]+\.?\d*)",
    ]

    SGST_PATTERNS = [
        r"(?i)(?:sgst|utgst)[\s\.:\-%0-9]*[₹\s]*(?:rs\.?|inr)?[\s:]*([0-9,]+\.?\d*)",
    ]

    IGST_PATTERNS = [
        r"(?i)(?:igst)[\s\.:\-%0-9]*[₹\s]*(?:rs\.?|inr)?[\s:]*([0-9,]+\.?\d*)",
    ]

    BUYER_PATTERNS = [
        r"(?i)(?:bill\s+to|billed\s+to|buyer|customer|client|recipient|party\s+name|m\/s\.?)[\s\.:\-]+([A-Za-z0-9\s\.\,\&\-]{2,60})",
        r"(?i)(?:ship\s+to|shipped\s+to|consignee)[\s\.:\-]+([A-Za-z0-9\s\.\,\&\-]{2,60})",
    ]

    SELLER_PATTERNS = [
        r"(?i)(?:sold\s+by|from|supplier|merchant|vendor|seller)[\s\.:\-]+([A-Za-z0-9\s\.\,\&\-]{2,60})",
    ]

    DATE_PATTERNS = [
        r"(?i)(?:invoice\s+date|bill\s+date|dated|date)[\s\.:\-]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})",
        r"(?i)(?:invoice\s+date|bill\s+date|dated|date)[\s\.:\-]*(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})",
        r"(?i)(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})",
        r"\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b",
    ]

    DUE_DATE_PATTERNS = [
        r"(?i)(?:due\s+date|pay\s+by|payment\s+due)[\s\.:\-]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})",
        r"(?i)(?:due\s+date|pay\s+by|payment\s+due)[\s\.:\-]*(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{4})",
    ]

    def classify_document(self, text: str) -> str:
        """
        Classifies document based on text features into:
        - 'invoice': Standard B2B/B2C invoice, bill of supply, tax invoice
        - 'receipt': Retail POS receipt, cash slip
        - 'payment_screenshot': UPI/Banking payment confirmation
        - 'unreadable': Empty, noise, or unintelligible OCR
        - 'unsupported': Image does not contain invoice/receipt data
        """
        if not text or len(text.strip()) < 15:
            return "unreadable"

        lower_text = text.lower()

        # Payment screenshot indicators
        payment_signals = [
            "paid to", "transferred to", "upi ref", "utr", "google pay", "phonepe",
            "paytm", "payment successful", "bhim upi", "debited from", "transaction id",
        ]
        payment_matches = sum(1 for sig in payment_signals if sig in lower_text)
        if payment_matches >= 2:
            return "payment_screenshot"

        # Invoice indicators
        invoice_signals = [
            "tax invoice", "invoice", "bill of supply", "gstin", "invoice no",
            "bill to", "taxable value", "cgst", "sgst", "igst", "hsn", "sac",
            "subtotal", "grand total", "net amount", "reverse charge",
        ]
        invoice_matches = sum(1 for sig in invoice_signals if sig in lower_text)

        # Receipt indicators
        receipt_signals = [
            "cash receipt", "payment receipt", "retail receipt", "store receipt",
            "cash memo", "pos receipt", "counter bill", "bill no", "receipt no",
        ]
        receipt_matches = sum(1 for sig in receipt_signals if sig in lower_text)

        if invoice_matches >= 2 or (invoice_matches >= 1 and ("gstin" in lower_text or "total" in lower_text)):
            return "invoice"

        if receipt_matches >= 1 or (invoice_matches >= 1 and "total" in lower_text):
            return "receipt"

        # If has GSTIN or explicit invoice number format
        if re.search(GSTIN_REGEX, text) or re.search(r"(?i)inv[\s\.\-]*no", text):
            return "invoice"

        return "unsupported"

    def extract(self, raw_text: str) -> OCRExtraction:
        """
        Extracts structured fields with confidence scores and validation.
        NEVER returns fake, guessed, or hardcoded data.
        """
        if not raw_text or not raw_text.strip():
            return OCRExtraction(
                document_type="unreadable",
                raw_text="",
                confidence_score=0.0,
                validation_warnings=["No readable text found in image."],
            )

        doc_type = self.classify_document(raw_text)
        if doc_type in {"unreadable", "unsupported"}:
            return OCRExtraction(
                document_type=doc_type,
                raw_text=raw_text,
                confidence_score=0.0,
                validation_warnings=[
                    "Document does not appear to contain a supported invoice or receipt."
                    if doc_type == "unsupported"
                    else "Could not extract legible text from image."
                ],
            )

        warnings: List[str] = []

        # 1. GSTIN extraction (Seller & Buyer)
        seller_gstin, buyer_gstin = self._extract_gstins(raw_text)

        # 2. Invoice number
        invoice_number = self._extract_invoice_number(raw_text)
        if not invoice_number:
            warnings.append("Invoice number not found.")

        # 3. Parties: Seller & Buyer
        seller_name, buyer_name = self._extract_parties(raw_text)
        if not buyer_name and not seller_name:
            warnings.append("Party (Customer / Vendor) name could not be reliably determined.")

        # 4. Dates
        invoice_date = self._extract_date(raw_text, self.DATE_PATTERNS)
        due_date = self._extract_date(raw_text, self.DUE_DATE_PATTERNS)

        # 5. Amounts: Total, Subtotal, Taxes
        total_amount = self._extract_total_amount(raw_text)
        subtotal = self._extract_subtotal(raw_text)
        cgst = self._extract_tax_component(raw_text, "cgst")
        sgst = self._extract_tax_component(raw_text, "sgst|utgst")
        igst = self._extract_tax_component(raw_text, "igst")
        tax = self._extract_single_amount(raw_text, self.TAX_PATTERNS)

        # Calculate combined tax if individual components present
        component_tax = (cgst or 0.0) + (sgst or 0.0) + (igst or 0.0)
        if component_tax > 0 and (tax is None or tax == 0.0):
            tax = round(component_tax, 2)

        # Arithmetic validation
        arithmetic_valid = False
        if total_amount is not None:
            if subtotal is not None and tax is not None:
                expected_total = subtotal + tax
                if abs(expected_total - total_amount) <= 1.0:  # Allow 1 rupee rounding tolerance
                    arithmetic_valid = True
                else:
                    warnings.append(
                        f"Subtotal (₹{subtotal:.2f}) + Tax (₹{tax:.2f}) does not match Total (₹{total_amount:.2f})."
                    )
        else:
            if subtotal is not None and tax is not None:
                # Deduce total if subtotal and tax are explicitly present
                total_amount = round(subtotal + tax, 2)
                arithmetic_valid = True
            else:
                warnings.append("Total amount could not be reliably extracted.")

        currency = self._detect_currency(raw_text)

        # 6. Line Items (Only real lines parsed, NEVER fake)
        items = self._extract_line_items(raw_text)

        # 7. Calculate confidence score
        confidence = self._calculate_confidence(
            doc_type=doc_type,
            invoice_number=invoice_number,
            total_amount=total_amount,
            buyer_name=buyer_name,
            seller_name=seller_name,
            invoice_date=invoice_date,
            seller_gstin=seller_gstin,
            arithmetic_valid=arithmetic_valid,
        )

        return OCRExtraction(
            document_type=doc_type,
            invoice_number=invoice_number,
            customer_name=buyer_name or seller_name,  # Primary party for billing
            business_name=seller_name,
            seller_name=seller_name,
            buyer_name=buyer_name,
            seller_gstin=seller_gstin,
            buyer_gstin=buyer_gstin,
            invoice_date=invoice_date,
            due_date=due_date,
            subtotal=subtotal,
            tax=tax,
            cgst=cgst,
            sgst=sgst,
            igst=igst,
            total_amount=total_amount,
            currency=currency,
            items=items,
            confidence_score=confidence,
            validation_warnings=warnings,
            raw_text=raw_text,
        )

    def _extract_gstins(self, text: str) -> Tuple[Optional[str], Optional[str]]:
        matches = re.findall(GSTIN_REGEX, text)
        if not matches:
            return None, None

        unique_gstins = []
        for g in matches:
            if g not in unique_gstins:
                unique_gstins.append(g)

        seller_gstin = None
        buyer_gstin = None

        if len(unique_gstins) == 1:
            seller_gstin = unique_gstins[0]
        elif len(unique_gstins) >= 2:
            # Check proximity to "bill to" or "buyer"
            lines = text.split("\n")
            for i, line in enumerate(lines):
                lower = line.lower()
                if any(w in lower for w in ["buyer", "bill to", "customer"]):
                    # Look ahead a few lines for buyer GSTIN
                    context = " ".join(lines[i : min(len(lines), i + 4)])
                    for g in unique_gstins:
                        if g in context:
                            buyer_gstin = g
                            break
            # Assign remaining to seller
            remaining = [g for g in unique_gstins if g != buyer_gstin]
            seller_gstin = remaining[0] if remaining else None

        return seller_gstin, buyer_gstin

    def _extract_invoice_number(self, text: str) -> Optional[str]:
        for pattern in self.INVOICE_NUM_KEYWORDS:
            match = re.search(pattern, text)
            if match:
                val = match.group(1).strip(".:- #")
                # Validate length and content
                if 2 <= len(val) <= 30 and not any(w in val.lower() for w in ["date", "tax", "total", "cash", "no"]):
                    return val
        return None

    def _extract_parties(self, text: str) -> Tuple[Optional[str], Optional[str]]:
        lines = [line.strip() for line in text.split("\n") if line.strip()]
        buyer_name = None
        seller_name = None

        # 1. Search for Buyer
        for pattern in self.BUYER_PATTERNS:
            match = re.search(pattern, text, re.MULTILINE)
            if match:
                candidate = match.group(1).strip()
                cleaned = self._clean_party_name(candidate)
                if cleaned:
                    buyer_name = cleaned
                    break

        # 2. Search for Seller
        for pattern in self.SELLER_PATTERNS:
            match = re.search(pattern, text, re.MULTILINE)
            if match:
                candidate = match.group(1).strip()
                cleaned = self._clean_party_name(candidate)
                if cleaned:
                    seller_name = cleaned
                    break

        # If seller not found via pattern, the top non-empty line before "Tax Invoice" is often the business name
        if not seller_name and len(lines) > 0:
            for line in lines[:5]:
                lower = line.lower()
                if any(inv_kw in lower for inv_kw in ["tax invoice", "invoice", "bill of supply", "gstin", "date:"]):
                    continue
                cleaned = self._clean_party_name(line)
                if cleaned and len(cleaned) >= 3 and cleaned != buyer_name:
                    seller_name = cleaned
                    break

        return seller_name, buyer_name

    def _clean_party_name(self, name: str) -> Optional[str]:
        # Strip phone numbers, GST numbers, addresses, and trailing invoice labels that might leak into the capture
        name = re.sub(r"(?i)\b(?:gstin|gst|pan|ph|phone|mob|mobile|tel|address|invoice|inv\s*no|bill\s*no)\b.*", "", name)
        name = re.sub(r"\b\d{10}\b", "", name)  # 10 digit phone
        name = re.sub(r"[^A-Za-z0-9\s\.\,\&\-]", "", name).strip(" .,-")
        name = re.sub(r"\s+", " ", name)

        if len(name) < 2:
            return None

        if name.lower() in INVALID_NAME_PATTERNS:
            return None

        return name

    def _extract_total_amount(self, text: str) -> Optional[float]:
        """
        Extracts labeled total amount.
        Does NOT use max(amounts) so phone numbers / barcodes are not picked up.
        """
        for pattern in self.TOTAL_PATTERNS:
            match = re.search(pattern, text)
            if match:
                amt_str = match.group(1).replace(",", "").strip()
                try:
                    val = float(amt_str)
                    if 0 < val < 100000000:  # Reasonable financial bounds
                        return val
                except ValueError:
                    continue

        # Look specifically in lines containing "Total" (case-insensitive)
        for line in text.split("\n"):
            line_lower = line.lower()
            if "total" in line_lower and not any(k in line_lower for k in ["subtotal", "sub total", "tax"]):
                # Extract number from this line
                nums = re.findall(r"([0-9,]+\.\d{2}|[0-9,]+)", line)
                for n in reversed(nums):
                    clean_n = n.replace(",", "").strip()
                    try:
                        val = float(clean_n)
                        if val > 0:
                            return val
                    except ValueError:
                        continue

        return None

    def _extract_subtotal(self, text: str) -> Optional[float]:
        val = self._extract_single_amount(text, self.SUBTOTAL_PATTERNS)
        if val is not None:
            return val
        for line in text.split("\n"):
            line_lower = line.lower()
            if any(k in line_lower for k in ["subtotal", "sub total", "taxable value", "taxable amount"]):
                nums = re.findall(r"([0-9,]+\.\d{2}|[0-9,]+)", line)
                for n in reversed(nums):
                    clean_n = n.replace(",", "").strip()
                    try:
                        v = float(clean_n)
                        if v > 0:
                            return v
                    except ValueError:
                        continue
        return None

    def _extract_tax_component(self, text: str, keyword_pattern: str) -> Optional[float]:
        for line in text.split("\n"):
            if re.search(rf"(?i)\b(?:{keyword_pattern})\b", line):
                nums = re.findall(r"([0-9,]+\.\d{2}|[0-9,]+)", line)
                for n in reversed(nums):
                    clean_n = n.replace(",", "").strip()
                    try:
                        v = float(clean_n)
                        # Check if this isn't just a rate like 9 or 18 followed by %
                        if v > 0:
                            return v
                    except ValueError:
                        continue
        return None

    def _extract_single_amount(self, text: str, patterns: List[str]) -> Optional[float]:
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                amt_str = match.group(1).replace(",", "").strip()
                try:
                    val = float(amt_str)
                    if val >= 0:
                        return val
                except ValueError:
                    continue
        return None

    def _extract_date(self, text: str, patterns: List[str]) -> Optional[date]:
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                date_str = match.group(1).strip()
                parsed = self._parse_date(date_str)
                if parsed:
                    return parsed
        return None

    def _parse_date(self, date_str: str) -> Optional[date]:
        date_str = date_str.strip().replace(".", "/").replace("-", "/")
        formats = [
            "%d/%m/%Y",
            "%d/%m/%y",
            "%m/%d/%Y",
            "%Y/%m/%d",
            "%d %b %Y",
            "%d %B %Y",
            "%b %d, %Y",
            "%B %d, %Y",
            "%d %b %y",
        ]
        for fmt in formats:
            try:
                dt = datetime.strptime(date_str, fmt).date()
                if 2000 <= dt.year <= 2050:
                    return dt
            except ValueError:
                continue
        return None

    def _detect_currency(self, text: str) -> str:
        text_lower = text.lower()
        if "₹" in text or "rs" in text_lower or "inr" in text_lower:
            return "INR"
        if "$" in text or "usd" in text_lower:
            return "USD"
        if "€" in text or "eur" in text_lower:
            return "EUR"
        if "£" in text or "gbp" in text_lower:
            return "GBP"
        return "INR"  # Standard default for Vyapar app

    def _extract_line_items(self, text: str) -> List[Dict[str, Any]]:
        """
        Parses genuine line items when tabular layout is detected.
        Never outputs fake/demo items.
        """
        items: List[Dict[str, Any]] = []
        lines = text.split("\n")

        # Line item regex pattern: Description followed by Qty, Rate, Amount
        # e.g.: "Cement Bag 50kg   10   350   3500.00"
        item_regex = r"^([A-Za-z0-9\s\.\-\(\)]+?)\s+(\d+(?:\.\d+)?)\s+([0-9,]+(?:\.\d+)?)\s+([0-9,]+(?:\.\d+)?)$"

        in_item_section = False
        for line in lines:
            line_str = line.strip()
            lower = line_str.lower()

            if any(h in lower for h in ["item", "description", "particulars"]) and any(h in lower for h in ["qty", "rate", "amount"]):
                in_item_section = True
                continue

            if in_item_section:
                if any(t in lower for t in ["subtotal", "total", "tax", "cgst", "sgst", "igst", "terms"]):
                    break

                match = re.match(item_regex, line_str)
                if match:
                    desc = match.group(1).strip()
                    if desc.lower() not in INVALID_NAME_PATTERNS and len(desc) >= 2:
                        try:
                            qty = float(match.group(2))
                            rate = float(match.group(3).replace(",", ""))
                            amt = float(match.group(4).replace(",", ""))
                            items.append({
                                "description": desc,
                                "quantity": qty,
                                "unit_price": rate,
                                "amount": amt,
                            })
                        except ValueError:
                            continue

        return items

    def _calculate_confidence(
        self,
        doc_type: str,
        invoice_number: Optional[str],
        total_amount: Optional[float],
        buyer_name: Optional[str],
        seller_name: Optional[str],
        invoice_date: Optional[date],
        seller_gstin: Optional[str],
        arithmetic_valid: bool,
    ) -> float:
        score = 0.0
        if doc_type in {"invoice", "receipt"}:
            score += 0.20

        if total_amount is not None and total_amount > 0:
            score += 0.30

        if invoice_number:
            score += 0.15

        if buyer_name or seller_name:
            score += 0.15

        if invoice_date:
            score += 0.10

        if seller_gstin:
            score += 0.05

        if arithmetic_valid:
            score += 0.05

        return min(round(score, 2), 1.0)


invoice_extractor = InvoiceExtractor()
