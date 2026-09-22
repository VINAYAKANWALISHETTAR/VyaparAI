from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
import math

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.security import get_current_user
from app.database.mongodb import db
from app.models.transaction import transaction_document
from app.schemas.transaction import TransactionCreate, TransactionResponse, TransactionUpdate
from app.services.notification_service import notification_service
from app.services.financial_service import financial_service


router = APIRouter(
    prefix="/transactions",
    tags=["Transactions"],
)


def validate_object_id(value: str, field_name: str) -> ObjectId:
    try:
        return ObjectId(value)
    except Exception:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid {field_name}",
        )


def get_user_business_ids(user_id: str) -> list[str]:
    businesses = db.businesses.find({"owner_id": user_id})
    return [str(b["_id"]) for b in businesses]


def verify_transaction_ownership(transaction: dict, current_user: dict, business_ids: list[str]) -> bool:
    user_id = str(current_user["_id"])
    if transaction.get("user_id") == user_id:
        return True
    if transaction.get("business_id") in business_ids:
        return True
    return False


def serialize_transaction(transaction: dict) -> dict:
    amount = float(transaction.get("amount", 0.0))
    if math.isnan(amount) or math.isinf(amount):
        amount = 0.0

    return {
        "id": str(transaction["_id"]),
        "business_id": str(transaction.get("business_id", "")),
        "user_id": transaction.get("user_id"),
        "type": transaction.get("type", "income"),
        "amount": round(amount, 2),
        "category": transaction.get("category", "General"),
        "description": transaction.get("description"),
        "date": transaction["date"].isoformat() if transaction.get("date") else None,
        "currency": transaction.get("currency", "INR"),
        "source": transaction.get("source", "manual"),
        "reference_id": transaction.get("reference_id"),
        "created_at": transaction["created_at"].isoformat() if transaction.get("created_at") else None,
        "updated_at": transaction["updated_at"].isoformat() if transaction.get("updated_at") else None,
    }


@router.get("/summary")
def get_transaction_summary(
    current_user=Depends(get_current_user),
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
):
    user_id = str(current_user["_id"])
    business_ids = get_user_business_ids(user_id)

    match_query: dict = {
        "$or": [
            {"business_id": {"$in": business_ids}},
            {"user_id": user_id},
        ]
    }

    if start_date or end_date:
        date_query = {}
        if start_date:
            date_query["$gte"] = datetime.combine(
                start_date, datetime.min.time()
            ).replace(tzinfo=timezone.utc)
        if end_date:
            date_query["$lte"] = datetime.combine(
                end_date, datetime.max.time()
            ).replace(tzinfo=timezone.utc)
        match_query["date"] = date_query

    pipeline = [
        {"$match": match_query},
        {
            "$group": {
                "_id": "$type",
                "total_amount": {"$sum": "$amount"},
                "count": {"$sum": 1},
            }
        },
    ]

    results = list(db.transactions.aggregate(pipeline))

    totals = {"income": Decimal("0"), "expense": Decimal("0")}
    transaction_count = 0

    for result in results:
        txn_type = str(result["_id"]).lower()
        amount = Decimal(str(result["total_amount"]))
        count = result["count"]

        if txn_type in totals:
            totals[txn_type] = amount

        transaction_count += count

    total_income = float(totals["income"])
    total_expense = float(totals["expense"])
    current_balance = total_income - total_expense

    return {
        "total_income": round(total_income, 2),
        "total_expenses": round(total_expense, 2),
        "current_balance": round(current_balance, 2),
        "transaction_count": transaction_count,
    }


@router.get("/")
def get_transactions(
    current_user=Depends(get_current_user),
    business_id: str | None = Query(default=None),
    type: str | None = Query(default=None, alias="type"),
    category: str | None = Query(default=None),
    source: str | None = Query(default=None),
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    limit: int = Query(default=100, ge=1, le=500),
):
    user_id = str(current_user["_id"])
    business_ids = get_user_business_ids(user_id)

    query: dict = {
        "$or": [
            {"business_id": {"$in": business_ids}},
            {"user_id": user_id},
        ]
    }

    if business_id:
        business_object_id = validate_object_id(business_id, "business_id")
        if str(business_object_id) not in business_ids:
            raise HTTPException(
                status_code=404,
                detail="Business not found or access denied",
            )
        query = {"business_id": str(business_object_id)}

    if type and type.strip().lower() != "all":
        query["type"] = type.strip().lower()

    if category and category.strip():
        query["category"] = category.strip()

    if source and source.strip():
        query["source"] = source.strip().lower()

    if start_date or end_date:
        date_query = {}
        if start_date:
            date_query["$gte"] = datetime.combine(
                start_date, datetime.min.time()
            ).replace(tzinfo=timezone.utc)
        if end_date:
            date_query["$lte"] = datetime.combine(
                end_date, datetime.max.time()
            ).replace(tzinfo=timezone.utc)
        query["date"] = date_query

    transactions = db.transactions.find(query).sort("date", -1).limit(limit)
    return [serialize_transaction(transaction) for transaction in transactions]


@router.get("/{transaction_id}")
def get_transaction(
    transaction_id: str,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    transaction_object_id = validate_object_id(transaction_id, "transaction_id")
    transaction = db.transactions.find_one({"_id": transaction_object_id})

    if not transaction:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found",
        )

    business_ids = get_user_business_ids(user_id)
    if not verify_transaction_ownership(transaction, current_user, business_ids):
        raise HTTPException(
            status_code=403,
            detail="Access denied to this transaction",
        )

    return serialize_transaction(transaction)


