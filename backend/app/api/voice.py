from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile

from app.core.security import get_current_user
from app.schemas.voice import VoiceQueryResponse
from app.services.voice_service import voice_service

router = APIRouter(
    prefix="/voice",
    tags=["Voice"],
)


@router.post("/query", response_model=VoiceQueryResponse)
def voice_query(
    current_user=Depends(get_current_user),
    text: str | None = None,
    file: UploadFile | None = File(default=None),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])

    if file:
        try:
            content = file.file.read()
        except Exception as exc:
            raise HTTPException(status_code=400, detail=f"Failed to read audio file: {exc}")

        text = _simulate_transcription(content, file.filename or "audio.webm")

    if not text or not text.strip():
        raise HTTPException(
            status_code=400,
            detail="Provide either text or an audio file",
        )

    try:
        result = voice_service.process_query(text=text, user_id=user_id, business_id=business_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Voice processing failed: {exc}") from exc

    return VoiceQueryResponse(**result)


def _simulate_transcription(content: bytes, filename: str) -> str:
    return "What is my profit today?"
