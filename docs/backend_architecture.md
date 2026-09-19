# VyaparAI Backend — Complete File Documentation

## Architecture Overview

```
Mobile App
    │
    ▼
FastAPI Backend (app/main.py)
    │
    ├── API Layer (app/api/)
    │       └── Routers → Service Layer
    │
    ├── Service Layer (app/services/)
    │       └── Business Logic → Database/AI Tools
    │
    ├── AI Tools Layer (app/ai_tools/)
    │       └── Tool wrappers → Service Layer
    │
    ├── Schema Layer (app/schemas/)
    │       └── Pydantic validation
    │
    ├── Model Layer (app/models/)
    │       └── MongoDB document builders
    │
    ├── Core (app/core/)
    │       └── Security, auth, config
    │
    └── Database (app/database/)
            └── MongoDB connection + indexes
```

**Data Flow:**
1. Request → API Router
2. Router → Service (business logic)
3. Service → Repository/DB or AI Tools
4. AI Tools → Service → DB
5. Response ← Service ← Router

**Key Principle:** Financial calculations are deterministic. LLM/AI only explains results, never calculates them.

---

## File-by-File Documentation

### Core Files

#### `app/main.py`
**Purpose:** FastAPI application entry point. Registers all routers, configures CORS, creates DB indexes on startup.

**Contains:**
- FastAPI app initialization
- CORS middleware configuration
- Startup event handler (`create_indexes()`)
- Router imports and registration
- Health check endpoints (`/`, `/health`, `/health/database`)

**Why Used:** Single entry point for the entire backend. All API routes are registered here.

---

#### `app/core/security.py`
**Purpose:** Authentication and authorization utilities. JWT token creation/validation, password hashing, current user extraction.

**Contains:**
- `hash_password()` — bcrypt password hashing
- `verify_password()` — bcrypt password verification
- `create_access_token()` — JWT token creation with expiry
- `get_current_user()` — FastAPI dependency that extracts and validates JWT, returns user document

**Why Used:** All protected endpoints use `get_current_user` dependency to authenticate requests. JWT_SECRET is required env var.

---

#### `app/database/mongodb.py`
**Purpose:** MongoDB Atlas connection management.

**Contains:**
- `MongoClient` initialization from `MONGODB_URL` env var
- `db` — global database instance (`vyaparai` by default)
- `get_database()` — accessor function

**Why Used:** Single MongoDB connection reused across all services. Raises `RuntimeError` if `MONGODB_URL` not configured.

---

#### `app/database/indexes.py`
**Purpose:** Creates MongoDB indexes on startup for query performance and uniqueness.

**Contains:**
- `create_indexes()` function called on app startup
- Indexes for: users (email unique), businesses (owner_id), invoices (business_id, status, due_date, invoice_number+customer+amount), transactions (business_id, type, date, category), reminders (user+business+status, user+business+due_at), notifications (user+business+read, user+business+created_at)

**Why Used:** Ensures fast queries and prevents duplicate invoices/emails.

---

### Model Files (`app/models/`)

**Purpose:** Document builder functions. Each function returns a dictionary ready for MongoDB insertion. No business logic, just shape definitions.

#### `app/models/user.py`
**Contains:** `user_document(name, email, password_hash)` → dict with name, email, password_hash, created_at

**Why Used:** Standardizes user document structure across create operations.

---

#### `app/models/business.py`
**Contains:** `business_document(name, business_type, owner_id)` → dict with name, business_type, owner_id, created_at

**Why Used:** Standardizes business document structure. All financial data links to a business via `business_id`.

---

#### `app/models/invoice.py`
**Contains:** `invoice_document(business_id, customer_name, amount, due_date, ...)` → dict with all invoice fields including paid_amount, outstanding_amount, status, created_at, updated_at

**Why Used:** Ensures all invoices have consistent fields. Handles date conversion and default values.

---

