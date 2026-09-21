from fastapi import APIRouter, Depends, HTTPException

from app.core.security import get_current_user
from app.schemas.copilot import CopilotChatRequest, CopilotChatResponse
from app.services.copilot_service import copilot_service

router = APIRouter(
    prefix="/copilot",
    tags=["Copilot"],
)


@router.post("/chat", response_model=CopilotChatResponse)
def chat(
    payload: CopilotChatRequest,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    message = payload.message.strip()

    if not message:
        raise HTTPException(
            status_code=400,
            detail="Message cannot be empty",
        )

    # Normalize language: e.g. "kn", "kn-IN", "kn_IN" -> "kn"
    lang = "en"
    if payload.language:
        l = payload.language.lower().replace("-", "_").split("_")[0]
        if l in ("en", "kn", "hi"):
            lang = l

    result = copilot_service.chat(
        user_id=user_id,
        message=message,
        business_id=None,
        language=lang,
    )
    return CopilotChatResponse(**result)
