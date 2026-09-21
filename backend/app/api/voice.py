from fastapi import APIRouter, Depends, File, HTTPException, Query, Request, UploadFile

from app.core.security import get_current_user
from app.schemas.voice import VoiceQueryRequest, VoiceQueryResponse
from app.services.voice_service import voice_service

router = APIRouter(
    prefix="/voice",
    tags=["Voice"],
)


@router.post("/query", response_model=VoiceQueryResponse)
async def voice_query(
    request: Request,
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    query_text = ""
    req_language = None
    req_business_id = business_id

    content_type = request.headers.get("content-type", "").lower()
    if "application/json" in content_type:
        try:
            body = await request.json()
            if isinstance(body, dict):
                query_text = body.get("text", "") or ""
                req_language = body.get("language")
                req_business_id = body.get("business_id", req_business_id)
        except Exception:
            pass
    elif "multipart/form-data" in content_type:
        try:
            form = await request.form()
            query_text = form.get("text") or ""
            req_language = form.get("language")
            req_business_id = form.get("business_id") or req_business_id
            file = form.get("file")
            if file and hasattr(file, "read") and not query_text:
                raise HTTPException(
                    status_code=400,
                    detail="Audio file transcription requires on-device speech-to-text. Please provide the recognized text."
                )
        except HTTPException:
            raise
        except Exception as exc:
            raise HTTPException(status_code=400, detail=f"Failed to read form data: {exc}")
    else:
        # Fallback to query params or text body
        try:
            raw_body = await request.body()
            if raw_body:
                import json
                try:
                    data = json.loads(raw_body.decode("utf-8"))
                    if isinstance(data, dict):
                        query_text = data.get("text", "") or ""
                        req_language = data.get("language")
                        req_business_id = data.get("business_id", req_business_id)
                except Exception:
                    query_text = raw_body.decode("utf-8")
        except Exception:
            pass

    if not query_text or not query_text.strip():
        query_text = request.query_params.get("text", "").strip()

    if not query_text or not query_text.strip():
        raise HTTPException(
            status_code=400,
            detail="Provide query text from speech recognition",
        )

    # Auto-resolve default business if not explicitly provided
    if not req_business_id:
        from app.services.financial_service import FinancialService
        financial_service = FinancialService()
        business_ids = financial_service._get_user_business_ids(user_id)
        if business_ids:
            req_business_id = business_ids[0]

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
