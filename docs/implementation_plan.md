# VyaparAI — Phase 8 Implementation Plan

## Goal

Build the Financial Intelligence Foundation.

This phase adds deterministic financial calculations on top of the existing transaction, invoice, and payment data.

**Critical rule:** All financial calculations must be performed by Python/MongoDB aggregation, not by an LLM.

---

## New Files

| File | Purpose |
|------|---------|
| `backend/app/services/financial_service.py` | Income, expense, profit, receivables, liabilities, cash position |
| `backend/app/api/financials.py` | Financial API endpoints |
| `backend/app/schemas/financial.py` | Pydantic schemas for financial responses |

## Modified Files

| File | Change |
|------|--------|
| `backend/app/main.py` | Register financial router |
| `backend/app/database/indexes.py` | Add financial query indexes |

---

## API Endpoints

### Income

```
GET /financials/income/today
GET /financials/income/week
GET /financials/income/month
```

Query params: `business_id` (optional, defaults to all user businesses)

Response:
```json
{
  "period": "today",
  "total_income": 42500.0,
  "transaction_count": 3,
  "breakdown": [
    {
      "category": "customer_payment",
      "amount": 35000.0,
      "count": 2
    },
    {
      "category": "other_income",
      "amount": 7500.0,
      "count": 1
    }
  ]
}
```

### Expenses

```
GET /financials/expenses/today
GET /financials/expenses/week
GET /financials/expenses/month
```

Response:
```json
{
  "period": "today",
  "total_expenses": 16200.0,
  "transaction_count": 4,
  "breakdown": [
    {
      "category": "inventory",
      "amount": 12000.0,
      "count": 2
    },
    {
      "category": "transport",
      "amount": 4200.0,
      "count": 2
    }
  ]
}
```

### Profit

```
GET /financials/profit/today
GET /financials/profit/week
GET /financials/profit/month
```

Response:
```json
{
  "period": "today",
  "total_income": 42500.0,
  "total_expenses": 16200.0,
  "profit": 26300.0,
  "transaction_count": 7
}
```

### Receivables

```
GET /financials/receivables
GET /financials/receivables/overdue
GET /financials/receivables/customer/{customer_id}
```

Response:
```json
{
  "total_receivables": 42000.0,
  "overdue_amount": 18000.0,
  "invoices": [
    {
      "id": "...",
      "invoice_number": "INV-1001",
      "customer_name": "ABC Traders",
      "amount": 18000.0,
      "paid_amount": 0.0,
      "outstanding_amount": 18000.0,
      "due_date": "2026-09-20",
      "status": "overdue",
      "days_overdue": 2
    }
  ]
}
```

### Liabilities

```
GET /financials/liabilities
GET /financials/liabilities/upcoming
GET /financials/liabilities/overdue
```

Response:
```json
{
  "total_liabilities": 12000.0,
  "upcoming_amount": 12000.0,
  "overdue_amount": 0.0,
  "obligations": [
    {
      "id": "...",
      "description": "Supplier payment",
      "amount": 12000.0,
      "due_date": "2026-09-22",
      "status": "upcoming",
      "days_until_due": 4
    }
  ]
}
```

### Cash Position

```
GET /financials/cash-position
```

Response:
```json
{
  "recorded_cash_position": 25000.0,
  "total_income": 42500.0,
  "total_expenses": 16200.0,
  "net_cash_flow": 26300.0,
  "pending_receivables": 42000.0,
  "pending_liabilities": 12000.0,
  "available_cash": 25000.0
}
```

**Important:** Use `recorded_cash_position`, not `bank_balance`, because the system cannot know money outside recorded data.

---

## Service Responsibilities

### `FinancialService`

**Location:** `backend/app/services/financial_service.py`

**Methods:**

#### `get_income(business_id, period, user_id)`
- Query transactions where `type = "income"` and `business_id` in user's businesses
- Filter by period: today, week, month
- Group by category
- Return total + breakdown

#### `get_expenses(business_id, period, user_id)`
- Query transactions where `type = "expense"`
- Filter by period
- Group by category
- Return total + breakdown

#### `get_profit(business_id, period, user_id)`
- Call `get_income()` and `get_expenses()`
- Calculate: profit = income - expenses
- Return with counts

#### `get_receivables(business_id, user_id, overdue_only=False, customer_id=None)`
- Query invoices where `business_id` in user's businesses
- Filter: `outstanding_amount > 0`
- If `overdue_only`: add `due_date < today` and `status != "paid"`
- If `customer_id`: filter by customer
- Calculate `days_overdue` for each invoice
- Return aggregated totals + invoice list

#### `get_liabilities(user_id, upcoming_only=False, overdue_only=False)`
- For MVP, liabilities are tracked as expense transactions with `source = "upi"` or manual entries
- Alternatively, create a simple liability collection if needed
- Filter by due date if available
- Return totals + obligation list

#### `get_cash_position(user_id)`
- Sum all income transactions = total income
- Sum all expense transactions = total expenses
- Net cash flow = income - expenses
- Pending receivables = sum of all outstanding invoice amounts
- Pending liabilities = sum of upcoming obligations
- Return all figures

#### `_get_date_range(period)`
- Helper to convert `today`, `week`, `month` to start/end datetimes
- Today: 00:00:00 to 23:59:59
- Week: Monday 00:00:00 to Sunday 23:59:59
- Month: 1st 00:00:00 to last day 23:59:59

#### `_verify_business_access(business_id, user_id)`
- Reuse existing `verify_business_ownership` pattern
- Ensure user owns the business

---

## Schema Design

