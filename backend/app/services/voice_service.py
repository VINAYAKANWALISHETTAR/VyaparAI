import os
from typing import Optional

from app.services.copilot_service import copilot_service


class VoiceService:
    def __init__(self):
        self._simulation_mode = os.getenv("VOICE_SIMULATION_MODE", "true").lower() == "true"

    def process_query(self, text: str, user_id: str, business_id: str | None = None) -> dict:
        if not text or not text.strip():
            raise ValueError("Empty voice transcription")

        text = text.strip()
        language = self._detect_language(text)

        result = copilot_service.chat(user_id=user_id, message=text, business_id=business_id)

        return {
            "transcription": text,
            "answer": result["answer"],
            "intent": result.get("intent"),
            "language": language,
        }

    def _detect_language(self, text: str) -> str:
        devanagari_chars = sum(1 for char in text if "\u0900" <= char <= "\u097F")
        kannada_chars = sum(1 for char in text if "\u0C80" <= char <= "\u0CFF")

        if devanagari_chars > len(text) * 0.3:
            return "hi"
        if kannada_chars > len(text) * 0.3:
            return "kn"
        return "en"


voice_service = VoiceService()