#### `app/models/transaction.py`
**Contains:** `transaction_document(business_id, type, amount, category, date, ...)` → dict with all transaction fields including source, reference_id, user_id, created_at, updated_at

**Why Used:** Ensures all transactions have consistent fields. Handles date conversion and default values.

---

### Schema Files (`app/schemas/`)

**Purpose:** Pydantic models for request/response validation. Define what data the API accepts and returns.

#### `app/schemas/transaction.py`
**Contains:**
- `TransactionCreate` — create transaction request (validates type ∈ {income, expense}, source ∈ allowed set, amount > 0)
- `TransactionUpdate` — update transaction request (partial update allowed)
- `TransactionResponse` — transaction response with all fields

**Why Used:** Validates transaction API inputs and serializes outputs.

---

#### `app/schemas/invoice.py`
**Contains:**
- `InvoiceCreate` — create invoice request
- `InvoiceUpdate` — update invoice request
- `InvoiceStatusUpdate` — update invoice status (validates status ∈ allowed set)
- `PaymentApplyRequest` — apply payment to invoice (amount > 0)

**Why Used:** Validates invoice API inputs. Ensures status values are valid.

---

#### `app/schemas/ocr.py`
**Contains:**
- `OCRExtraction` — extracted invoice data from OCR
- `OCRResponse` — OCR extraction response
- `OCRConfirmRequest` — confirm OCR-extracted invoice
- `PaymentExtraction` — extracted payment data from OCR
- `PaymentResponse` — payment extraction response
- `PaymentConfirmRequest` — confirm payment extraction

**Why Used:** Validates OCR endpoints. Defines the shape of extracted data from invoice/payment screenshots.

---

#### `app/schemas/financial.py`
**Contains:**
- `IncomeResponse`, `ExpenseResponse`, `ProfitResponse` — period-based financial summaries
- `ReceivableResponse`, `LiabilityResponse` — receivables/liabilities lists
- `CashPositionResponse` — current cash position
- `CashFlowResponse` — cash flow forecast
- `ReceivableAgingResponse`, `CustomerSummaryResponse`, `SupplierSummaryResponse` — reconciliation views
- `AnomalyResponse`, `AnomaliesListResponse` — anomaly detection results
- `InsightResponse`, `InsightsListResponse` — insight generation results

**Why Used:** Standardizes all financial API responses.

---

#### `app/schemas/copilot.py`
**Contains:**
- `CopilotChatRequest` — chat message input
- `CopilotChatResponse` — chat response with answer, intent, data

**Why Used:** Validates copilot chat API. Keeps chat interface consistent.

---

#### `app/schemas/voice.py`
**Contains:**
- `VoiceQueryRequest` — voice query input (audio or text)
- `VoiceQueryResponse` — voice response with transcription, answer, intent, language

**Why Used:** Validates voice API. Bridges audio/text input to copilot output.

---

#### `app/schemas/reminder.py`
**Contains:**
- `ReminderCreate` — create reminder request
- `ReminderUpdate` — update reminder request
- `ReminderResponse` — reminder response
- `NotificationResponse` — notification response
- `MorningBriefingResponse` — morning briefing summary

**Why Used:** Validates reminder/notification APIs. Structures morning briefing output.

---

### Service Files (`app/services/`)

**Purpose:** Business logic layer. Contains all calculations, validations, and data operations. No HTTP concerns.

#### `app/services/ocr_service.py`
**Contains:** `OCRService` class with:
- `validate_file()` — validates image file size, extension, MIME type
- `preprocess_image()` — image enhancement for better OCR
- `extract_text()` — pytesseract OCR or simulation mode
- `_simulate_ocr()` — returns sample invoice text when tesseract unavailable

**Why Used:** Handles all OCR operations. Falls back to simulation mode if tesseract not installed.

---

#### `app/services/invoice_extractor.py`
**Contains:** `InvoiceExtractor` class with regex patterns for:
- Invoice numbers, dates, due dates
- Customer names, total amounts
- Currency detection
- `extract()` — main extraction method returning `OCRExtraction`

