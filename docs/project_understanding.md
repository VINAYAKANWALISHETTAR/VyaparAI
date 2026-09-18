# VyaparAI — Project Understanding & Implementation Plan

## Product Vision

VyaparAI is an AI-powered financial copilot for small Indian businesses. It converts fragmented financial information — UPI screenshots, invoices, receipts, voice notes, handwritten records — into structured data, then provides intelligent answers through chat and voice.

**Core promise:** The business owner doesn't have to manually enter every transaction. They can simply ask VyaparaAI questions and receive actionable financial intelligence.

---

## Current Implementation Status

### Completed (Phases 1–7)

| Phase | Feature | Status |
|-------|---------|--------|
| 1 | FastAPI foundation, health, Swagger | Done |
| 2 | MongoDB Atlas connection | Done |
| 3 | JWT authentication, bcrypt, protected APIs | Done |
| 4 | Invoice management + payment tracking | Done |
| 5 | Transaction management + summary | Done |
| 6 | OCR document intelligence (invoice extraction) | Done |
| 7 | UPI/payment screenshot intelligence + reconciliation | Done |

### Current API surface

- `GET /`, `GET /health`, `GET /health/database`
- `POST /users/`, `POST /auth/login`
- `POST /businesses/`, `GET /businesses/`, `GET /businesses/{id}`, `PUT /businesses/{id}`, `DELETE /businesses/{id}`
- `POST /invoices/`, `GET /invoices/`, `GET /invoices/{id}`, `PUT /invoices/{id}`, `DELETE /invoices/{id}`, `PATCH /invoices/{id}/status`, `POST /invoices/{id}/payments`
- `POST /transactions/`, `GET /transactions/`, `GET /transactions/{id}`, `PUT /transactions/{id}`, `DELETE /transactions/{id}`, `GET /transactions/summary`
- `POST /ocr/invoice`, `POST /ocr/invoice/confirm`
- `POST /ocr/payment`, `POST /ocr/payment/confirm`

### What exists today

- User registration + JWT login
- Business ownership verification
- Invoice CRUD with payment tracking
- Transaction CRUD with summary
- OCR invoice extraction with simulation mode
- OCR payment extraction with matching + reconciliation
- Partial payments, overpayment review, duplicate detection

### What is NOT yet built

- Financial intelligence calculations
- Cash-flow forecasting
- Anomaly detection
- Insights engine
- AI copilot / Q&A
- Voice backend
- Reminders
- Dashboard/report APIs
- Mobile app

---

## Key Technical Decisions

| Decision | Choice |
|----------|--------|
| Database | Keep MongoDB Atlas |
| Next priority | Financial intelligence → AI tool layer → copilot → voice |
| LLM approach | Hybrid: own AI workflow as product layer; strong API model for reasoning; local/open models where feasible |
| STT/TTS | Whisper-family for transcription; TTS API initially; abstract behind interfaces |
| Mobile app | Separate frontend repo/directory from backend |
| MVP languages | English + Hindi + Kannada |
| Anomaly detection | Rule/statistical based first; ML later |
| Reports | In-app first → PDF second → Excel later |

---

## Corrected Implementation Order

The critical rule is:

**Build the brain before the mouth.**

The voice agent should sit on top of a stable financial intelligence and tool layer. Do not build voice first and then try to make it understand finances.

### Phase 8 — Financial Intelligence Foundation

Build deterministic financial calculations first.

Endpoints to add:

- `GET /financials/income/today`
- `GET /financials/income/week`
- `GET /financials/income/month`
- `GET /financials/expenses/today`
- `GET /financials/expenses/week`
- `GET /GET /financials/expenses/month`
- `GET /financials/profit/today`
- `GET /financials/profit/week`
- `GET /financials/profit/month`
- `GET /financials/receivables`
- `GET /financials/receivables/overdue`
- `GET /financials/receivables/customer/{customer_id}`
- `GET /financials/liabilities`
- `GET /financials/liabilities/upcoming`
- `GET /financials/liabilities/overdue`
- `GET /financials/cash-position`

Key terminology:
- Use **recorded cash position**, not “bank balance”, because the system cannot know money outside recorded data.

### Phase 9 — Cash-Flow Intelligence

- `GET /financials/cash-flow?days=7`
- Combine current cash + expected receivables - upcoming liabilities
- Return projected balance + risk indicator

### Phase 10 — Reconciliation Intelligence

- Smarter payment-to-invoice reconciliation
- Customer/supplier-level outstanding aggregation
- Receivable aging

### Phase 11 — Anomaly Detection

Rule/statistical based first:
- Unusual amount vs. historical average
- Duplicate invoice numbers
- Payment > invoice amount
- Due date < invoice date
- Unusually large expense

Return:
- “This transaction appears unusual. Please review it.”
- NOT “This transaction is fraudulent.”

### Phase 12 — Insights Engine

Generate deterministic insights from financial data:
- Revenue trend
- Expense trend
- Receivable alerts
- Cash-flow warnings
- Anomaly flags

Architecture:
- MongoDB → Financial services → Insight engine → Insight objects
- NOT MongoDB → LLM → random insight

### Phase 13 — AI Tool Layer

Create backend tools that the copilot can call:

- `get_today_income()`
- `get_today_expenses()`
- `get_today_profit()`
- `get_cash_position()`
- `get_receivables()`
- `get_overdue_receivables()`
- `get_liabilities()`
- `get_upcoming_liabilities()`
- `get_customer_balance(customer)`
- `get_supplier_balance(supplier)`
- `get_invoice(invoice)`
- `get_payment_history(customer)`
- `get_cash_flow_forecast(days)`
- `get_anomalies()`
- `get_insights()`
- `get_business_summary()`
- `create_transaction()`
- `create_receivable()`
- `create_liability()`
- `create_reminder()`

These are backend functions, not necessarily public REST APIs.

### Phase 14 — AI Copilot (Text First)

Make text Q&A reliable before adding voice.

Endpoints:
- `POST /copilot/query`

Flow:
1. User sends question
2. LLM identifies intent
3. Backend calls appropriate financial tool
4. Backend calculates verified result
5. LLM generates natural-language explanation

Example:
> “What is my profit today?”

Backend:
- LLM chooses `get_today_profit()`
- Financial engine calculates `₹26,300`
- LLM explains: “Your recorded profit today is ₹26,300.”

Critical rule: LLM never becomes the financial source of truth.

### Phase 15 — Voice Backend

Add voice only after copilot works.

- `POST /voice/query` — accept audio, return answer
- STT: Whisper-family or equivalent
- TTS: API initially; abstract behind interface
- Language pipeline: English + Hindi + Kannada for MVP

Architecture:
- Audio → STT → text → copilot → answer → TTS → audio

Wake word:
- Detect on device/mobile side
- Send only recognized voice queries to backend

### Phase 16 — Reminders + Notifications

- `POST /reminders/`
- `GET /reminders/`
- `PATCH /reminders/{id}/complete`
- Support payment reminders, follow-ups

### Phase 17 — Dashboard + Reports

- `GET /dashboard` — aggregated data for mobile dashboard
- In-app reports: daily, weekly, monthly
- PDF export later
- Excel export later

### Phase 18 — Mobile Application

Start only after backend milestone is stable.

Separate repo/directory:
- `backend/` — FastAPI + MongoDB + AI
- `mobile/` — React Native / Expo

Mobile consumes:
- Dashboard API
- Financial APIs
- Copilot API
- Voice API
- Reminders API

---

## Final Backend Milestone Before Mobile

Backend is ready for mobile when:

- [x] Auth, users, businesses
- [x] Invoices + payments
- [x] Transactions
- [x] OCR invoice + payment
- [ ] Financial calculations (income, expense, profit, receivables, liabilities, cash position)
- [ ] Cash-flow forecast
- [ ] Anomaly detection
- [ ] Insights engine
- [ ] AI tool layer
- [ ] Copilot Q&A
- [ ] Voice API
- [ ] Reminders
- [ ] Dashboard API

---

## Architecture Principles

1. **AI extracts, backend decides** — LLM proposes, backend validates before storage
2. **No direct LLM-to-database writes** — all data through validation + business rules
3. **Financial engine before voice** — build brain before mouth
4. **LLM never controls money** — deterministic calculations only
5. **Business isolation** — strict user-to-business access control
6. **Reusable services** — OCR, extraction, matching, processing as independent modules
7. **Provider abstraction** — LLM, STT, TTS behind interfaces for future swapping

---

## Current Architecture

```
                         MOBILE APP (future)
                             │
              ┌──────────────┼──────────────┐
              │              │              │
           Camera          Voice           Chat
              │              │              │
              └──────────────┼──────────────┘
                           FASTAPI
       ┌─────────────────────┼─────────────────────┐
       │                     │                     │
 Authentication         Input Processing       Copilot
       │                     │                     │
       │                ┌────┴────┐                │
       │               OCR       STT               │
       │                │         │                │
       └────────────────┼─────────┼────────────────┘
                        │
                  AI ORCHESTRATOR
                        │
                 ┌──────┴──────┐
                 │             │
              Intent        Tool Router
                 │             │
                 └──────┬──────┘
                        │
                BUSINESS SERVICES
                        │
       ┌────────────────┼────────────────┐
       │                │                │
   Transactions      Invoices        Payments
       │                │                │
       ├────────────────┼────────────────┤
       │                │                │
   Customers        Suppliers       Reconciliation
       │                │                │
       └────────────────┼────────────────┘
                        │
                     MONGODB
                        │
                FINANCIAL ENGINE
                        │
        ┌───────────────┼────────────────┐
        │               │                │
      Profit         Cash Flow       Receivables
        │               │                │
        ├───────────────┼────────────────┤
        │               │                │
    Anomalies        Insights        Forecasting
        │               │                │
        └───────────────┼────────────────┘
                        │
                 BUSINESS MEMORY
                        │
                  AI COPILOT
                        │
              ┌─────────┴─────────┐
              │                   │
             CHAT                VOICE
              │                   │
              └─────────┬─────────┘
                        │
                   TTS / RESPONSE
                        │
                     USER
```

---

## Immediate Next Task

**Phase 8: Financial Intelligence Foundation**

Do not touch mobile app yet.

Build:
- Income calculations
- Expense calculations
- Profit calculations
- Receivables
- Liabilities
- Cash position

Then proceed through Phases 9–17 in order.

---

## Open Questions

None at this stage. All technical decisions have been made.
