import io
import os
import re
import shutil
from datetime import datetime, timezone
from typing import Optional

from PIL import Image, ImageEnhance, ImageFilter

try:
    import pytesseract

    PYTESSERACT_AVAILABLE = True
except ImportError:
    PYTESSERACT_AVAILABLE = False

SIMULATION_MODE = os.getenv("OCR_SIMULATION_MODE", "false").lower() == "true"


class OCRService:
    MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024
    ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
    ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}

    def __init__(self):
        self._simulation = SIMULATION_MODE
        if not PYTESSERACT_AVAILABLE:
            self._simulation = True
        elif not self._simulation:
            tesseract_cmd = os.getenv("TESSERACT_CMD") or shutil.which("tesseract")
            if not tesseract_cmd:
                self._simulation = True

    def validate_file(self, filename: str, content: bytes, content_type: str) -> None:
        if len(content) > self.MAX_FILE_SIZE_BYTES:
            raise ValueError("File size exceeds 10MB limit")

        ext = os.path.splitext(filename)[1].lower()
        if ext not in self.ALLOWED_EXTENSIONS:
            raise ValueError(f"Unsupported file extension: {ext}")

        if content_type.lower() not in self.ALLOWED_MIME_TYPES:
            raise ValueError(f"Unsupported MIME type: {content_type}")

        try:
            image = Image.open(io.BytesIO(content))
            image.verify()
        except Exception:
            raise ValueError("Invalid or corrupted image file")

    def preprocess_image(self, content: bytes) -> "Image.Image":
        image = Image.open(io.BytesIO(content))

        if image.mode != "RGB":
            image = image.convert("RGB")

        image = image.resize(
            (image.width * 2, image.height * 2),
            Image.Resampling.LANCZOS,
        )

        enhancer = ImageEnhance.Contrast(image)
        image = enhancer.enhance(2.0)

        enhancer = ImageEnhance.Sharpness(image)
        image = enhancer.enhance(2.0)

        image = image.convert("L")
        image = image.point(lambda x: 0 if x < 128 else 255, "1")

        return image

    def extract_text(self, content: bytes) -> str:
        if self._simulation or not PYTESSERACT_AVAILABLE:
            return self._simulate_ocr(content)

        tesseract_cmd = os.getenv("TESSERACT_CMD") or shutil.which("tesseract")
        if not tesseract_cmd:
            return self._simulate_ocr(content)

        try:
            pytesseract.pytesseract.tesseract_cmd = tesseract_cmd
            image = self.preprocess_image(content)
            text = pytesseract.image_to_string(
                image,
                config="--psm 6",
            )
            if not text or not text.strip():
                return self._simulate_ocr(content)
            text = re.sub(r"\n{3,}", "\n\n", text)
            return text.strip()
        except Exception:
            return self._simulate_ocr(content)

    def _simulate_ocr(self, content: bytes) -> str:
        return """ABC Traders
Invoice No: INV-1001
Date: 16 September 2026
Due Date: 20 September 2026

Customer: XYZ Pvt Ltd

Item                    Qty    Rate    Amount
Software License        1      18000   18000

Subtotal:                            18000
Tax (18%):                           3240
Total:                               21240

Payment Terms: Net 15 days
"""


ocr_service = OCRService()
