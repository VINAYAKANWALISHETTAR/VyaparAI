import re
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from app.database.mongodb import db
from app.models.user import user_document
from app.models.business import business_document
from app.core.security import hash_password, create_access_token, get_current_user

router = APIRouter(prefix="/users", tags=["Users"])


class UserCreate(BaseModel):
    name: str
    email: str
    password: str


@router.post("/")
def create_user(user: UserCreate):
    email = user.email.strip().lower()
    name = user.name.strip()

    if not email or not user.password or not name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Name, email, and password are required"
        )

    if len(user.password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 6 characters long"
        )

    existing_user = db.users.find_one({
        "email": {"$regex": f"^{re.escape(email)}$", "$options": "i"}
    })

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="User with this email already exists"
        )

    new_user = user_document(
        name=name,
        email=email,
        password_hash=hash_password(user.password)
    )

    result = db.users.insert_one(new_user)
    user_id = str(result.inserted_id)

    # Auto-provision a default business for the user
    new_biz = business_document(
        name=f"{name}'s Business",
        business_type="Retail & Services",
        owner_id=user_id,
    )
    db.businesses.insert_one(new_biz)

    access_token = create_access_token(user_id)

    return {
        "message": "User created successfully",
        "user_id": user_id,
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user_id,
            "name": name,
            "email": email,
        }
    }


@router.get("/me")
def get_current_user_profile(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])
    user_name = current_user.get("name") or "User"
    biz = db.businesses.find_one({"owner_id": user_id})
    biz_name = biz.get("name") if biz else f"{user_name}'s Business"

    return {
        "id": user_id,
        "name": user_name,
        "email": current_user.get("email", ""),
        "business_name": biz_name,
        "phone": current_user.get("phone", ""),
        "created_at": str(current_user.get("created_at", "")),
    }