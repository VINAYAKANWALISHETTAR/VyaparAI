from pydantic import BaseModel


class VoiceQueryRequest(BaseModel):
    audio_file: bytes | None = None
    text: str | None = None
    language: str | None = None
    business_id: str | None = None


class VoiceQueryResponse(BaseModel):
    transcription: str
    answer: str
    intent: str | None = None
    language: str | None = None
    action_buttons: list[dict] = []
