# VyaparAI — Backend Implementation Plan

## Backend Vision

The backend sits between the mobile app and the intelligence layer. FastAPI is the orchestration/API layer, MongoDB is the persistent business-data layer, and the AI/financial engines sit between them.

### Architecture Layers
- Mobile App → FastAPI Backend → Validation Engine → Business Engine → Financial Intelligence → Business Memory → AI Copilot Engine → User Response
- AI understands intent and unstructured information
- Financial engine calculates money deterministically
- MongoDB stores structured business truth
- FastAPI orchestrates everything
- Business Memory personalizes the system over time

### Key Principle
**Build the brain before the mouth.** Voice agent sits on top of stable financial intelligence and tool layer.

---

## Phase Status

| Phase | Feature | Status |
|-------|---------|--------|
| 1 | FastAPI foundation, health, Swagger | Done |
| 2 | MongoDB Atlas connection | Done |
| 3 | JWT authentication, bcrypt, protected APIs | Done |
| 4 | Invoice management + payment tracking | Done |
| 5 | Transaction management + summary | Done |
| 6 | OCR document intelligence (invoice extraction) | Done |
| 7 | UPI/payment screenshot intelligence + reconciliation | Done |
| 8 | Financial Intelligence Foundation | Done |
| 9 | Cash-Flow Intelligence | Done |
| 10 | Reconciliation Intelligence | Done |
| 11 | Anomaly Detection | Done |
| 12 | Insights Engine | Done |
| 13 | AI Tool Layer | Done |
| 14 | AI Copilot (Text First) | Pending |
| 15 | Voice Backend | Pending |
| 16 | Reminders + Notifications | Pending |
| 17 | Dashboard + Reports | Pending |
| 18 | Mobile Application | Pending |

---

## Current API Surface (Phases 1–11)

- `GET /`, `GET /health`, `GET /health/database`
- `POST /users/`, `POST /auth/login`
- `POST /businesses/`, `GET /businesses/`, `GET /businesses/{id}`, `PUT /businesses/{id}`, `DELETE /businesses/{id}`
- `POST /invoices/`, `GET /invoices/`, `GET /invoices/{id}`, `PUT /invoices/{id}`, `DELETE /invoices/{id}`, `PATCH /invoices/{id}/status`, `POST /invoices/{id}/payments`
- `POST /transactions/`, `GET /transactions/`, `GET /transactions/{id}`, `PUT /transactions/{id}`, `DELETE /transactions/{id}`, `GET /transactions/summary`
- `POST /ocr/invoice`, `POST /ocr/invoice/confirm`
- `POST /ocr/payment`, `POST /ocr/payment/confirm`
- `GET /financials/income/{today,week,month}`
- `GET /financials/expenses/{today,week,month}`
- `GET /financials/profit/{today,week,month}`
- `GET /financials/receivables`, `GET /financials/receivables/overdue`, `GET /financials/receivables/customer/{customer_id}`, `GET /financials/receivables/aging`, `GET /financials/receivables/customer-summary`
- `GET /financials/liabilities`, `GET /financials/liabilities/upcoming`, `GET /financials/liabilities/overdue`, `GET /financials/liabilities/supplier-summary`
- `GET /financials/cash-position`
- `GET /financials/cash-flow`
- `GET /financials/anomalies`
- `GET /financials/insights`

## Phase 13 — AI Tool Layer

**Goal:** Create backend tools that the copilot can call.

**Architecture:** Router → AI Service → AI Tools → Business Services → Repositories → MongoDB

**New Files:**
- `backend/app/ai_tools/__init__.py`
- `backend/app/ai_tools/financial_tools.py`
- `backend/app/ai_tools/customer_tools.py`
- `backend/app/ai_tools/invoice_tools.py`
- `backend/app/ai_tools/reminder_tools.py`
- `backend/app/ai_tools/analytics_tools.py`

**Tools implemented:**
- `get_today_income(business_id, user_id)`
- `get_today_expenses(business_id, user_id)`
- `get_today_profit(business_id, user_id)`
- `get_cash_position(user_id)`
- `get_receivables(business_id, user_id, overdue_only, customer_id)`
- `get_overdue_receivables(business_id, user_id)`
- `get_liabilities(user_id, upcoming_only, overdue_only)`
- `get_upcoming_liabilities(user_id)`
- `get_cash_flow_forecast(user_id, days)`
- `get_customer_balance(customer_name, business_id, user_id)`
- `get_supplier_balance(supplier_name, business_id, user_id)`
- `get_payment_history(customer_name, business_id, user_id)`
- `get_invoice(invoice_id, business_id)`
- `get_anomalies(user_id)`
- `get_insights(user_id)`
- `get_business_summary(user_id, business_id)`
- `create_reminder(user_id, business_id, title, description, due_at)`

