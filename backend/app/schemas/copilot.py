from pydantic import BaseModel


class CopilotChatRequest(BaseModel):
    message: str
    conversation_id: str | None = None


class CopilotChatResponse(BaseModel):
    answer: str
    intent: str | None = None
    data: dict | None = None
