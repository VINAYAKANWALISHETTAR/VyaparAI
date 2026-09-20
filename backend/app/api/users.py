from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.database.mongodb import db
from app.models.user import user_document
from app.core.security import hash_password, get_current_user

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


@router.get("/me")
def get_current_user_profile(current_user=Depends(get_current_user)):
    return {
        "id": str(current_user["_id"]),
        "name": current_user.get("name", ""),
        "email": current_user.get("email", ""),
        "business_name": current_user.get("business_name", ""),
        "phone": current_user.get("phone", ""),
        "created_at": str(current_user.get("created_at", "")),
    }