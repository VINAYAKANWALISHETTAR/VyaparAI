import io
import logging
import os
import re
import shutil
from typing import Optional, Tuple
import numpy as np
from PIL import Image, ImageOps

logger = logging.getLogger(__name__)

# Check RapidOCR availability
try:
    from rapidocr_onnxruntime import RapidOCR
    RAPIDOCR_AVAILABLE = True
except ImportError:
    RAPIDOCR_AVAILABLE = False

# Check PyTesseract availability
try:
    import pytesseract
    PYTESSERACT_AVAILABLE = True
except ImportError:
    PYTESSERACT_AVAILABLE = False


class OCRService:
    MAX_FILE_SIZE_BYTES = 25 * 1024 * 1024  # 25MB limit
    ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tiff"}
    ALLOWED_MIME_TYPES = {
        "image/jpeg",
        "image/png",
        "image/webp",
        "image/bmp",
        "image/tiff",
        "application/octet-stream",  # Allow binary image streams if validated by PIL
    }

    def __init__(self):
        self._rapidocr_engine: Optional[object] = None
        self._tesseract_cmd: Optional[str] = None
        self._init_engines()

    def _init_engines(self):
        if RAPIDOCR_AVAILABLE:
            try:
                self._rapidocr_engine = RapidOCR()
                logger.info("RapidOCR engine initialized successfully.")
            except Exception as e:
                logger.warning(f"Failed to initialize RapidOCR: {e}")
                self._rapidocr_engine = None

        if PYTESSERACT_AVAILABLE:
            # Check standard tesseract binary locations
            possible_cmds = [
                os.getenv("TESSERACT_CMD"),
                shutil.which("tesseract"),
                r"C:\Program Files\Tesseract-OCR\tesseract.exe",
                r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
                os.path.expanduser(r"~\AppData\Local\Programs\Tesseract-OCR\tesseract.exe"),
                "/usr/bin/tesseract",
                "/usr/local/bin/tesseract",
            ]
            for cmd in possible_cmds:
                if cmd and os.path.isfile(cmd) and os.access(cmd, os.X_OK):
                    self._tesseract_cmd = cmd
                    pytesseract.pytesseract.tesseract_cmd = cmd
                    logger.info(f"Tesseract binary located at {cmd}")
                    break

    def is_engine_available(self) -> bool:
        """Returns True if at least one real OCR engine is initialized and ready."""
        return (self._rapidocr_engine is not None) or (self._tesseract_cmd is not None)

    def validate_file(self, filename: str, content: bytes, content_type: str) -> None:
        if not content or len(content) == 0:
            raise ValueError("File content is empty")

        if len(content) > self.MAX_FILE_SIZE_BYTES:
            raise ValueError("File size exceeds 25MB limit")

        ext = os.path.splitext(filename)[1].lower() if filename else ""
        if ext and ext not in self.ALLOWED_EXTENSIONS:
            raise ValueError(f"Unsupported file extension: {ext}. Allowed: {', '.join(self.ALLOWED_EXTENSIONS)}")

        try:
            image = Image.open(io.BytesIO(content))
            image.verify()
        except Exception:
            raise ValueError("Invalid or corrupted image file. Please provide a valid JPG, PNG, or WebP image.")

    def preprocess_image(self, content: bytes) -> Image.Image:
        """
        Preprocesses image for OCR:
        - Auto-rotates based on EXIF camera orientation tags
        - Converts color channels cleanly to RGB
        - Resizes within optimal OCR resolution bounds (800 - 3200 px)
        """
        image = Image.open(io.BytesIO(content))

        # Auto-orient using EXIF data (crucial for mobile camera captures)
        try:
            image = ImageOps.exif_transpose(image)
        except Exception:
            pass

        if image.mode != "RGB":
            image = image.convert("RGB")

        # Optimal dimensions for OCR
        min_dim = min(image.width, image.height)
        max_dim = max(image.width, image.height)

        if min_dim < 800:
            # Scale up small images
            scale = 800.0 / min_dim
            new_w = int(image.width * scale)
            new_h = int(image.height * scale)
            image = image.resize((new_w, new_h), Image.Resampling.LANCZOS)
        elif max_dim > 3200:
            # Scale down excessively large images to avoid high latency / OOM
            scale = 3200.0 / max_dim
            new_w = int(image.width * scale)
            new_h = int(image.height * scale)
            image = image.resize((new_w, new_h), Image.Resampling.LANCZOS)

        return image

    def extract_text_with_details(self, content: bytes) -> Tuple[str, float]:
        """
        Extracts real text and average confidence from image content.
        NEVER returns fake, mocked, or simulated data.
        If no text is found, returns ("", 0.0).
        """
        if not self.is_engine_available():
            raise RuntimeError(
                "OCR engine is not available on this server environment. "
                "Please ensure rapidocr-onnxruntime or tesseract-ocr is installed."
            )

        image = self.preprocess_image(content)

        # 1. Primary Engine: RapidOCR (Deep Learning onnx, highly accurate for bills/invoices)
        if self._rapidocr_engine is not None:
            try:
                img_np = np.array(image)
                results, _ = self._rapidocr_engine(img_np)
                if results and len(results) > 0:
                    lines = []
                    confidences = []
                    for item in results:
                        # item format: [box_coords, text, confidence_float]
                        text = item[1].strip()
                        conf = float(item[2])
                        if text:
                            lines.append(text)
                            confidences.append(conf)

                    if lines:
                        full_text = "\n".join(lines)
                        avg_conf = sum(confidences) / len(confidences) if confidences else 0.0
                        return full_text.strip(), round(avg_conf, 2)
            except Exception as e:
                logger.warning(f"RapidOCR execution failed: {e}. Falling back to Tesseract if available.")

        # 2. Secondary Fallback Engine: Tesseract OCR
        if self._tesseract_cmd is not None and PYTESSERACT_AVAILABLE:
            try:
                pytesseract.pytesseract.tesseract_cmd = self._tesseract_cmd
                # PSM 3: Fully automatic page segmentation (better for invoices with tables & headers)
                data = pytesseract.image_to_data(
                    image,
                    config="--psm 3",
                    output_type=pytesseract.Output.DICT,
                )
                texts = []
                confs = []
                for i in range(len(data["text"])):
                    t = data["text"][i].strip()
                    c = float(data["conf"][i])
                    if t and c >= 0:
                        texts.append(t)
                        confs.append(c / 100.0)

                if texts:
                    full_text = " ".join(texts)
                    # Clean up multi-newlines
                    full_text = re.sub(r"\s{2,}", " ", full_text)
                    avg_conf = sum(confs) / len(confs) if confs else 0.0
                    return full_text.strip(), round(avg_conf, 2)
            except Exception as e:
                logger.error(f"Tesseract execution failed: {e}")

        # If genuine OCR found no text, return empty string with 0.0 confidence.
        # NEVER return fake / mocked / simulated data!
        return "", 0.0

    def extract_text(self, content: bytes) -> str:
        """Helper to extract text only."""
        text, _ = self.extract_text_with_details(content)
        return text


ocr_service = OCRService()