@router.post("/", status_code=status.HTTP_201_CREATED, response_model=TransactionResponse)
def create_transaction(
    transaction: TransactionCreate,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    business_ids = get_user_business_ids(user_id)

    if not transaction.business_id:
        if not business_ids:
            from app.models.business import business_document
            default_biz = business_document(
                name="Vyapar Business",
                business_type="Retail",
                owner_id=user_id,
            )
            res = db.businesses.insert_one(default_biz)
            transaction.business_id = str(res.inserted_id)
            business_ids = [transaction.business_id]
        else:
            transaction.business_id = business_ids[0]
    else:
        if transaction.business_id not in business_ids:
            raise HTTPException(
                status_code=403,
                detail="Business not found or access denied",
            )

    # 1. Idempotency / Reference duplicate protection
    dedup_ref = transaction.reference_id or transaction.idempotency_key
    if dedup_ref:
        existing_ref = db.transactions.find_one({
            "$or": [{"user_id": user_id}, {"business_id": transaction.business_id}],
            "reference_id": dedup_ref,
        })
        if existing_ref:
            raise HTTPException(
                status_code=409,
                detail="Duplicate transaction with this reference ID already exists",
            )

    # 2. Window duplicate protection (prevent double-clicks & instant retries within 5s)
    five_secs_ago = datetime.now(timezone.utc) - timedelta(seconds=5)
    existing_window = db.transactions.find_one({
        "user_id": user_id,
        "type": transaction.type,
        "amount": round(transaction.amount, 2),
        "category": transaction.category,
        "created_at": {"$gte": five_secs_ago},
    })
    if existing_window:
        raise HTTPException(
            status_code=409,
            detail="Duplicate transaction detected within deduplication window",
        )

    new_transaction = transaction_document(
        business_id=transaction.business_id,
        type=transaction.type,
        amount=transaction.amount,
        category=transaction.category,
        description=transaction.description,
        date=transaction.date,
        currency=transaction.currency,
        source=transaction.source,
        reference_id=dedup_ref,
        user_id=user_id,
    )

    result = db.transactions.insert_one(new_transaction)
    created_transaction = db.transactions.find_one({"_id": result.inserted_id})
    financial_service.invalidate_report_cache(user_id)

    # Trigger real transaction notification
    try:
        type_label = "Sale" if transaction.type == "income" else "Expense"
        notification_service.create_notification(
            user_id=user_id,
            business_id=transaction.business_id,
            notification_type="transaction_created",
            title=f"{type_label} of ₹{transaction.amount:,.0f} recorded",
            message=f"{transaction.category}: {transaction.description or 'Transaction successfully added to ledger.'}",
            data={
                "transaction_id": str(result.inserted_id),
                "amount": transaction.amount,
                "type": transaction.type,
            },
        )
    except Exception:
        pass

    return serialize_transaction(created_transaction)


@router.put("/{transaction_id}", response_model=TransactionResponse)
def update_transaction(
    transaction_id: str,
    transaction_data: TransactionUpdate,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    transaction_object_id = validate_object_id(transaction_id, "transaction_id")

    transaction = db.transactions.find_one({"_id": transaction_object_id})
    if not transaction:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found",
        )

    business_ids = get_user_business_ids(user_id)
    if not verify_transaction_ownership(transaction, current_user, business_ids):
        raise HTTPException(
            status_code=403,
            detail="Access denied to this transaction",
        )

    update_data = {
        key: value
        for key, value in transaction_data.model_dump().items()
        if value is not None
    }

    if not update_data:
        raise HTTPException(
            status_code=400,
            detail="No fields provided for update",
        )

    if "amount" in update_data:
        update_data["amount"] = round(float(update_data["amount"]), 2)

    if "date" in update_data:
        d = update_data["date"]
        if isinstance(d, date) and not isinstance(d, datetime):
            update_data["date"] = datetime.combine(d, datetime.min.time()).replace(tzinfo=timezone.utc)

    update_data["updated_at"] = datetime.now(timezone.utc)

    db.transactions.update_one(
        {"_id": transaction_object_id},
        {"$set": update_data},
    )
    financial_service.invalidate_report_cache(user_id)

    updated_transaction = db.transactions.find_one({"_id": transaction_object_id})
    return serialize_transaction(updated_transaction)


@router.delete("/{transaction_id}")
def delete_transaction(
    transaction_id: str,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    transaction_object_id = validate_object_id(transaction_id, "transaction_id")

    transaction = db.transactions.find_one({"_id": transaction_object_id})
    if not transaction:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found",
        )

    business_ids = get_user_business_ids(user_id)
    if not verify_transaction_ownership(transaction, current_user, business_ids):
        raise HTTPException(
            status_code=403,
            detail="Access denied to this transaction",
        )

    result = db.transactions.delete_one({"_id": transaction_object_id})
    if result.deleted_count == 0:
        raise HTTPException(
            status_code=500,
            detail="Failed to delete transaction from database",
        )

    financial_service.invalidate_report_cache(user_id)

    return {
        "message": "Transaction deleted successfully",
        "id": transaction_id,
    }
