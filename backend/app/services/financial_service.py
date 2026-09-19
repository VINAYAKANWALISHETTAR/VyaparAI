from calendar import monthrange
from datetime import date, datetime, timezone, timedelta

from bson import ObjectId
from app.database.mongodb import db


class FinancialService:
    def _get_date_range(self, period: str):
        today = date.today()

        if period == "today":
            start = datetime.combine(today, datetime.min.time()).replace(tzinfo=timezone.utc)
            end = datetime.combine(today, datetime.max.time()).replace(tzinfo=timezone.utc)
        elif period == "week":
            start_date = today - timedelta(days=today.weekday())
            end_date = start_date + timedelta(days=6)
            start = datetime.combine(start_date, datetime.min.time()).replace(tzinfo=timezone.utc)
            end = datetime.combine(end_date, datetime.max.time()).replace(tzinfo=timezone.utc)
        elif period == "month":
            start_date = today.replace(day=1)
            last_day = monthrange(today.year, today.month)[1]
            end_date = today.replace(day=last_day)
            start = datetime.combine(start_date, datetime.min.time()).replace(tzinfo=timezone.utc)
            end = datetime.combine(end_date, datetime.max.time()).replace(tzinfo=timezone.utc)
        else:
            raise ValueError("Invalid period")

        return start, end

    def _get_user_business_ids(self, user_id: str):
        businesses = db.businesses.find({"owner_id": user_id})
        return [str(business["_id"]) for business in businesses]

    def _verify_business_access(self, business_id: str, user_id: str):
        business_ids = self._get_user_business_ids(user_id)
        if business_id not in business_ids:
            raise ValueError("Business not found or access denied")
        return business_id

    def get_income(self, business_id: str | None, period: str, user_id: str):
        business_ids = self._get_user_business_ids(user_id)
        if business_id:
            self._verify_business_access(business_id, user_id)
            business_ids = [business_id]

        start, end = self._get_date_range(period)

        pipeline = [
            {
                "$match": {
                    "business_id": {"$in": business_ids},
                    "type": "income",
                    "date": {"$gte": start, "$lte": end},
                }
            },
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
            {"category": r["_id"], "amount": float(r["amount"]), "count": r["count"]}
            for r in results
        ]

        return {
            "period": period,
            "total_income": total_income,
            "transaction_count": transaction_count,
            "breakdown": breakdown,
        }

    def get_expenses(self, business_id: str | None, period: str, user_id: str):
        business_ids = self._get_user_business_ids(user_id)
        if business_id:
            self._verify_business_access(business_id, user_id)
            business_ids = [business_id]

        start, end = self._get_date_range(period)

        pipeline = [
            {
                "$match": {
                    "business_id": {"$in": business_ids},
                    "type": "expense",
                    "date": {"$gte": start, "$lte": end},
                }
            },
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
            {"category": r["_id"], "amount": float(r["amount"]), "count": r["count"]}
            for r in results
        ]

        return {
            "period": period,
            "total_expenses": total_expenses,
            "transaction_count": transaction_count,
            "breakdown": breakdown,
        }

    def get_profit(self, business_id: str | None, period: str, user_id: str):
        income = self.get_income(business_id, period, user_id)
        expenses = self.get_expenses(business_id, period, user_id)
        profit = income["total_income"] - expenses["total_expenses"]

        return {
            "period": period,
            "total_income": income["total_income"],
            "total_expenses": expenses["total_expenses"],
            "profit": profit,
            "transaction_count": income["transaction_count"] + expenses["transaction_count"],
        }

    def get_receivables(self, business_id: str | None, user_id: str, overdue_only: bool = False, customer_id: str | None = None):
        business_ids = self._get_user_business_ids(user_id)
        if business_id:
            self._verify_business_access(business_id, user_id)
            business_ids = [business_id]

        query = {
            "business_id": {"$in": business_ids},
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
            "total_receivables": total_receivables,
            "overdue_amount": overdue_amount,
            "invoices": invoice_list,
        }

    def get_liabilities(self, user_id: str, upcoming_only: bool = False, overdue_only: bool = False):
        business_ids = self._get_user_business_ids(user_id)

        query = {
            "business_id": {"$in": business_ids},
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
            "total_liabilities": total_liabilities,
            "upcoming_amount": upcoming_amount,
            "overdue_amount": overdue_amount,
            "obligations": obligations,
        }

    def get_cash_position(self, user_id: str):
        business_ids = self._get_user_business_ids(user_id)

        income_pipeline = [
            {"$match": {"business_id": {"$in": business_ids}, "type": "income"}},
            {"$group": {"_id": None, "total": {"$sum": "$amount"}}},
        ]
        income_result = list(db.transactions.aggregate(income_pipeline))
        total_income = float(income_result[0]["total"]) if income_result else 0.0

        expense_pipeline = [
            {"$match": {"business_id": {"$in": business_ids}, "type": "expense"}},
            {"$group": {"_id": None, "total": {"$sum": "$amount"}}},
        ]
        expense_result = list(db.transactions.aggregate(expense_pipeline))
        total_expenses = float(expense_result[0]["total"]) if expense_result else 0.0

        net_cash_flow = total_income - total_expenses
        recorded_cash_position = net_cash_flow

        receivables = db.invoices.find({
            "business_id": {"$in": business_ids},
            "outstanding_amount": {"$gt": 0},
        })
        pending_receivables = sum(float(inv.get("outstanding_amount", 0)) for inv in receivables)

        liabilities_result = self.get_liabilities(user_id, upcoming_only=True)
        pending_liabilities = liabilities_result["upcoming_amount"]

        available_cash = recorded_cash_position + pending_receivables - pending_liabilities

        return {
            "recorded_cash_position": recorded_cash_position,
            "total_income": total_income,
            "total_expenses": total_expenses,
            "net_cash_flow": net_cash_flow,
            "pending_receivables": pending_receivables,
            "pending_liabilities": pending_liabilities,
            "available_cash": available_cash,
        }

    def get_cash_flow(self, user_id: str, days: int = 7):
        cash_position = self.get_cash_position(user_id)
        receivables = self.get_receivables(None, user_id)
        liabilities = self.get_liabilities(user_id, upcoming_only=True)

        current_cash = cash_position["recorded_cash_position"]
        expected_receivables = receivables["total_receivables"]
        upcoming_liabilities = liabilities["upcoming_amount"]

        projected_balance = current_cash + expected_receivables - upcoming_liabilities

        if upcoming_liabilities == 0:
            risk_indicator = "low"
        elif projected_balance >= 0:
            risk_indicator = "medium"
        else:
            risk_indicator = "high"

        return {
            "days": days,
            "current_cash": current_cash,
            "expected_receivables": expected_receivables,
            "upcoming_liabilities": upcoming_liabilities,
            "projected_balance": projected_balance,
            "risk_indicator": risk_indicator,
        }

    def get_receivable_aging(self, business_id: str | None, user_id: str):
        business_ids = self._get_user_business_ids(user_id)
        if business_id:
            self._verify_business_access(business_id, user_id)
            business_ids = [business_id]

        invoices = db.invoices.find({
            "business_id": {"$in": business_ids},
            "outstanding_amount": {"$gt": 0},
        })

        today = date.today()
        aging_buckets = {
            "0-30": 0.0,
            "31-60": 0.0,
            "61-90": 0.0,
            "90+": 0.0,
        }
        invoice_list = []
        total_receivables = 0.0

        for invoice in invoices:
            amount = float(invoice["amount"])
            paid_amount = float(invoice.get("paid_amount", 0))
            outstanding = float(invoice.get("outstanding_amount", amount - paid_amount))
            due_date = invoice.get("due_date")

            if hasattr(due_date, "date"):
                due_date = due_date.date()

            days_outstanding = 0
            if due_date:
                days_outstanding = (today - due_date).days
                if days_outstanding < 0:
                    days_outstanding = 0

            if days_outstanding <= 30:
                bucket = "0-30"
            elif days_outstanding <= 60:
                bucket = "31-60"
            elif days_outstanding <= 90:
                bucket = "61-90"
            else:
                bucket = "90+"

            aging_buckets[bucket] += outstanding
            total_receivables += outstanding

            invoice_list.append({
                "id": str(invoice["_id"]),
                "invoice_number": invoice.get("invoice_number"),
                "customer_name": invoice["customer_name"],
                "amount": amount,
                "paid_amount": paid_amount,
                "outstanding_amount": outstanding,
                "due_date": due_date.isoformat() if due_date else None,
                "days_outstanding": days_outstanding,
                "aging_bucket": bucket,
            })

        return {
            "total_receivables": total_receivables,
            "aging_buckets": aging_buckets,
            "invoices": invoice_list,
        }

    def get_customer_summary(self, business_id: str | None, user_id: str):
        business_ids = self._get_user_business_ids(user_id)
        if business_id:
            self._verify_business_access(business_id, user_id)
            business_ids = [business_id]

        invoices = db.invoices.find({
            "business_id": {"$in": business_ids},
            "outstanding_amount": {"$gt": 0},
        })

        customer_map = {}
        total_receivables = 0.0

        for invoice in invoices:
            customer_name = invoice["customer_name"]
            amount = float(invoice["amount"])
            paid_amount = float(invoice.get("paid_amount", 0))
            outstanding = float(invoice.get("outstanding_amount", amount - paid_amount))

            if customer_name not in customer_map:
                customer_map[customer_name] = {
                    "customer_name": customer_name,
                    "amount": 0.0,
                    "paid_amount": 0.0,
                    "outstanding_amount": 0.0,
                    "invoice_count": 0,
                }

            customer_map[customer_name]["amount"] += amount
            customer_map[customer_name]["paid_amount"] += paid_amount
            customer_map[customer_name]["outstanding_amount"] += outstanding
            customer_map[customer_name]["invoice_count"] += 1
            total_receivables += outstanding

        return {
            "total_receivables": total_receivables,
            "customers": list(customer_map.values()),
        }

    def get_supplier_summary(self, business_id: str | None, user_id: str):
        business_ids = self._get_user_business_ids(user_id)
        if business_id:
            self._verify_business_access(business_id, user_id)
            business_ids = [business_id]

        transactions = db.transactions.find({
            "business_id": {"$in": business_ids},
            "type": "expense",
        })

        supplier_map = {}
        total_payables = 0.0

        for txn in transactions:
            supplier_name = txn.get("description") or txn.get("category", "unknown")
            amount = float(txn["amount"])

            if supplier_name not in supplier_map:
                supplier_map[supplier_name] = {
                    "name": supplier_name,
                    "amount": 0.0,
                    "paid_amount": 0.0,
                    "outstanding_amount": 0.0,
                    "transaction_count": 0,
                }

            supplier_map[supplier_name]["amount"] += amount
            supplier_map[supplier_name]["paid_amount"] += amount
            supplier_map[supplier_name]["outstanding_amount"] += amount
            supplier_map[supplier_name]["transaction_count"] += 1
            total_payables += amount

        return {
            "total_payables": total_payables,
            "suppliers": list(supplier_map.values()),
        }

    def get_anomalies(self, user_id: str):
        business_ids = self._get_user_business_ids(user_id)
        anomalies = []

        anomalies.extend(self._check_duplicate_invoices(business_ids))
        anomalies.extend(self._check_overpayments(business_ids))
        anomalies.extend(self._check_unusual_expenses(business_ids))

        return {
            "anomaly_count": len(anomalies),
            "anomalies": anomalies,
        }

    def _check_duplicate_invoices(self, business_ids: list[str]):
        anomalies = []
        invoices = db.invoices.find({"business_id": {"$in": business_ids}})

        seen = {}
        for invoice in invoices:
            invoice_number = invoice.get("invoice_number")
            if not invoice_number:
                continue

            key = (str(invoice["business_id"]), invoice_number.strip().lower())
            if key in seen:
                anomalies.append({
                    "id": str(invoice["_id"]),
                    "type": "invoice",
                    "severity": "medium",
                    "message": "Duplicate invoice number detected. Please review.",
                    "data": {
                        "invoice_number": invoice_number,
                        "business_id": str(invoice["business_id"]),
                        "existing_invoice_id": seen[key],
                        "duplicate_invoice_id": str(invoice["_id"]),
                    },
                })
            else:
                seen[key] = str(invoice["_id"])

        return anomalies

    def _check_overpayments(self, business_ids: list[str]):
        anomalies = []
        invoices = db.invoices.find({
            "business_id": {"$in": business_ids},
            "outstanding_amount": {"$lt": 0},
        })

        for invoice in invoices:
            anomalies.append({
                "id": str(invoice["_id"]),
                "type": "invoice",
                "severity": "high",
                "message": "Payment exceeds invoice amount. Please review.",
                "data": {
                    "invoice_number": invoice.get("invoice_number"),
                    "amount": float(invoice["amount"]),
                    "paid_amount": float(invoice.get("paid_amount", 0)),
                    "outstanding_amount": float(invoice.get("outstanding_amount", 0)),
                },
            })

        return anomalies

    def _check_unusual_expenses(self, business_ids: list[str]):
        anomalies = []
        transactions = db.transactions.find({
            "business_id": {"$in": business_ids},
            "type": "expense",
        })

        category_stats = {}
        for txn in transactions:
            category = txn.get("category", "unknown")
            amount = float(txn["amount"])
            if category not in category_stats:
                category_stats[category] = []
            category_stats[category].append(amount)

        category_avg = {}
        for category, amounts in category_stats.items():
            if amounts:
                category_avg[category] = sum(amounts) / len(amounts)

        for txn in transactions:
            category = txn.get("category", "unknown")
            amount = float(txn["amount"])
            avg = category_avg.get(category)

            if avg and avg > 0 and amount > avg * 3:
                anomalies.append({
                    "id": str(txn["_id"]),
                    "type": "transaction",
                    "severity": "medium",
                    "message": "Unusually large expense detected. Please review.",
                    "data": {
                        "category": category,
                        "amount": amount,
                        "average_for_category": avg,
                        "description": txn.get("description"),
                    },
                })

        return anomalies


financial_service = FinancialService()
