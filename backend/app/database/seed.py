from app.database.mongodb import db
from app.core.security import hash_password, verify_password
from app.models.user import user_document
from app.models.business import business_document


def seed_default_data():
    try:
        user_email = "walishettar123@gmail.com"
        user = db.users.find_one({"email": user_email})
        if not user:
            new_user = user_document(
                name="vinayaka",
                email=user_email,
                password_hash=hash_password("password123"),
            )
            res = db.users.insert_one(new_user)
            user_id = str(res.inserted_id)
        else:
            user_id = str(user["_id"])
            if not verify_password("password123", user.get("password_hash", "")):
                db.users.update_one(
                    {"_id": user["_id"]},
                    {"$set": {"password_hash": hash_password("password123")}}
                )

        # Check or create default business entity if not present
        biz = db.businesses.find_one({"owner_id": user_id})
        if not biz:
            new_biz = business_document(
                name="VyaparAI Enterprise",
                business_type="Retail & Wholesale",
                owner_id=user_id,
            )
            db.businesses.insert_one(new_biz)
    except Exception as e:
        print(f"Notice: Seed default data encountered: {e}")