**Why Used:** Extracts structured invoice data from raw OCR text using regex patterns.

---

#### `app/services/payment_extractor.py`
**Contains:** `PaymentExtractor` class with regex patterns for:
- Payment amounts, references, dates
- Sender/receiver names, bank names
- Payment status, method
- Direction detection (sent/received)

**Why Used:** Extracts payment data from UPI screenshots and bank messages.

---

#### `app/services/invoice_matching.py`
**Contains:** `InvoiceMatchingService` with:
- `find_match()` — matches payment to invoices using scoring
- `_score_invoice()` — calculates match score (customer name + amount)
- `_build_match_result()` — builds match result with after-payment status
- Statuses: `match`, `partial_match`, `overpayment_review`, `no_match`

**Why Used:** Automatically matches UPI payments to outstanding invoices. Critical for reconciliation.

---

#### `app/services/payment_processing.py`
**Contains:** `PaymentProcessingService` with:
- `record_payment()` — records payment, creates transaction, updates invoice status
- `check_duplicate_payment()` — checks for duplicate payments by reference

**Why Used:** Central payment processing. Ensures invoice and transaction records stay in sync.

---

#### `app/services/financial_service.py`
**Contains:** `FinancialService` class with core financial calculations:
- `get_income()` — income by period with category breakdown
- `get_expenses()` — expenses by period with category breakdown
- `get_profit()` — profit calculation
- `get_receivables()` — outstanding invoices with overdue detection
- `get_liabilities()` — expense-based obligations with upcoming/overdue
- `get_cash_position()` — recorded cash position + pending receivables/liabilities

**Why Used:** Single source of truth for all deterministic financial calculations. Used by every other financial service.

---

#### `app/services/cashflow_service.py`
**Contains:** `get_cash_flow()` — projected cash balance with risk indicator

**Why Used:** Separates cash-flow projection logic from core financial calculations.

---

#### `app/services/reconciliation_service.py`
**Contains:**
- `get_receivable_aging()` — aging buckets (0-30, 31-60, 61-90, 90+)
- `get_customer_summary()` — customer-wise receivables
- `get_supplier_summary()` — supplier-wise payables

**Why Used:** Provides reconciliation views. Used in dashboard and reports.

---

#### `app/services/anomaly_service.py`
**Contains:**
- `get_anomalies()` — runs all anomaly checks
- `_check_duplicate_invoices()` — duplicate invoice detection
- `_check_overpayments()` — payment > invoice amount
- `_check_unusual_expenses()` — expense > 3x category average

**Why Used:** Rule-based anomaly detection. Flags issues for review without ML.

---

#### `app/services/insight_service.py`
**Contains:**
- `get_insights()` — runs all insight checks
- `_check_revenue_trends()` — declining revenue detection
- `_check_expense_trends()` — high expense category alerts
- `_check_receivable_alerts()` — overdue receivable warnings
- `_check_cash_flow_warnings()` — projected shortfall warnings
- `_check_anomaly_flags()` — anomaly summary insight

**Why Used:** Generates deterministic business insights from financial data.

---

#### `app/services/copilot_service.py`
**Contains:** `CopilotService` with:
- `classify_intent()` — rule-based intent detection from user message
- `generate_answer()` — formats financial data into natural language
- `chat()` — main entry point, routes intents to handlers
- Intent handlers for: profit, income, expenses, cash position, cash flow, receivables, liabilities, invoices, customer balance, payment history, business summary

**Why Used:** Text-based AI copilot. Bridges natural language to financial tools. No LLM calculates money.

---

#### `app/services/voice_service.py`
**Contains:** `VoiceService` with:
- `process_query()` — main voice pipeline
- `_is_bot_activated()` — checks for activation phrases ("VyaparAI", "hey VyaparAI", etc.)
- `_remove_activation()` — strips activation phrase from query
- `_is_morning_briefing()` — detects morning briefing intent
- `_handle_morning_briefing()` — generates morning briefing
- `_detect_language()` — detects English/Hindi/Kannada

