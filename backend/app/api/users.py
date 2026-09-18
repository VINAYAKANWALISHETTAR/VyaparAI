from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.database.mongodb import db
from app.models.user import user_document
from app.core.security import hash_password

router = APIRouter(prefix="/users", tags=["Users"])


class UserCreate(BaseModel):
    name: str
    email: str
    password: str


@router.post("/")
def create_user(user: UserCreate):

    existing_user = db.users.find_one({
        "email": user.email
    })

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="User with this email already exists"
        )

    # Temporary for Phase 2.
    # Password hashing will be implemented in Phase 3.
    new_user = user_document(
        name=user.name,
        email=user.email,
        password_hash=hash_password(user.password)
    )

    result = db.users.insert_one(new_user)

    return {
        "message": "User created successfully",
        "user_id": str(result.inserted_id)
    }