### `IncomeResponse`
```python
class IncomeResponse(BaseModel):
    period: str
    total_income: float
    transaction_count: int
    breakdown: list[dict]

class ExpenseResponse(BaseModel):
    period: str
    total_expenses: float
    transaction_count: int
    breakdown: list[dict]

class ProfitResponse(BaseModel):
    period: str
    total_income: float
    total_expenses: float
    profit: float
    transaction_count: int

class ReceivableResponse(BaseModel):
    total_receivables: float
    overdue_amount: float
    invoices: list[dict]

class LiabilityResponse(BaseModel):
    total_liabilities: float
    upcoming_amount: float
    overdue_amount: float
    obligations: list[dict]

class CashPositionResponse(BaseModel):
    recorded_cash_position: float
    total_income: float
    total_expenses: float
    net_cash_flow: float
    pending_receivables: float
    pending_liabilities: float
    available_cash: float
```

---

## MongoDB Indexes

Add to `backend/app/database/indexes.py`:

```python
db.transactions.create_index([
    ("business_id", 1),
    ("type", 1),
    ("date", 1)
])

db.transactions.create_index([
    ("business_id", 1),
    ("type", 1),
    ("category", 1)
])

db.invoices.create_index([
    ("business_id", 1),
    ("status", 1),
    ("due_date", 1)
])
```

---

## Business Logic Rules

### Income Calculation
- Only transactions with `type = "income"` count
- Group by `category`
- Filter by `date` range based on period

### Expense Calculation
- Only transactions with `type = "expense"` count
- Group by `category`
- Filter by `date` range based on period

### Profit Calculation
- Profit = total_income - total_expenses
- Never let LLM calculate this
- Use Python float arithmetic

### Receivables
- Only invoices with `outstanding_amount > 0` count as receivables
- Overdue = `due_date < today` and `status != "paid"`
- `days_overdue` = `today - due_date` in days

### Liabilities
- For MVP, use expense transactions with `source = "upi"` or `source = "manual"` as liabilities
- Or create simple liability tracking if needed
- Upcoming = due date in future
- Overdue = due date in past

### Cash Position
- `recorded_cash_position` = sum of all income - sum of all expenses
- `pending_receivables` = sum of all invoice `outstanding_amount`
- `pending_liabilities` = sum of upcoming obligations
- `available_cash` = `recorded_cash_position` + `pending_receivables` - `pending_liabilities`

---

## Error Handling

- 401: Missing/invalid JWT
- 404: Business not found or access denied
- 400: Invalid period parameter
- 500: Database error

---

## Security

- All endpoints require `get_current_user()`
- All queries filtered by user's businesses
- Never expose other users' data
- Never expose password_hash

---

## Testing Checklist

- [ ] `GET /financials/income/today` returns correct total
- [ ] `GET /financials/income/week` returns correct total
- [ ] `GET /financials/income/month` returns correct total
- [ ] `GET /financials/expenses/today` returns correct total
- [ ] `GET /financials/expenses/week` returns correct total
- [ ] `GET /financials/expenses/month` returns correct total
- [ ] `GET /financials/profit/today` = income - expenses
- [ ] `GET /financials/profit/week` = income - expenses
- [ ] `GET /financials/profit/month` = income - expenses
- [ ] `GET /financials/receivables` returns only outstanding invoices
- [ ] `GET /financials/receivables/overdue` returns only overdue invoices
- [ ] `GET /financials/receivables/customer/{id}` returns customer-specific receivables
- [ ] `GET /financials/liabilities` returns liabilities
- [ ] `GET /financials/liabilities/upcoming` returns future liabilities
- [ ] `GET /financials/liabilities/overdue` returns overdue liabilities
- [ ] `GET /financials/cash-position` returns correct position
- [ ] User A cannot access User B's financial data
- [ ] Invalid business_id returns 400
- [ ] Missing JWT returns 401

---

## Example Test Data

Create these transactions for testing:

```json
// Income today
{
  "business_id": "BUSINESS_ID",
  "type": "income",
  "amount": 35000.0,
  "category": "customer_payment",
  "date": "2026-09-18",
  "source": "upi",
  "description": "Payment from ABC Traders"
}

// Income today
{
  "business_id": "BUSINESS_ID",
  "type": "income",
  "amount": 7500.0,
  "category": "other_income",
  "date": "2026-09-18",
  "source": "manual",
  "description": "Miscellaneous income"
}

// Expense today
{
  "business_id": "BUSINESS_ID",
  "type": "expense",
  "amount": 12000.0,
  "category": "inventory",
  "date": "2026-09-18",
  "source": "upi",
  "description": "Inventory purchase"
}

// Expense today
{
  "business_id": "BUSINESS_ID",
  "type": "expense",
  "amount": 4200.0,
  "category": "transport",
  "date": "2026-09-18",
  "source": "cash",
  "description": "Transport cost"
}
```

Expected results:
- Income today: ₹42,500
- Expenses today: ₹16,200
- Profit today: ₹26,300

---

## Implementation Order

1. Create `backend/app/schemas/financial.py`
2. Create `backend/app/services/financial_service.py`
3. Create `backend/app/api/financials.py`
4. Update `backend/app/main.py` to register router
5. Update `backend/app/database/indexes.py` with new indexes
6. Test all endpoints with Swagger
7. Run security tests
8. Verify Phases 1–7 still work

---

## What This Phase Does NOT Include

- Cash-flow forecasting (Phase 9)
- Anomaly detection (Phase 11)
- Insights engine (Phase 12)
- AI copilot (Phase 14)
- Voice backend (Phase 15)
- Reminders (Phase 16)
- Reports (Phase 17)

This phase is strictly about deterministic financial calculations from existing data.