**Why Used:** Voice interface layer. Handles bot activation, morning briefing, and routes to copilot.

---

#### `app/services/reminder_service.py`
**Contains:** `ReminderService` with:
- `create_reminder()` — create reminder
- `get_reminders()` — list reminders with optional status filter
- `get_reminder()` — get single reminder
- `update_reminder()` — update reminder fields
- `delete_reminder()` — delete reminder
- `get_morning_briefing()` — generates morning briefing with financial summary + notifications

**Why Used:** Manages user reminders and generates daily morning briefings.

---

#### `app/services/notification_service.py`
**Contains:** `NotificationService` with:
- `create_notification()` — create notification
- `get_notifications()` — list notifications with unread filter
- `mark_as_read()` — mark notification as read

**Why Used:** Manages in-app notifications. Currently notifications are created by morning briefing and can be marked as read.

---

### API Files (`app/api/`)

**Purpose:** FastAPI routers. Each file handles one domain. Contains route definitions, request validation, and response formatting. No business logic.

#### `app/api/auth.py`
**Endpoints:**
- `POST /auth/login` — login with email/password, returns JWT

**Why Used:** Authentication entry point. All other APIs require JWT from this endpoint.

---

#### `app/api/users.py`
**Endpoints:**
- `POST /users/` — create user with hashed password

**Why Used:** User registration. Creates user document with bcrypt-hashed password.

---

#### `app/api/businesses.py`
**Endpoints:**
- `POST /businesses/` — create business for current user

**Why Used:** Business creation. All financial data is scoped to a business.

---

#### `app/api/transactions.py`
**Endpoints:**
- `GET /transactions/` — list transactions with filters
- `GET /transactions/{id}` — get single transaction
- `POST /transactions/` — create transaction
- `PUT /transactions/{id}` — update transaction
- `DELETE /transactions/{id}` — delete transaction
- `GET /transactions/summary` — income/expense summary with date range

**Why Used:** CRUD for financial transactions. Summary endpoint for dashboard.

---

#### `app/api/invoices.py`
**Endpoints:**
- `POST /invoices/` — create invoice
- `GET /invoices/` — list user's invoices
- `GET /invoices/{id}` — get single invoice
- `PUT /invoices/{id}` — update invoice
- `DELETE /invoices/{id}` — delete invoice
- `PATCH /invoices/{id}/status` — update invoice status
- `POST /invoices/{id}/payments` — apply payment to invoice

**Why Used:** Invoice management. Payment endpoint creates transaction and updates invoice atomically via `payment_processing_service`.

---

#### `app/api/ocr.py`
**Endpoints:**
- `POST /ocr/invoice` — upload invoice image, extract data via OCR
- `POST /ocr/invoice/confirm` — confirm OCR-extracted invoice, create in DB
- `POST /ocr/payment` — upload payment screenshot, extract + match to invoices
- `POST /ocr/payment/confirm` — confirm payment, record transaction and update invoice

**Why Used:** OCR pipeline for invoice and payment screenshots. Includes duplicate detection and invoice matching.

---

#### `app/api/financials.py`
**Endpoints:**
- `GET /financials/income/{today,week,month}` — income by period
- `GET /financials/expenses/{today,week,month}` — expenses by period
- `GET /financials/profit/{today,week,month}` — profit by period
- `GET /financials/receivables` — outstanding invoices
- `GET /financials/receivables/overdue` — overdue invoices only
- `GET /financials/receivables/customer/{id}` — customer-specific receivables
- `GET /financials/receivables/aging` — receivable aging buckets
- `GET /financials/receivables/customer-summary` — customer-wise summary
- `GET /financials/liabilities` — all liabilities
- `GET /financials/liabilities/upcoming` — upcoming liabilities
- `GET /financials/liabilities/overdue` — overdue liabilities
- `GET /financials/liabilities/supplier-summary` — supplier-wise summary
- `GET /financials/anomalies` — detected anomalies
- `GET /financials/insights` — business insights
- `GET /financials/cash-flow` — cash flow forecast
- `GET /financials/cash-position` — current cash position

