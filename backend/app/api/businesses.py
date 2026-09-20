from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from bson import ObjectId

from app.database.mongodb import db
from app.models.business import business_document
from app.core.security import get_current_user

router = APIRouter(
    prefix="/businesses",
    tags=["Businesses"]
)


class BusinessCreate(BaseModel):
    name: str
    business_type: str

@router.post("/")
def create_business(
    business: BusinessCreate,
    current_user=Depends(get_current_user)
):

    new_business = business_document(
        name=business.name,
        business_type=business.business_type,
        owner_id=str(current_user["_id"])
    )

    result = db.businesses.insert_one(new_business)

    return {
        "message": "Business created successfully",
        "business_id": str(result.inserted_id)
    }


@router.get("/")
def get_user_businesses(current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])
    businesses = list(db.businesses.find({"owner_id": user_id}))
    if not businesses:
        default_biz = business_document(
            name="Vyapar Business",
            business_type="Retail",
            owner_id=user_id,
        )
        res = db.businesses.insert_one(default_biz)
        default_biz["_id"] = res.inserted_id
        businesses = [default_biz]

    return [
        {
            "id": str(b["_id"]),
            "name": b.get("name", "Vyapar Business"),
            "business_type": b.get("business_type", "Retail"),
        }
        for b in businesses
    ]