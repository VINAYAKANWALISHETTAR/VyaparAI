import time
from calendar import monthrange
from datetime import date, datetime, timezone, timedelta
from typing import Optional

from bson import ObjectId
from app.database.mongodb import db


class FinancialService:
    _overview_cache: dict[str, tuple[float, dict]] = {}

    def invalidate_report_cache(self, user_id: str | None = None) -> None:
        if not user_id:
            self._overview_cache.clear()
            return
        keys_to_del = [k for k in self._overview_cache if k.startswith(f"{user_id}_")]
        for k in keys_to_del:
            self._overview_cache.pop(k, None)

    def _get_date_range(
        self,
        period: str,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
        tz_offset_minutes: int = 330,  # Default IST (+5:30)
    ) -> tuple[Optional[datetime], Optional[datetime]]:
        # Compute current local time of the user
        tz_delta = timedelta(minutes=tz_offset_minutes)
        local_now = datetime.now(timezone.utc) + tz_delta
        today = local_now.date()

        p = (period or "month").strip().lower()

        if p in ("all", "all_time"):
            return None, None

        if p == "custom":
            if not start_date and not end_date:
                return None, None
            start = None
            end = None
            if start_date:
                # Combine with local start of day, subtract offset to get UTC
                start_local = datetime.combine(start_date, datetime.min.time())
                start = (start_local - tz_delta).replace(tzinfo=timezone.utc)
            if end_date:
                end_local = datetime.combine(end_date, datetime.max.time())
                end = (end_local - tz_delta).replace(tzinfo=timezone.utc)
            return start, end

        if p == "today":
            start_local = datetime.combine(today, datetime.min.time())
            end_local = datetime.combine(today, datetime.max.time())
        elif p == "yesterday":
            yest = today - timedelta(days=1)
            start_local = datetime.combine(yest, datetime.min.time())
            end_local = datetime.combine(yest, datetime.max.time())
        elif p in ("week", "this_week"):
            start_d = today - timedelta(days=today.weekday())
            end_d = start_d + timedelta(days=6)
            start_local = datetime.combine(start_d, datetime.min.time())
            end_local = datetime.combine(end_d, datetime.max.time())
        elif p in ("month", "this_month"):
            start_d = today.replace(day=1)
            last_day = monthrange(today.year, today.month)[1]
            end_d = today.replace(day=last_day)
            start_local = datetime.combine(start_d, datetime.min.time())
            end_local = datetime.combine(end_d, datetime.max.time())
        elif p in ("previous_month", "last_month", "prev_month"):
            first_of_this_month = today.replace(day=1)
            last_day_prev_month = first_of_this_month - timedelta(days=1)
            first_day_prev_month = last_day_prev_month.replace(day=1)
            start_local = datetime.combine(first_day_prev_month, datetime.min.time())
            end_local = datetime.combine(last_day_prev_month, datetime.max.time())
        elif p in ("year", "this_year"):
            start_d = date(today.year, 1, 1)
            end_d = date(today.year, 12, 31)
            start_local = datetime.combine(start_d, datetime.min.time())
            end_local = datetime.combine(end_d, datetime.max.time())
        else:
            # Fallback to month
            start_d = today.replace(day=1)
            last_day = monthrange(today.year, today.month)[1]
            end_d = today.replace(day=last_day)
            start_local = datetime.combine(start_d, datetime.min.time())
            end_local = datetime.combine(end_d, datetime.max.time())

        start = (start_local - tz_delta).replace(tzinfo=timezone.utc)
        end = (end_local - tz_delta).replace(tzinfo=timezone.utc)
        return start, end

    def _get_user_business_ids(self, user_id: str) -> list[str]:
        businesses = db.businesses.find({"owner_id": user_id})
        return [str(business["_id"]) for business in businesses]

    def _verify_business_access(self, business_id: str, user_id: str):
        business_ids = self._get_user_business_ids(user_id)
        if business_id not in business_ids:
            raise ValueError("Business not found or access denied")
        return business_id

    def get_income(
        self,
        business_id: str | None,
        period: str,
        user_id: str,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ):
        business_ids = self._get_user_business_ids(user_id)
        if business_id:
            self._verify_business_access(business_id, user_id)
            business_ids = [business_id]

        start, end = self._get_date_range(period, start_date=start_date, end_date=end_date)

        match_query: dict = {
            "$or": [
                {"business_id": {"$in": business_ids}},
                {"user_id": user_id},
            ],
            "type": "income",
        }

        if start and end:
            match_query["date"] = {"$gte": start, "$lte": end}
        elif start:
            match_query["date"] = {"$gte": start}
        elif end:
            match_query["date"] = {"$lte": end}

        pipeline = [
            {"$match": match_query},
            {
                "$group": {
                    "_id": "$category",
                    "amount": {"$sum": "$amount"},
                    "count": {"$sum": 1},
                }
            },
        ]

        results = list(db.transactions.aggregate(pipeline))
        total_income = sum(float(r["amount"]) for r in results)
        transaction_count = sum(r["count"] for r in results)
        breakdown = [
            {"category": r["_id"] or "General", "amount": round(float(r["amount"]), 2), "count": r["count"]}
            for r in results
        ]

        return {
            "period": period,
            "total_income": round(total_income, 2),
            "transaction_count": transaction_count,
            "breakdown": breakdown,
        }

    def get_expenses(
        self,
        business_id: str | None,
        period: str,
        user_id: str,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ):
        business_ids = self._get_user_business_ids(user_id)
        if business_id:
            self._verify_business_access(business_id, user_id)
            business_ids = [business_id]

        start, end = self._get_date_range(period, start_date=start_date, end_date=end_date)

        match_query: dict = {
            "$or": [
                {"business_id": {"$in": business_ids}},
                {"user_id": user_id},
            ],
            "type": "expense",
        }

        if start and end:
            match_query["date"] = {"$gte": start, "$lte": end}
        elif start:
            match_query["date"] = {"$gte": start}
        elif end:
            match_query["date"] = {"$lte": end}

        pipeline = [
            {"$match": match_query},
            {
                "$group": {
                    "_id": "$category",
                    "amount": {"$sum": "$amount"},
                    "count": {"$sum": 1},
                }
            },
        ]

        results = list(db.transactions.aggregate(pipeline))
        total_expenses = sum(float(r["amount"]) for r in results)
        transaction_count = sum(r["count"] for r in results)
        breakdown = [
            {"category": r["_id"] or "General", "amount": round(float(r["amount"]), 2), "count": r["count"]}
            for r in results
        ]

        return {
            "period": period,
            "total_expenses": round(total_expenses, 2),
            "transaction_count": transaction_count,
            "breakdown": breakdown,
        }

    def get_profit(
        self,
        business_id: str | None,
        period: str,
        user_id: str,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ):
        income = self.get_income(business_id, period, user_id, start_date=start_date, end_date=end_date)
        expenses = self.get_expenses(business_id, period, user_id, start_date=start_date, end_date=end_date)
        profit = round(income["total_income"] - expenses["total_expenses"], 2)

        return {
            "period": period,
            "total_income": income["total_income"],
            "total_expenses": expenses["total_expenses"],
            "profit": profit,
            "transaction_count": income["transaction_count"] + expenses["transaction_count"],
        }

    def get_report_overview(
        self,
        business_id: str | None,
        period: str,
        user_id: str,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ) -> dict:
        business_ids = self._get_user_business_ids(user_id)
        if business_id:
            try:
                self._verify_business_access(business_id, user_id)
                business_ids = [business_id]
            except Exception:
                pass

        cache_key = f"{user_id}_{business_id or 'all'}_{period}_{start_date}_{end_date}"
        cached = self._overview_cache.get(cache_key)
        now_ts = time.time()
        if cached and (now_ts - cached[0] < 20.0):
            return cached[1]

        start, end = self._get_date_range(period, start_date=start_date, end_date=end_date)

        match_query: dict = {
            "$or": [
                {"business_id": {"$in": business_ids}},
                {"user_id": user_id},
            ],
        }
        if start and end:
            match_query["date"] = {"$gte": start, "$lte": end}
        elif start:
            match_query["date"] = {"$gte": start}
        elif end:
            match_query["date"] = {"$lte": end}

        pipeline = [
            {"$match": match_query},
            {
                "$group": {
                    "_id": {"type": "$type", "category": "$category"},
                    "amount": {"$sum": "$amount"},
                    "count": {"$sum": 1},
                }
            },
        ]

        results = list(db.transactions.aggregate(pipeline))

        total_income = 0.0
        total_expenses = 0.0
        income_breakdown = []
        expense_breakdown = []

        for r in results:
            t = (r["_id"].get("type") or "income").lower()
            cat = r["_id"].get("category") or "General"
            amt = round(float(r["amount"]), 2)
            cnt = int(r["count"])

            if t == "income":
                total_income += amt
                income_breakdown.append({"category": cat, "amount": amt, "count": cnt})
            else:
                total_expenses += amt
                expense_breakdown.append({"category": cat, "amount": amt, "count": cnt})

        # Also get recent transactions for chart points
        recent_txns = list(
            db.transactions.find(match_query)
            .sort("date", -1)
            .limit(100)
        )
        serialized_txns = []
        for tx in recent_txns:
            serialized_txns.append({
                "id": str(tx["_id"]),
                "business_id": str(tx.get("business_id", "")),
                "type": tx.get("type", "income"),
                "amount": float(tx.get("amount", 0.0)),
                "category": tx.get("category", "General"),
                "description": tx.get("description", ""),
                "date": tx.get("date").isoformat() if tx.get("date") else None,
                "source": tx.get("source"),
            })

        net_profit = round(total_income - total_expenses, 2)
        total_income = round(total_income, 2)
        total_expenses = round(total_expenses, 2)
        total_count = sum(item["count"] for item in income_breakdown) + sum(item["count"] for item in expense_breakdown)

        result = {
            "period": period,
            "total_income": total_income,
            "total_expenses": total_expenses,
            "net_profit": net_profit,
            "transaction_count": total_count,
            "income_breakdown": income_breakdown,
            "expense_breakdown": expense_breakdown,
            "transactions": serialized_txns,
        }
        self._overview_cache[cache_key] = (now_ts, result)
        return result

    def get_receivables(self, business_id: str | None, user_id: str, overdue_only: bool = False, customer_id: str | None = None):
        business_ids = self._get_user_business_ids(user_id)
        if business_id:
            self._verify_business_access(business_id, user_id)
            business_ids = [business_id]

        query: dict = {
            "$or": [
                {"business_id": {"$in": business_ids}},
                {"user_id": user_id},
            ],
            "outstanding_amount": {"$gt": 0},
        }

        if customer_id:
            query["customer_name"] = customer_id

        invoices = db.invoices.find(query)

        today = date.today()
        invoice_list = []
        total_receivables = 0.0
        overdue_amount = 0.0

        for invoice in invoices:
            amount = float(invoice["amount"])
            paid_amount = float(invoice.get("paid_amount", 0))
            outstanding = float(invoice.get("outstanding_amount", amount - paid_amount))
            due_date = invoice.get("due_date")

            if hasattr(due_date, "date"):
                due_date = due_date.date()

            days_overdue = None
            status = invoice.get("status", "unpaid")

            if due_date and due_date < today and outstanding > 0:
                days_overdue = (today - due_date).days
                status = "overdue"
            else:
                if status == "overdue":
                    status = "unpaid"

            if overdue_only and status != "overdue":
                continue

            total_receivables += outstanding
            if status == "overdue":
                overdue_amount += outstanding

            invoice_list.append({
                "id": str(invoice["_id"]),
                "invoice_number": invoice.get("invoice_number"),
                "customer_name": invoice["customer_name"],
                "amount": amount,
                "paid_amount": paid_amount,
                "outstanding_amount": outstanding,
                "due_date": due_date.isoformat() if due_date else None,
                "status": status,
                "days_overdue": days_overdue,
            })

        return {
            "total_receivables": round(total_receivables, 2),
            "overdue_amount": round(overdue_amount, 2),
            "invoices": invoice_list,
        }

    def get_liabilities(self, user_id: str, business_id: str | None = None, upcoming_only: bool = False, overdue_only: bool = False):
        business_ids = self._get_user_business_ids(user_id)
        if business_id:
            self._verify_business_access(business_id, user_id)
            business_ids = [business_id]

        query: dict = {
            "$or": [
                {"business_id": {"$in": business_ids}},
                {"user_id": user_id},
            ],
            "type": "expense",
        }

        transactions = db.transactions.find(query)

        today = date.today()
        obligations = []
        total_liabilities = 0.0
        upcoming_amount = 0.0
        overdue_amount = 0.0

        for txn in transactions:
            txn_date = txn.get("date")
            if hasattr(txn_date, "date"):
                txn_date = txn_date.date()

            amount = float(txn["amount"])
            days_until_due = None
            status = "upcoming"

            if txn_date:
                if txn_date < today:
                    status = "overdue"
                    days_until_due = (txn_date - today).days
                else:
                    days_until_due = (txn_date - today).days

            if overdue_only and status != "overdue":
                continue
            if upcoming_only and status != "upcoming":
                continue

            total_liabilities += amount
            if status == "upcoming":
                upcoming_amount += amount
            if status == "overdue":
                overdue_amount += amount

            obligations.append({
                "id": str(txn["_id"]),
                "description": txn.get("description") or txn.get("category", "expense"),
                "amount": amount,
                "due_date": txn_date.isoformat() if txn_date else None,
                "status": status,
                "days_until_due": days_until_due,
            })

        return {
            "total_liabilities": round(total_liabilities, 2),
            "upcoming_amount": round(upcoming_amount, 2),
            "overdue_amount": round(overdue_amount, 2),
            "obligations": obligations,
        }

    def get_cash_position(self, user_id: str):
        business_ids = self._get_user_business_ids(user_id)

        match_scope = {
            "$or": [
                {"business_id": {"$in": business_ids}},
                {"user_id": user_id},
            ]
        }

        income_pipeline = [
            {"$match": {**match_scope, "type": "income"}},
            {"$group": {"_id": None, "total": {"$sum": "$amount"}}},
        ]
        income_result = list(db.transactions.aggregate(income_pipeline))
        total_income = float(income_result[0]["total"]) if income_result else 0.0

        expense_pipeline = [
            {"$match": {**match_scope, "type": "expense"}},
            {"$group": {"_id": None, "total": {"$sum": "$amount"}}},
        ]
        expense_result = list(db.transactions.aggregate(expense_pipeline))
        total_expenses = float(expense_result[0]["total"]) if expense_result else 0.0

        net_cash_flow = total_income - total_expenses
        recorded_cash_position = net_cash_flow

        receivables = db.invoices.find({
            "$or": [
                {"business_id": {"$in": business_ids}},
                {"user_id": user_id},
            ],
            "outstanding_amount": {"$gt": 0},
        })
        pending_receivables = sum(float(inv.get("outstanding_amount", 0)) for inv in receivables)

        liabilities_result = self.get_liabilities(user_id, upcoming_only=True)
        pending_liabilities = liabilities_result["upcoming_amount"]

        available_cash = recorded_cash_position + pending_receivables - pending_liabilities

        return {
            "recorded_cash_position": round(recorded_cash_position, 2),
            "total_income": round(total_income, 2),
            "total_expenses": round(total_expenses, 2),
            "net_cash_flow": round(net_cash_flow, 2),
            "pending_receivables": round(pending_receivables, 2),
            "pending_liabilities": round(pending_liabilities, 2),
            "available_cash": round(available_cash, 2),
        }


financial_service = FinancialService()
