import os
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

    def process_query(self, text: str, user_id: str, business_id: str | None = None) -> dict:
        if not text or not text.strip():
            raise ValueError("Empty voice transcription")

        text = text.strip()
        language = self._detect_language(text)

        activated_text = self._remove_activation(text)

        # Check for morning briefing intent
        if self._is_morning_briefing(activated_text):
            return self._handle_morning_briefing(user_id, business_id, activated_text, language)

        # Process through copilot service (with transaction creation, financial analysis & greetings)
        result = copilot_service.chat(user_id=user_id, message=activated_text, business_id=business_id)

        return {
            "transcription": text,
            "answer": result["answer"],
            "intent": result.get("intent"),
            "language": language,
            "action_buttons": result.get("action_buttons", []),
        }

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

        if not briefing.get("notifications"):
            answer = (
                f"Good morning! I am your VyaparAI bot. You have no overdue alerts for today. "
                f"Your revenue today is ₹{briefing.get('today_income', 0):,.0f} and expenses are ₹{briefing.get('today_expenses', 0):,.0f}."
            )
        else:
            notification_summary = "\n".join([
                f"- {n.get('title')}: {n.get('message')}"
                for n in briefing["notifications"]
            ])
            answer = (
                f"Good morning! I am your VyaparAI bot. Here is your briefing for today:\n\n{notification_summary}\n\n"
                f"Today's revenue: ₹{briefing.get('today_income', 0):,.0f}\n"
                f"Today's expenses: ₹{briefing.get('today_expenses', 0):,.0f}"
            )

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
