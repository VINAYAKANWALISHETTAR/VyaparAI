import re
import secrets
from datetime import datetime, timedelta, timezone
from bson import ObjectId
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr

from app.database.mongodb import db
from app.models.user import user_document
from app.models.business import business_document
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
)

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)


class LoginRequest(BaseModel):
    email: str
    password: str


class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str


@router.post("/login")
def login(data: LoginRequest):
    email = data.email.strip().lower()
    if not email or not data.password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email and password are required"
        )

    # Case-insensitive email query to match regardless of registration casing
    user = db.users.find_one({
        "email": {"$regex": f"^{re.escape(email)}$", "$options": "i"}
    })

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

    stored_hash = user.get("password_hash", "")
    if not verify_password(data.password, stored_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

    user_id = str(user["_id"])
    access_token = create_access_token(user_id)

    # Ensure user has at least one business record
    existing_biz = db.businesses.find_one({"owner_id": user_id})
    if not existing_biz:
        default_biz = business_document(
            name=f"{user.get('name', 'My Business')}'s Enterprise",
            business_type="Retail",
            owner_id=user_id,
        )
        db.businesses.insert_one(default_biz)

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user_id,
            "name": user.get("name", ""),
            "email": user.get("email", email),
        }
    }


@router.post("/register")
def register(data: RegisterRequest):
    email = data.email.strip().lower()
    name = data.name.strip()

    if not email or not data.password or not name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Name, email, and password are required"
        )

    if len(data.password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 6 characters long"
        )

    existing_user = db.users.find_one({
        "email": {"$regex": f"^{re.escape(email)}$", "$options": "i"}
    })

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists"
        )

    hashed_pw = hash_password(data.password)
    new_user = user_document(
        name=name,
        email=email,
        password_hash=hashed_pw
    )

    result = db.users.insert_one(new_user)
    user_id = str(result.inserted_id)

    # Auto-provision a default business for the user
    new_business = business_document(
        name=f"{name}'s Business",
        business_type="Retail & Services",
        owner_id=user_id,
    )
    db.businesses.insert_one(new_business)

    access_token = create_access_token(user_id)

    return {
        "message": "User registered successfully",
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user_id,
            "name": name,
            "email": email,
        }
    }


@router.post("/forgot-password")
def forgot_password(data: ForgotPasswordRequest):
    email = data.email.strip().lower()
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is required"
        )

    user = db.users.find_one({
        "email": {"$regex": f"^{re.escape(email)}$", "$options": "i"}
    })

    if not user:
        # Don't leak registered accounts, but return consistent message
        return {
            "message": f"If an account exists for {email}, password reset instructions have been generated.",
            "email": email
        }

    user_id = str(user["_id"])
    reset_token = secrets.token_urlsafe(32)
    expires_at = datetime.now(timezone.utc) + timedelta(hours=1)

    db.password_resets.delete_many({"user_id": user_id})
    db.password_resets.insert_one({
        "user_id": user_id,
        "token": reset_token,
        "email": email,
        "expires_at": expires_at,
        "used": False,
        "created_at": datetime.now(timezone.utc)
    })

    return {
        "message": f"Password reset instructions have been generated for {email}.",
        "reset_token": reset_token,
        "email": email
    }


@router.post("/reset-password")
def reset_password(data: ResetPasswordRequest):
    if not data.token or not data.new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token and new password are required"
        )

    if len(data.new_password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New password must be at least 6 characters long"
        )

    reset_record = db.password_resets.find_one({
        "token": data.token,
        "used": False
    })

    if not reset_record:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired password reset token"
        )

    # Check expiration
    expires_at = reset_record.get("expires_at")
    if expires_at:
        # Handle naive vs aware datetime if needed
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        if datetime.now(timezone.utc) > expires_at:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Reset token has expired. Please request a new one."
            )

    user_id = reset_record["user_id"]
    hashed_pw = hash_password(data.new_password)

    db.users.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": {"password_hash": hashed_pw}}
    )

    db.password_resets.update_one(
        {"_id": reset_record["_id"]},
        {"$set": {"used": True}}
    )

    return {
        "message": "Password has been successfully reset. You can now log in with your new password."
    }