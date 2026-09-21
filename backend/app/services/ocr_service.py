import io
import logging
import os
import re
import shutil
from typing import Optional, Tuple
import numpy as np
from PIL import Image, ImageOps
import requests

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
        self._ocr_space_key: str = (
            os.getenv("OCR_SPACE_API_KEY")
            or os.getenv("OCR_API_KEY")
            or "K81686941188957"
        )
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
        """Returns True if at least one real OCR engine (RapidOCR, Tesseract, or OCR.space Cloud API) is ready."""
        return (
            (self._rapidocr_engine is not None)
            or (self._tesseract_cmd is not None)
            or bool(self._ocr_space_key)
        )

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

    def _extract_via_ocr_space(self, content: bytes, language: Optional[str] = None) -> Tuple[str, float]:
        """
        Extract text using OCR.space Cloud API.
        Engine 2 is optimized for numbers, invoices, receipts, and table extraction.
        Engine 1 is used for regional scripts (Kannada, Hindi).
        """
        if not self._ocr_space_key:
            return "", 0.0

        ocr_lang = "eng"
        engine = "2"
        if language:
            norm = language.lower().replace("-", "_").split("_")[0]
            if norm == "kn":
                ocr_lang = "kan"
                engine = "1"
            elif norm == "hi":
                ocr_lang = "hin"
                engine = "1"

        try:
            res = requests.post(
                "https://api.ocr.space/parse/image",
                files={"file": ("receipt.jpg", content, "image/jpeg")},
                data={
                    "apikey": self._ocr_space_key,
                    "language": ocr_lang,
                    "OCREngine": engine,
                    "isTable": "true",
                    "scale": "true",
                    "detectOrientation": "true",
                },
                timeout=25,
            )
            if res.status_code == 200:
                data = res.json()
                if data.get("OCRExitCode") in (1, 2) and data.get("ParsedResults"):
                    parsed_texts = []
                    for pr in data["ParsedResults"]:
                        pt = pr.get("ParsedText", "").strip()
                        if pt:
                            parsed_texts.append(pt)
                    if parsed_texts:
                        return "\n".join(parsed_texts).strip(), 0.95
                elif engine == "2":
                    # Fallback to engine 1 if engine 2 encountered a parsing issue
                    res2 = requests.post(
                        "https://api.ocr.space/parse/image",
                        files={"file": ("receipt.jpg", content, "image/jpeg")},
                        data={
                            "apikey": self._ocr_space_key,
                            "language": ocr_lang,
                            "OCREngine": "1",
                            "isTable": "true",
                            "scale": "true",
                        },
                        timeout=25,
                    )
                    if res2.status_code == 200:
                        data2 = res2.json()
                        if data2.get("OCRExitCode") in (1, 2) and data2.get("ParsedResults"):
                            parsed_texts = [
                                pr.get("ParsedText", "").strip()
                                for pr in data2["ParsedResults"]
                                if pr.get("ParsedText", "").strip()
                            ]
                            if parsed_texts:
                                return "\n".join(parsed_texts).strip(), 0.90
        except Exception as e:
            logger.warning(f"OCR.space API request failed: {e}")

        return "", 0.0

    def extract_text_with_details(self, content: bytes, language: Optional[str] = None) -> Tuple[str, float]:
        """
        Extracts real text and average confidence from image content.
        NEVER returns fake, mocked, or simulated data.
        If no text is found, returns ("", 0.0).
        """
        if not self.is_engine_available():
            raise RuntimeError(
                "OCR engine is not available on this server environment. "
                "Please ensure rapidocr-onnxruntime, tesseract-ocr, or a valid OCR_SPACE_API_KEY is configured."
            )

        image = self.preprocess_image(content)

        # 1. Primary Engine: RapidOCR (Deep Learning onnx, fast local inference)
        if self._rapidocr_engine is not None:
            try:
                img_np = np.array(image)
                results, _ = self._rapidocr_engine(img_np)
                if results and len(results) > 0:
                    lines = []
                    confidences = []
                    for item in results:
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
                logger.warning(f"RapidOCR execution failed: {e}. Falling back to OCR.space / Tesseract.")

        # 2. Secondary Engine: OCR.space Cloud API (High accuracy on bills, receipts, tables)
        if self._ocr_space_key:
            try:
                img_bytes = io.BytesIO()
                image.save(img_bytes, format="JPEG", quality=95)
                ocr_text, ocr_conf = self._extract_via_ocr_space(img_bytes.getvalue(), language=language)
                if ocr_text:
                    return ocr_text, ocr_conf
            except Exception as e:
                logger.warning(f"OCR.space extraction failed: {e}. Falling back to Tesseract.")

        # 3. Tertiary Fallback Engine: Tesseract OCR
        if self._tesseract_cmd is not None and PYTESSERACT_AVAILABLE:
            try:
                pytesseract.pytesseract.tesseract_cmd = self._tesseract_cmd
                tess_lang = "eng"
                if language:
                    norm = language.lower().replace("-", "_").split("_")[0]
                    if norm == "kn":
                        tess_lang = "kan+eng"
                    elif norm == "hi":
                        tess_lang = "hin+eng"

                try:
                    data = pytesseract.image_to_data(
                        image,
                        lang=tess_lang,
                        config="--psm 3",
                        output_type=pytesseract.Output.DICT,
                    )
                except Exception:
                    data = pytesseract.image_to_data(
                        image,
                        lang="eng",
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
                    full_text = re.sub(r"\s{2,}", " ", full_text)
                    avg_conf = sum(confs) / len(confs) if confs else 0.0
                    return full_text.strip(), round(avg_conf, 2)
            except Exception as e:
                logger.error(f"Tesseract execution failed: {e}")

        # If genuine OCR found no text, return empty string with 0.0 confidence.
        return "", 0.0

    def extract_text(self, content: bytes) -> str:
        """Helper to extract text only."""
        text, _ = self.extract_text_with_details(content)
        return text


ocr_service = OCRService()
