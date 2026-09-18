# VyaparAI — AI Financial Copilot for Small Businesses

<p align="center">
  <strong>Your Business Brain in Your Pocket</strong>
</p>

VyaparAI is an AI-powered financial copilot built specifically for small Indian businesses. It transforms fragmented financial information — UPI screenshots, invoices, receipts, voice notes, and handwritten records — into structured, actionable business intelligence.

Instead of forcing business owners to manually maintain complicated accounting records, VyaparAI understands their existing financial data and lets them simply ask questions to get answers.

---

## Problem

Small businesses in India operate with financial information scattered across UPI apps, WhatsApp, bank notifications, invoices, receipts, and handwritten bahi-khata records. Owners know individual transactions but rarely have a clear, real-time picture of:

- How much cash they actually have
- Who owes them money and since when
- What payments are pending
- Whether they will have enough money for upcoming obligations
- Where their money is going

This fragmentation makes it extremely difficult to make informed financial decisions.

---

## Solution

VyaparAI acts as a **business-aware AI layer** on top of existing financial data. It captures information from multiple sources, extracts structured data, reconciles transactions, and provides natural-language answers through both chat and voice.

### Core Pipeline

```
Camera / Screenshot / Voice / Document
            ↓
       OCR / Speech AI
            ↓
      Structured Extraction
            ↓
       Validation Engine
            ↓
      Financial Database
            ↓
      Financial Intelligence
            ↓
         AI Copilot
            ↓
    Answer / Insight / Action
```

---

## Key Features

### Data Capture
- **Invoice scanning** — photograph invoices, extract structured data
- **UPI/payment screenshot processing** — extract payment details, match to invoices
- **Receipt scanning** — capture expenses automatically
- **Handwritten record understanding** — digitize bahi-khata entries
- **Voice input** — speak naturally in regional languages
- **Manual entry** — direct transaction creation

### AI Understanding
- **OCR engine** — Tesseract-based with preprocessing pipeline
- **Invoice extraction** — invoice number, customer, dates, amounts, tax
- **Payment extraction** — amount, sender/receiver, reference, status, direction
- **Duplicate detection** — prevent duplicate invoices and payments
- **Invoice matching** — match payments to outstanding invoices automatically
- **Simulation mode** — test without Tesseract installed

### Financial Management
- **Invoice lifecycle** — create, update, track, and manage invoices
- **Payment tracking** — partial payments, full payments, outstanding amounts
- **Transaction management** — income, expenses, categorization
- **Business ownership** — strict user-to-business isolation
- **JWT authentication** — secure API access

### Payment Intelligence
- **UPI screenshot processing** — extract payment information
- **Invoice reconciliation** — automatically match payments to invoices
- **Partial payment support** — track installment payments
- **Overpayment detection** — flag payments exceeding invoice amount
- **Duplicate prevention** — block duplicate payment references

### Financial Intelligence
- **Real-time summaries** — income, expenses, net cash flow
- **Transaction filtering** — by type, category, date range, source
- **Payment status tracking** — unpaid, partially paid, paid, overdue
- **Business metrics** — per-business financial aggregation

### Architecture
- **Modular design** — models, schemas, services, APIs separated
- **Reusable services** — OCR, extraction, matching, processing
- **Type-safe** — Pydantic validation throughout
- **Secure** — JWT auth, business ownership verification, input validation

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | FastAPI |
| **Database** | MongoDB Atlas |
| **ODM** | PyMongo |
| **Authentication** | JWT + bcrypt |
| **Validation** | Pydantic |
| **OCR** | Tesseract + Pillow |
| **Language** | Python 3.10+ |
| **Server** | Uvicorn |

---

## Project Structure

```
backend/
└── app/
    ├── api/
    │   ├── auth.py              # Authentication endpoints
    │   ├── users.py             # User management
    │   ├── businesses.py        # Business CRUD
    │   ├── invoices.py          # Invoice management + payments
    │   ├── transactions.py      # Transaction management
    │   └── ocr.py               # OCR endpoints (invoice + payment)
    ├── core/
    │   └── security.py          # JWT utilities
    ├── database/
    │   ├── mongodb.py           # MongoDB connection
    │   └── indexes.py           # Database indexes
    ├── models/
    │   ├── user.py              # User document builder
    │   ├── business.py          # Business document builder
    │   ├── invoice.py           # Invoice document builder
    │   └── transaction.py       # Transaction document builder
    ├── schemas/
    │   ├── invoice.py           # Invoice Pydantic schemas
    │   └── ocr.py               # OCR/Payment schemas
    ├── services/
    │   ├── ocr_service.py       # OCR abstraction
    │   ├── invoice_extractor.py # Invoice field extraction
    │   ├── payment_extractor.py # Payment field extraction
    │   ├── invoice_matching.py  # Invoice-payment matching
    │   └── payment_processing.py# Payment recording logic
    └── main.py                  # FastAPI application
```

---

## Getting Started

### Prerequisites

- Python 3.10+
- MongoDB Atlas account
- Tesseract OCR (optional, simulation mode available)

### Installation

```bash
# Clone repository
git clone https://github.com/VINAYAKANWALISHETTAR/VyaparAI.git
cd VyaparAI/backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
# or source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt
```

### Environment Setup

Create `.env` file in `backend/app/`:

```env
MONGODB_URL=mongodb+srv://<user>:<password>@cluster0.s4ybtgh.mongodb.net/?appName=Cluster0
DATABASE_NAME=vyaparai
JWT_SECRET=your-secret-key-here
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=1440
```

### Running the Server

```bash
# From backend directory
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Server will start at `http://localhost:8000`

### OCR Simulation Mode

For testing without Tesseract:

