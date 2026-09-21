from __future__ import annotations

import datetime as dt
from typing import Optional
from pydantic import BaseModel, Field, field_validator


ALLOWED_SOURCES = {"manual", "upi", "bank", "invoice", "voice", "ocr", "agent"}


class TransactionCreate(BaseModel):
    business_id: str | None = None
    type: str
    amount: float = Field(gt=0)
    category: str = Field(min_length=1)
    description: str | None = None
    date: dt.date = Field(default_factory=dt.date.today)
    source: str = "manual"
    reference_id: str | None = None
    user_id: str | None = None

    @field_validator("type")
    @classmethod
    def validate_type(cls, value: str) -> str:
        value = value.strip().lower()
        if value not in {"income", "expense"}:
            raise ValueError("type must be 'income' or 'expense'")
        return value

    @field_validator("source")
    @classmethod
    def validate_source(cls, value: str) -> str:
        value = value.strip().lower()
        if value not in ALLOWED_SOURCES:
            raise ValueError(
                "source must be one of: "
                + ", ".join(sorted(ALLOWED_SOURCES))
            )
        return value


class TransactionUpdate(BaseModel):
    type: str | None = None
    amount: float | None = Field(default=None, gt=0)
    category: str | None = Field(default=None, min_length=1)
    description: str | None = None
    date: Optional[dt.date] = None
    source: str | None = None
    reference_id: str | None = None
    user_id: str | None = None

    @field_validator("type")
    @classmethod
    def validate_type(cls, value: str | None) -> str | None:
        if value is None:
            return value
        value = value.strip().lower()
        if value not in {"income", "expense"}:
            raise ValueError("type must be 'income' or 'expense'")
        return value

    @field_validator("source")
    @classmethod
    def validate_source(cls, value: str | None) -> str | None:
        if value is None:
            return value
        value = value.strip().lower()
        if value not in ALLOWED_SOURCES:
            raise ValueError(
                "source must be one of: "
                + ", ".join(sorted(ALLOWED_SOURCES))
            )
        return value


class TransactionResponse(BaseModel):
    id: str
    business_id: str
    user_id: str | None = None
    type: str
    amount: float
    category: str
    description: str | None = None
    date: Optional[str] = None
    source: str | None = None
    reference_id: str | None = None
    created_at: str | None = None
    updated_at: str | None = None
