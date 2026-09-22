import os
import time
from typing import Optional

from app.services.copilot_service import copilot_service
from app.services.reminder_service import reminder_service


class VoiceService:
    BOT_ACTIVATION = [
        "vyaparai",
        "vyapara ai",
        "vyapar ai",
        "vyapar",
        "hey vyaparai",
        "hi vyaparai",
        "hello vyaparai",
        "vyaparai please",
        "vyaparai help",
    ]

    def __init__(self):
        self._simulation_mode = os.getenv("VOICE_SIMULATION_MODE", "true").lower() == "true"
        self._recent_queries: dict[str, tuple[float, dict]] = {}

    def process_query(self, text: str, user_id: str, business_id: str | None = None, language: str | None = None) -> dict:
        if not text or not text.strip():
            raise ValueError("Empty voice transcription")

        text = text.strip()
        norm_lang = None
        if language:
            l = language.lower().replace("-", "_").split("_")[0]
            if l in ("en", "kn", "hi"):
                norm_lang = l

        detected_lang = None
        detected_lang = self._detect_language(text)
        # Selected app language takes precedence over speech recognition detection,
        # unless the speech recognition explicitly detected a different script or user asks for translation
        final_language = norm_lang or detected_lang or "en"
        if final_language not in ("en", "kn", "hi"):
            final_language = "en"

        activated_text = self._remove_activation(text)

        # Check in-memory debounce cache to prevent rapid double-clicks/callbacks from running duplicate queries
        cache_key = f"{user_id}:{activated_text.lower().strip()}"
        now = time.time()
        if cache_key in self._recent_queries:
            last_time, cached_res = self._recent_queries[cache_key]
            if now - last_time < 5.0:
                return cached_res

        # Check for morning briefing intent
        if self._is_morning_briefing(activated_text):
            res = self._handle_morning_briefing(user_id, business_id, activated_text, final_language)
            self._recent_queries = {k: v for k, v in self._recent_queries.items() if now - v[0] < 30.0}
            self._recent_queries[cache_key] = (now, res)
            return res

        # Process through copilot service (with transaction creation, financial analysis & greetings)
        result = copilot_service.chat(
            user_id=user_id,
            message=activated_text,
            business_id=business_id,
            language=final_language,
        )

        res = {
            "transcription": text,
            "answer": result["answer"],
            "intent": result.get("intent"),
            "language": final_language,
            "action_buttons": result.get("action_buttons", []),
        }
        self._recent_queries = {k: v for k, v in self._recent_queries.items() if now - v[0] < 30.0}
        self._recent_queries[cache_key] = (now, res)
        return res

    def _is_bot_activated(self, text: str) -> bool:
        text_lower = text.lower().strip()
        return any(activation in text_lower for activation in self.BOT_ACTIVATION)

    def _remove_activation(self, text: str) -> str:
        text_lower = text.lower().strip()
        for activation in self.BOT_ACTIVATION:
            if activation in text_lower:
                idx = text_lower.index(activation)
                prefix = text[:idx].strip(" ,.!?")
                suffix = text[idx + len(activation):].strip(" ,.!?")
                if suffix:
                    return suffix
                if prefix:
                    return prefix
                return text.strip()
        return text.strip()

    def _is_morning_briefing(self, text: str) -> bool:
        morning_keywords = [
            "morning briefing",
            "daily briefing",
            "what's today",
            "what is today",
            "today's update",
            "todays update",
            "morning update",
        ]
        text_lower = text.lower().strip()
        return any(keyword in text_lower for keyword in morning_keywords)

    def _handle_morning_briefing(self, user_id: str, business_id: str | None, text: str, language: str) -> dict:
        if not business_id:
            from app.services.financial_service import FinancialService
            financial_service = FinancialService()
            business_ids = financial_service._get_user_business_ids(user_id)
            if business_ids:
                business_id = business_ids[0]
            else:
                return {
                    "transcription": text,
                    "answer": "Hello! I am your VyaparAI bot. You don't have any business set up yet. Please create a business first.",
                    "intent": "morning_briefing",
                    "language": language,
                    "action_buttons": [],
                }

        briefing = reminder_service.get_morning_briefing(user_id, business_id)

        inc = float(briefing.get('today_income', 0.0))
        exp = float(briefing.get('today_expenses', 0.0))
        prof = inc - exp
        if language == "kn":
            answer = f"ಇಂದಿನ ಮಾರಾಟ ₹{inc:,.0f}, ವೆಚ್ಚ ₹{exp:,.0f}, ನಿವ್ವಳ ಲಾಭ ₹{prof:,.0f}."
        elif language == "hi":
            answer = f"आज की बिक्री ₹{inc:,.0f}, खर्च ₹{exp:,.0f}, शुद्ध लाभ ₹{prof:,.0f} है।"
        else:
            answer = f"Today: Sales ₹{inc:,.0f}, Expenses ₹{exp:,.0f}, Net Profit ₹{prof:,.0f}."

        return {
            "transcription": text,
            "answer": answer,
            "intent": "morning_briefing",
            "language": language,
            "action_buttons": [
                {"label": "View Details", "route": "/app/transactions"},
                {"label": "Show Reports", "route": "/app/reports"},
                {"label": "Check Reminders", "route": "/app/reminders"},
            ],
        }

    def _detect_language(self, text: str) -> str:
        devanagari_chars = sum(1 for char in text if "\u0900" <= char <= "\u097F")
        kannada_chars = sum(1 for char in text if "\u0C80" <= char <= "\u0CFF")
        tamil_chars = sum(1 for char in text if "\u0B80" <= char <= "\u0BFF")
        telugu_chars = sum(1 for char in text if "\u0C00" <= char <= "\u0C7F")

        if devanagari_chars > len(text) * 0.3:
            return "hi"
        if kannada_chars > len(text) * 0.3:
            return "kn"
        if tamil_chars > len(text) * 0.3:
            return "ta"
        if telugu_chars > len(text) * 0.3:
            return "te"
        return "en"


voice_service = VoiceService()
