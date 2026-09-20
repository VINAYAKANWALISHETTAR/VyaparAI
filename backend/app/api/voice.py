from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile

from app.core.security import get_current_user
from app.schemas.voice import VoiceQueryRequest, VoiceQueryResponse
from app.services.voice_service import voice_service

router = APIRouter(
    prefix="/voice",
    tags=["Voice"],
)


@router.post("/query", response_model=VoiceQueryResponse)
def voice_query(
    current_user=Depends(get_current_user),
    body: VoiceQueryRequest | None = None,
    text: str | None = None,
    language: str | None = None,
    file: UploadFile | None = File(default=None),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    query_text = (body.text if body and body.text else text) or ""
    req_language = (body.language if body and body.language else language) or None
    req_business_id = (body.business_id if body and body.business_id else business_id) or None

    if file:
        try:
            content = file.file.read()
        except Exception as exc:
            raise HTTPException(status_code=400, detail=f"Failed to read audio file: {exc}")

        query_text = _simulate_transcription(content, file.filename or "audio.webm")

    if not query_text or not query_text.strip():
        raise HTTPException(
            status_code=400,
            detail="Provide either text or an audio file",
        )

    try:
        result = voice_service.process_query(
            text=query_text,
            user_id=user_id,
            business_id=req_business_id,
            language=req_language,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Voice processing failed: {exc}") from exc

    return VoiceQueryResponse(**result)


def _simulate_transcription(content: bytes, filename: str) -> str:
    return "What is my profit today?"
