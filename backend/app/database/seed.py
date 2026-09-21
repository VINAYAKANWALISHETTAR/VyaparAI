from datetime import datetime, timezone, timedelta
from app.database.mongodb import db
from app.core.security import hash_password, verify_password
from app.models.user import user_document
from app.models.business import business_document
from app.models.transaction import transaction_document


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
            user = db.users.find_one({"_id": res.inserted_id})
        else:
            user_id = str(user["_id"])
            if not verify_password("password123", user.get("password_hash", "")):
                db.users.update_one(
                    {"_id": user["_id"]},
                    {"$set": {"password_hash": hash_password("password123")}}
                )

        # Check or create business
        biz = db.businesses.find_one({"owner_id": user_id})
        if not biz:
            new_biz = business_document(
                name="VyaparAI Enterprise",
                business_type="Retail & Wholesale",
                owner_id=user_id,
            )
            res = db.businesses.insert_one(new_biz)
            biz_id = str(res.inserted_id)
        else:
            biz_id = str(biz["_id"])

        # Check if transactions exist
        tx_count = db.transactions.count_documents({"business_id": biz_id})
        if tx_count == 0:
            now = datetime.now(timezone.utc)
            today_morning_1 = now.replace(hour=7, minute=24, second=0, microsecond=0)
            today_morning_2 = now.replace(hour=6, minute=9, second=0, microsecond=0)
            today_morning_3 = now.replace(hour=8, minute=30, second=0, microsecond=0)
            yesterday = now - timedelta(days=1)
            yesterday_1 = yesterday.replace(hour=14, minute=30, second=0, microsecond=0)
            yesterday_2 = yesterday.replace(hour=10, minute=15, second=0, microsecond=0)

            sample_txs = [
                transaction_document(
                    business_id=biz_id,
                    type="income",
                    amount=8450.0,
                    category="Document - Invoice",
                    description="GST Tax Invoice - Krishna Traders",
                    date=today_morning_1,
                    source="ocr",
                    reference_id="INV-KT-7821",
                    user_id=user_id,
                ),
                transaction_document(
                    business_id=biz_id,
                    type="income",
                    amount=2100.0,
                    category="Voice Order",
                    description="Voice Order - 5x Rice Bags",
                    date=today_morning_2,
                    source="voice",
                    reference_id="VO-8912",
                    user_id=user_id,
                ),
                transaction_document(
                    business_id=biz_id,
                    type="expense",
                    amount=1250.0,
                    category="Utilities",
                    description="Electricity & Shop Maintenance",
                    date=today_morning_3,
                    source="manual",
                    reference_id="EXP-1092",
                    user_id=user_id,
                ),
                transaction_document(
                    business_id=biz_id,
                    type="expense",
                    amount=14200.0,
                    category="Document - Receipt",
                    description="Wholesale Purchase Receipt #882",
                    date=yesterday_1,
                    source="ocr",
                    reference_id="REC-882",
                    user_id=user_id,
                ),
                transaction_document(
                    business_id=biz_id,
                    type="income",
                    amount=5000.0,
                    category="Chat Alert",
                    description="WhatsApp Payment Alert - Suresh Gowda",
                    date=yesterday_2,
                    source="chat",
                    reference_id="WA-9041",
                    user_id=user_id,
                ),
            ]

            db.transactions.insert_many(sample_txs)
            print("Successfully seeded realistic starter business transactions into MongoDB")
    except Exception as e:
        print(f"Notice: Seed default data encountered: {e}")