```bash
# Windows PowerShell
$env:OCR_SIMULATION_MODE="true"

# Linux/Mac
export OCR_SIMULATION_MODE=true
```

---

## API Documentation

### Interactive Docs

Open `http://localhost:8000/docs` for Swagger UI.

### Authentication

All endpoints except `/auth/login` and `/users/` require JWT:

```
Authorization: Bearer <access_token>
```

### Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/users/` | Register user |
| `POST` | `/auth/login` | Login, get JWT |
| `POST` | `/businesses/` | Create business |
| `GET` | `/businesses/` | List user's businesses |
| `POST` | `/invoices/` | Create invoice |
| `GET` | `/invoices/` | List invoices |
| `POST` | `/invoices/{id}/payments` | Record payment |
| `POST` | `/transactions/` | Create transaction |
| `GET` | `/transactions/summary` | Financial summary |
| `POST` | `/ocr/invoice` | Extract invoice from image |
| `POST` | `/ocr/invoice/confirm` | Confirm and save invoice |
| `POST` | `/ocr/payment` | Extract payment from image |
| `POST` | `/ocr/payment/confirm` | Confirm and record payment |

---

## Example Workflows

### 1. Create Invoice

```bash
curl -X POST "http://localhost:8000/invoices/" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "YOUR_BUSINESS_ID",
    "customer_name": "ABC Traders",
    "invoice_number": "INV-001",
    "amount": 18000,
    "due_date": "2026-09-20",
    "description": "Monthly stock supply"
  }'
```

### 2. Upload UPI Screenshot

```bash
curl -X POST "http://localhost:8000/ocr/payment" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "business_id=YOUR_BUSINESS_ID" \
  -F "file=@payment_screenshot.png"
```

### 3. Confirm Payment

```bash
curl -X POST "http://localhost:8000/ocr/payment/confirm" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "YOUR_BUSINESS_ID",
    "invoice_id": "INVOICE_ID",
    "amount": 8000,
    "transaction_reference": "UPI123456",
    "source": "upi",
    "direction": "received"
  }'
```

---

## Testing

```bash
# Run with simulation mode
$env:OCR_SIMULATION_MODE="true"
python -m uvicorn app.main:app --reload
```

Then use Swagger UI at `http://localhost:8000/docs` to test all endpoints.

---

## Architecture Principles

1. **AI extracts, backend decides** — LLM proposes structured data, backend validates before storage
2. **No direct LLM-to-database writes** — all data goes through Pydantic validation and business rules
3. **Financial engine before voice** — build brain before mouth; voice sits on top of stable financial intelligence
4. **LLM never controls money** — deterministic financial calculations only; LLM explains results
5. **Business isolation** — users can only access their own businesses and data
6. **Reusable services** — OCR, extraction, matching, processing are independent modules
7. **Provider abstraction** — LLM, STT, TTS behind interfaces for future swapping

## Implementation Order

The correct sequence is:

```text
Phase 8:  Financial Intelligence Foundation
Phase 9:  Cash-Flow Intelligence
Phase 10: Reconciliation Intelligence
Phase 11: Anomaly Detection
Phase 12: Insights Engine
Phase 13: AI Tool Layer
Phase 14: AI Copilot (Text Q&A)
Phase 15: Voice Backend
Phase 16: Reminders + Notifications
Phase 17: Dashboard + Reports
Phase 18: Mobile Application
```

**Key principle:** Build the financial brain before the voice mouth. The voice agent should sit on top of a stable financial intelligence layer.

## Database Strategy

**Keep MongoDB Atlas.** There is no compelling reason to migrate to PostgreSQL at this stage. The existing MongoDB backend is already working and supports the required flexibility for document-based financial records.

## Mobile Application

The mobile app will be a separate repository/directory that consumes the backend APIs. Do not start mobile development until the backend financial intelligence milestone is complete.

## AI & Speech Stack

- **LLM:** Hybrid architecture — own AI workflow as product layer; strong API model for reasoning; local/open models where feasible
- **STT:** Whisper-family transcription for MVP
- **TTS:** API initially; abstract behind interface for future swapping
- **Languages (MVP):** English + Hindi + Kannada
- **Anomaly Detection:** Rule/statistical based first; ML later
- **Reports:** In-app first → PDF second → Excel later

---

## Roadmap

### Completed
- [x] Phase 1: FastAPI Foundation
- [x] Phase 2: MongoDB Atlas Connection
- [x] Phase 3: JWT Authentication
- [x] Phase 4: Invoice Management
- [x] Phase 5: Transaction Management
- [x] Phase 6: OCR / Document Intelligence
- [x] Phase 7: UPI / Payment Screenshot Intelligence

### In Progress
- [ ] Phase 8: Financial Intelligence Foundation
- [ ] Phase 9: Cash-Flow Intelligence
- [ ] Phase 10: Reconciliation Intelligence
- [ ] Phase 11: Anomaly Detection
- [ ] Phase 12: Insights Engine
- [ ] Phase 13: AI Tool Layer
- [ ] Phase 14: AI Copilot (Text Q&A)
- [ ] Phase 15: Voice Backend
- [ ] Phase 16: Reminders + Notifications
- [ ] Phase 17: Dashboard + Reports
- [ ] Phase 18: Mobile Application

### Future
- [ ] Regional language expansion (English + Hindi + Kannada for MVP)
- [ ] PDF/Excel exports
- [ ] WhatsApp integration
- [ ] Bank statement parsing
- [ ] Advanced ML forecasting

---

## Contributing

This is a hackathon project. Contributions, issues, and feature requests are welcome.

---

## License

MIT

---

## Contact

For questions or collaboration, reach out through the project repository.

---

<p align="center">
  Built with FastAPI, MongoDB, and PyTesseract
</p>