**Why Used:** Main financial intelligence API layer. All financial queries go through here.

---

#### `app/api/copilot.py`
**Endpoints:**
- `POST /copilot/chat` — text chat with AI copilot

**Why Used:** Text-based AI interface. Accepts user question, returns AI-generated answer based on deterministic financial data.

---

#### `app/api/voice.py`
**Endpoints:**
- `POST /voice/query` — voice query with bot activation

**Why Used:** Voice interface. Accepts audio or text, requires bot activation phrase, returns structured answer.

---

#### `app/api/reminders.py`
**Endpoints:**
- `GET /reminders/morning-briefing` — get morning briefing with financial summary
- `POST /reminders/` — create reminder
- `GET /reminders/` — list reminders
- `GET /reminders/{id}` — get single reminder
- `PATCH /reminders/{id}` — update reminder
- `DELETE /reminders/{id}` — delete reminder

**Why Used:** Reminder management and morning briefing generation.

---

#### `app/api/notifications.py`
**Endpoints:**
- `GET /notifications/` — list notifications
- `PATCH /notifications/{id}/read` — mark notification as read

**Why Used:** In-app notification management. Currently used for morning briefing notifications.

---

### AI Tools Files (`app/ai_tools/`)

**Purpose:** Backend tool wrappers that the copilot can call. Each function is a deterministic financial operation. No HTTP, no LLM logic.

#### `app/ai_tools/financial_tools.py`
**Contains:**
- `get_today_income(business_id, user_id)`
- `get_today_expenses(business_id, user_id)`
- `get_today_profit(business_id, user_id)`
- `get_cash_position(user_id)`
- `get_receivables(business_id, user_id, overdue_only, customer_id)`
- `get_overdue_receivables(business_id, user_id)`
- `get_liabilities(user_id, upcoming_only, overdue_only)`
- `get_upcoming_liabilities(user_id)`
- `get_cash_flow_forecast(user_id, days)`

**Why Used:** Provides financial data tools for copilot. Each calls `FinancialService` directly.

---

#### `app/ai_tools/customer_tools.py`
**Contains:**
- `get_customer_balance(customer_name, business_id, user_id)`
- `get_supplier_balance(supplier_name, business_id, user_id)`
- `get_payment_history(customer_name, business_id, user_id)`

**Why Used:** Provides customer/supplier specific tools for copilot.

---

#### `app/ai_tools/invoice_tools.py`
**Contains:**
- `get_invoice(invoice_id, business_id)`

**Why Used:** Provides invoice lookup tool for copilot.

---

#### `app/ai_tools/reminder_tools.py`
**Contains:**
- `create_reminder(user_id, business_id, title, description, due_at)`

**Why Used:** Allows copilot to create reminders from voice/text commands.

---

#### `app/ai_tools/analytics_tools.py`
**Contains:**
- `get_anomalies(user_id)`
- `get_insights(user_id)`
- `get_business_summary(user_id, business_id)`

**Why Used:** Provides analytics tools for copilot. Aggregates multiple financial metrics.

---

## Feature Implementation Status

### Phase 1 — FastAPI Foundation ✅
- **Files:** `app/main.py`, `app/database/mongodb.py`, `app/database/indexes.py`
- **Features:** FastAPI app, CORS, health endpoints, Swagger docs, DB indexes

### Phase 2 — MongoDB Atlas ✅
- **Files:** `app/database/mongodb.py`
- **Features:** MongoDB connection, env validation, `vyaparai` database

### Phase 3 — JWT Authentication ✅
- **Files:** `app/core/security.py`, `app/api/auth.py`, `app/api/users.py`
- **Features:** bcrypt hashing, JWT tokens, login endpoint, protected routes

