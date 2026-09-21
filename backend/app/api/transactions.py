from datetime import date, datetime, timezone
from decimal import Decimal

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.security import get_current_user
from app.database.mongodb import db
from app.models.transaction import transaction_document
from app.schemas.transaction import TransactionCreate, TransactionResponse, TransactionUpdate


router = APIRouter(
    prefix="/transactions",
    tags=["Transactions"],
)


def validate_object_id(value: str, field_name: str):
    try:
        return ObjectId(value)
    except Exception:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid {field_name}",
        )


def verify_business_ownership(business_id: str, current_user):
    business_object_id = validate_object_id(business_id, "business_id")

    business = db.businesses.find_one({
        "_id": business_object_id,
        "owner_id": str(current_user["_id"]),
    })

    if not business:
        raise HTTPException(
            status_code=404,
            detail="Business not found or access denied",
        )

    return business


def serialize_transaction(transaction):
    return {
        "id": str(transaction["_id"]),
        "business_id": transaction["business_id"],
        "user_id": transaction.get("user_id"),
        "type": transaction["type"],
        "amount": float(transaction["amount"]),
        "category": transaction["category"],
        "description": transaction.get("description"),
        "date": transaction["date"].isoformat()
        if transaction.get("date")
        else None,
        "source": transaction.get("source"),
        "reference_id": transaction.get("reference_id"),
        "created_at": transaction["created_at"].isoformat()
        if transaction.get("created_at")
        else None,
        "updated_at": transaction["updated_at"].isoformat()
        if transaction.get("updated_at")
        else None,
    }


@router.get("/summary")
def get_transaction_summary(
    current_user=Depends(get_current_user),
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
):
    user_id = str(current_user["_id"])

    businesses = db.businesses.find({"owner_id": user_id})
    business_ids = [str(business["_id"]) for business in businesses]

    match_query = {"business_id": {"$in": business_ids}}

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
        }
    ]

    results = list(db.transactions.aggregate(pipeline))

    totals = {"income": Decimal("0"), "expense": Decimal("0")}
    transaction_count = 0

    for result in results:
        txn_type = result["_id"]
        amount = Decimal(str(result["total_amount"]))
        count = result["count"]

        if txn_type in totals:
            totals[txn_type] = amount

        transaction_count += count

    total_income = float(totals["income"])
    total_expense = float(totals["expense"])
    current_balance = total_income - total_expense

    return {
        "total_income": total_income,
        "total_expenses": total_expense,
        "current_balance": current_balance,
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
):
    user_id = str(current_user["_id"])

    businesses = db.businesses.find({"owner_id": user_id})
    business_ids = [str(business["_id"]) for business in businesses]

    query = {"business_id": {"$in": business_ids}}

    if business_id:
        business_object_id = validate_object_id(business_id, "business_id")
        if str(business_object_id) not in business_ids:
            raise HTTPException(
                status_code=404,
                detail="Business not found or access denied",
            )
        query["business_id"] = str(business_object_id)

    if type:
        query["type"] = type.strip().lower()

    if category:
        query["category"] = category.strip()

    if source:
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

    transactions = db.transactions.find(query)

    return [serialize_transaction(transaction) for transaction in transactions]


@router.get("/{transaction_id}")
def get_transaction(
    transaction_id: str,
    current_user=Depends(get_current_user),
):
    transaction_object_id = validate_object_id(transaction_id, "transaction_id")

    transaction = db.transactions.find_one({"_id": transaction_object_id})

    if not transaction:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found",
        )

    verify_business_ownership(transaction["business_id"], current_user)

    return serialize_transaction(transaction)


@router.post("/", status_code=status.HTTP_201_CREATED, response_model=TransactionResponse)
def create_transaction(
    transaction: TransactionCreate,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    if not transaction.business_id:
        from app.models.business import business_document
        businesses = list(db.businesses.find({"owner_id": user_id}))
        if not businesses:
            default_biz = business_document(
                name="Vyapar Business",
                business_type="Retail",
                owner_id=user_id,
            )
            res = db.businesses.insert_one(default_biz)
            transaction.business_id = str(res.inserted_id)
        else:
            transaction.business_id = str(businesses[0]["_id"])
    else:
        verify_business_ownership(transaction.business_id, current_user)

    new_transaction = transaction_document(
        business_id=transaction.business_id,
        type=transaction.type,
        amount=transaction.amount,
        category=transaction.category,
        description=transaction.description,
        date=transaction.date,
        source=transaction.source,
        reference_id=transaction.reference_id,
        user_id=str(current_user["_id"]),
    )

    result = db.transactions.insert_one(new_transaction)

    created_transaction = db.transactions.find_one({
        "_id": result.inserted_id
    })

    return serialize_transaction(created_transaction)


@router.put("/{transaction_id}", response_model=TransactionResponse)
def update_transaction(
    transaction_id: str,
    transaction_data: TransactionUpdate,
    current_user=Depends(get_current_user),
):
    transaction_object_id = validate_object_id(transaction_id, "transaction_id")

    transaction = db.transactions.find_one({"_id": transaction_object_id})

    if not transaction:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found",
        )

    verify_business_ownership(transaction["business_id"], current_user)

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

    if "date" in update_data:
        update_data["date"] = datetime.combine(
            update_data["date"],
            datetime.min.time(),
        ).replace(tzinfo=timezone.utc)

    update_data["updated_at"] = datetime.now(timezone.utc)

    db.transactions.update_one(
        {"_id": transaction_object_id},
        {"$set": update_data},
    )

    updated_transaction = db.transactions.find_one({"_id": transaction_object_id})

    return serialize_transaction(updated_transaction)


@router.delete("/{transaction_id}")
def delete_transaction(
    transaction_id: str,
    current_user=Depends(get_current_user),
):
    transaction_object_id = validate_object_id(transaction_id, "transaction_id")

    transaction = db.transactions.find_one({"_id": transaction_object_id})

    if not transaction:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found",
        )

    verify_business_ownership(transaction["business_id"], current_user)

    db.transactions.delete_one({"_id": transaction_object_id})

    return {
        "message": "Transaction deleted successfully"
    }
