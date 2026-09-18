from datetime import date
from pydantic import BaseModel, Field, field_validator


ALLOWED_SOURCES = {"manual", "upi", "bank", "invoice", "voice", "ocr"}


class TransactionCreate(BaseModel):
    business_id: str
    transaction_type: str
    amount: float = Field(gt=0)
    category: str = Field(min_length=1)
    description: str | None = None
    transaction_date: date
    source: str = "manual"
    reference: str | None = None

    @field_validator("transaction_type")
    @classmethod
    def validate_transaction_type(cls, value: str) -> str:
        value = value.strip().lower()
        if value not in {"income", "expense"}:
            raise ValueError("transaction_type must be 'income' or 'expense'")
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
    transaction_type: str | None = None
    amount: float | None = Field(default=None, gt=0)
    category: str | None = Field(default=None, min_length=1)
    description: str | None = None
    transaction_date: date | None = None
    source: str | None = None
    reference: str | None = None

    @field_validator("transaction_type")
    @classmethod
    def validate_transaction_type(cls, value: str | None) -> str | None:
        if value is None:
            return value
        value = value.strip().lower()
        if value not in {"income", "expense"}:
            raise ValueError("transaction_type must be 'income' or 'expense'")
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