### Phase 4 — Invoice Management ✅
- **Files:** `app/models/invoice.py`, `app/schemas/invoice.py`, `app/api/invoices.py`
- **Features:** Invoice CRUD, payment tracking, status updates, payment application

### Phase 5 — Transaction Management ✅
- **Files:** `app/models/transaction.py`, `app/schemas/transaction.py`, `app/api/transactions.py`
- **Features:** Transaction CRUD, summary aggregation, date filtering

### Phase 6 — OCR Invoice Extraction ✅
- **Files:** `app/services/ocr_service.py`, `app/services/invoice_extractor.py`, `app/api/ocr.py`
- **Features:** Image validation, OCR extraction, regex-based field extraction, simulation mode

### Phase 7 — UPI Payment Intelligence ✅
- **Files:** `app/services/payment_extractor.py`, `app/services/invoice_matching.py`, `app/services/payment_processing.py`
- **Features:** Payment extraction, invoice matching, duplicate detection, payment recording

### Phase 8 — Financial Intelligence Foundation ✅
- **Files:** `app/services/financial_service.py` (partial), `app/schemas/financial.py`, `app/api/financials.py`
- **Features:** Income, expenses, profit, receivables, liabilities, cash position

### Phase 9 — Cash-Flow Intelligence ✅
- **Files:** `app/services/cashflow_service.py`
- **Features:** Cash flow forecast with risk indicator

### Phase 10 — Reconciliation Intelligence ✅
- **Files:** `app/services/reconciliation_service.py`
- **Features:** Receivable aging, customer summary, supplier summary

### Phase 11 — Anomaly Detection ✅
- **Files:** `app/services/anomaly_service.py`
- **Features:** Duplicate invoices, overpayments, unusual expenses

### Phase 12 — Insights Engine ✅
- **Files:** `app/services/insight_service.py`
- **Features:** Revenue trends, expense trends, receivable alerts, cash-flow warnings, anomaly flags

### Phase 13 — AI Tool Layer ✅
- **Files:** `app/ai_tools/` (all 5 files)
- **Features:** Backend tool wrappers for financial, customer, invoice, reminder, and analytics operations

### Phase 14 — AI Copilot (Text First) ✅
- **Files:** `app/schemas/copilot.py`, `app/services/copilot_service.py`, `app/api/copilot.py`
- **Features:** Rule-based intent classification, tool execution, natural language answers

### Phase 15 — Voice Backend ✅
- **Files:** `app/schemas/voice.py`, `app/services/voice_service.py`, `app/api/voice.py`
- **Features:** Bot activation, language detection, morning briefing, voice-to-copilot pipeline

### Phase 16 — Reminders + Notifications ✅
- **Files:** `app/schemas/reminder.py`, `app/services/reminder_service.py`, `app/services/notification_service.py`, `app/api/reminders.py`, `app/api/notifications.py`
- **Features:** Reminder CRUD, morning briefing, notifications list, mark as read

---

## API Endpoints Summary

### Authentication
- `POST /auth/login` — Login, returns JWT

### Users
- `POST /users/` — Create user

### Businesses
- `POST /businesses/` — Create business

### Invoices
- `POST /invoices/` — Create invoice
- `GET /invoices/` — List invoices
- `GET /invoices/{id}` — Get invoice
- `PUT /invoices/{id}` — Update invoice
- `DELETE /invoices/{id}` — Delete invoice
- `PATCH /invoices/{id}/status` — Update status
- `POST /invoices/{id}/payments` — Apply payment

### Transactions
- `GET /transactions/` — List transactions
- `GET /transactions/{id}` — Get transaction
- `POST /transactions/` — Create transaction
- `PUT /transactions/{id}` — Update transaction
- `DELETE /transactions/{id}` — Delete transaction
- `GET /transactions/summary` — Transaction summary