These are backend functions, not public REST APIs.

---

## Phase 14 — AI Copilot (Text First)

**Goal:** Make text Q&A reliable before adding voice.

**New Files:**
- `backend/app/schemas/copilot.py`
- `backend/app/services/copilot_service.py`
- `backend/app/api/copilot.py`

**Endpoints:**
- `POST /copilot/chat`

**Flow:**
1. User sends question
2. LLM identifies intent
3. Backend calls appropriate financial tool
4. Backend calculates verified result
5. LLM generates natural-language explanation

**Critical rule:** LLM never becomes the financial source of truth.

---

## Phase 15 — Voice Backend

**Goal:** Add voice only after copilot works.

**New Files:**
- `backend/app/schemas/voice.py`
- `backend/app/services/voice_service.py`
- `backend/app/api/voice.py`

**Endpoints:**
- `POST /voice/query` — accept audio, return answer

**Pipeline:** Audio → STT → text → copilot → answer → TTS → audio

**Languages:** English + Hindi + Kannada for MVP

---

## Phase 16 — Reminders + Notifications

**Goal:** Build reminder and notification system.

**New Files:**
- `backend/app/schemas/reminder.py`
- `backend/app/services/reminder_service.py`
- `backend/app/api/reminders.py`

**Endpoints:**
- `POST /reminders/`
- `GET /reminders/`
- `PATCH /reminders/{id}/complete`

**Notification Types:**
- payment_due
- payment_overdue
- cash_flow_warning
- unusual_transaction
- reminder

---

## Phase 17 — Dashboard + Reports

**Goal:** Build dashboard and reporting APIs.

**New Files:**
- `backend/app/schemas/dashboard.py`
- `backend/app/services/dashboard_service.py`
- `backend/app/api/dashboard.py`

**Endpoints:**
- `GET /dashboard` — aggregated data for mobile dashboard
- `GET /reports/daily`
- `GET /reports/weekly`
- `GET /reports/monthly`

**Report Order:** In-app first → PDF second → Excel later

---

## Phase 18 — Mobile Application

**Goal:** Start only after backend milestone is stable.

Separate repo/directory:
- `backend/` — FastAPI + MongoDB + AI
- `mobile/` — React Native / Expo

---

## MongoDB Collections

vyaparai
├── users
├── businesses
├── business_members
├── customers
├── suppliers
├── invoices
├── invoice_items
├── transactions
├── payments
├── expenses
├── liabilities
├── financial_accounts
├── reconciliations
├── files
├── extraction_results
├── ai_interactions
├── reminders
├── notifications
├── forecasts
├── anomalies
├── insights
├── business_memory
├── user_preferences
├── reports
├── report_jobs
├── audit_logs
└── system_events

---

## Key Technical Decisions

| Decision | Choice |
|----------|--------|
| Database | MongoDB Atlas |
| API versioning | `/api/v1/...` |
| LLM approach | Hybrid: own AI workflow as product layer |
| STT/TTS | Whisper-family for transcription; TTS API initially |
| Mobile app | Separate frontend repo |
| MVP languages | English + Hindi + Kannada |
| Anomaly detection | Rule/statistical based first; ML later |
| Reports | In-app first → PDF second → Excel later |

---

## Implementation Order

1. Complete Phase 8 Financial Intelligence Foundation
2. Complete Phase 9 Cash-Flow Intelligence
3. Complete Phase 10 Reconciliation Intelligence
4. Complete Phase 11 Anomaly Detection
5. Complete Phase 12 Insights Engine
6. Complete Phase 13 AI Tool Layer
7. Complete Phase 14 AI Copilot
8. Complete Phase 15 Voice Backend
9. Complete Phase 16 Reminders + Notifications
10. Complete Phase 17 Dashboard + Reports
11. Complete Phase 18 Mobile Application

Each phase will be implemented, tested, committed, and pushed before proceeding to the next.