### OCR
- `POST /ocr/invoice` — Extract invoice from image
- `POST /ocr/invoice/confirm` — Confirm and save invoice
- `POST /ocr/payment` — Extract payment from image
- `POST /ocr/payment/confirm` — Confirm and record payment

### Financials
- `GET /financials/income/{today,week,month}`
- `GET /financials/expenses/{today,week,month}`
- `GET /financials/profit/{today,week,month}`
- `GET /financials/receivables`
- `GET /financials/receivables/overdue`
- `GET /financials/receivables/customer/{id}`
- `GET /financials/receivables/aging`
- `GET /financials/receivables/customer-summary`
- `GET /financials/liabilities`
- `GET /financials/liabilities/upcoming`
- `GET /financials/liabilities/overdue`
- `GET /financials/liabilities/supplier-summary`
- `GET /financials/anomalies`
- `GET /financials/insights`
- `GET /financials/cash-flow`
- `GET /financials/cash-position`

### Copilot
- `POST /copilot/chat` — Text chat with AI copilot

### Voice
- `POST /voice/query` — Voice query (requires bot activation)

### Reminders
- `GET /reminders/morning-briefing` — Morning briefing
- `POST /reminders/` — Create reminder
- `GET /reminders/` — List reminders
- `GET /reminders/{id}` — Get reminder
- `PATCH /reminders/{id}` — Update reminder
- `DELETE /reminders/{id}` — Delete reminder

### Notifications
- `GET /notifications/` — List notifications
- `PATCH /notifications/{id}/read` — Mark as read

### Health
- `GET /` — Root
- `GET /health` — Health check
- `GET /health/database` — Database health check

---

## Database Collections

| Collection | Purpose | Key Fields |
|------------|---------|------------|
| `users` | User accounts | email (unique), password_hash, name |
| `businesses` | Business entities | owner_id, name, business_type |
| `invoices` | Invoice records | business_id, customer_name, amount, paid_amount, outstanding_amount, status, due_date |
| `transactions` | Financial transactions | business_id, type, amount, category, date, source |
| `reminders` | User reminders | user_id, business_id, title, description, due_at, status |
| `notifications` | In-app notifications | user_id, business_id, type, title, message, read |

---

## Environment Variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `MONGODB_URL` | Yes | MongoDB Atlas connection string |
| `DATABASE_NAME` | No | Database name (default: `vyaparai`) |
| `JWT_SECRET` | Yes | Secret key for JWT signing |
| `JWT_ALGORITHM` | No | JWT algorithm (default: `HS256`) |
| `JWT_EXPIRE_MINUTES` | No | Token expiry in minutes (default: `60`) |
| `OCR_SIMULATION_MODE` | No | Enable OCR simulation (default: `false`) |
| `TESSERACT_CMD` | No | Path to tesseract binary |
| `VOICE_SIMULATION_MODE` | No | Enable voice simulation (default: `true`) |

---

## Key Design Patterns

1. **Dependency Injection:** `get_current_user` used across all protected endpoints
2. **Document Builders:** Models return dicts, not classes
3. **Service Layer:** All business logic in services, no logic in routers
4. **Tool Layer:** AI tools wrap services for copilot consumption
5. **Multi-tenancy:** Every query filters by `business_id` or `user_id`
6. **Deterministic Finance:** All financial calculations in `FinancialService`, never in LLM
7. **Error Handling:** HTTPException with appropriate status codes
8. **Validation:** Pydantic schemas for all inputs

---

## Production Readiness Checklist

- ✅ All endpoints have error handling
- ✅ All protected routes use `get_current_user`
- ✅ Business ownership verified on sensitive operations
- ✅ Input validation via Pydantic schemas
- ✅ MongoDB indexes for performance
- ✅ No hardcoded secrets
- ✅ Clean separation: routers → services → tools → DB
- ✅ Financial calculations deterministic, not LLM-based
- ✅ Multi-tenant data isolation
- ✅ Compilation verified, all imports resolve
