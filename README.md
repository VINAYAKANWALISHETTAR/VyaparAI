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
- **OCR engine** — PyTesseract + RapidOCR with preprocessing pipeline
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
- **Real-time summaries** — income, expenses, net cash flow for today/week/month
- **Transaction filtering** — by type, category, date range, source
- **Payment status tracking** — unpaid, partially paid, paid, overdue
- **Business metrics** — per-business financial aggregation
- **Cash-flow forecast** — projected balance with risk indicator
- **Receivable aging** — 0-30, 31-60, 61-90, 90+ day buckets
- **Anomaly detection** — duplicate invoices, overpayments, unusual expenses
- **Insights engine** — rule-based insights on revenue, expenses, receivables, cash flow
- **PDF reports** — ReportLab-generated downloadable statements

### AI Copilot & Voice
- **Text Q&A** — ask about profit, income, expenses, cash position, receivables, liabilities, invoices, customer balances
- **Voice assistant** — "Hey VyaparAI" wake phrase, trilingual support
- **Morning briefing** — spoken-style financial summary with notifications
- **Intent classification** — rule-based + Google Gemini NLP
- **Trilingual UI** — English, Hindi, Kannada with 100% parity

### Notifications & Reminders
- **Smart reminders** — scheduled follow-ups with sound alerts
- **Notification center** — reactive notification drawer
- **Morning briefing** — combined financial summary + notifications

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile Framework** | Flutter 3.44 |
| **Mobile State** | Riverpod + GoRouter |
| **Mobile Networking** | Dio |
| **Mobile Voice** | speech_to_text + flutter_tts |
| **Mobile Alerts** | flutter_local_notifications |
| **Backend Framework** | FastAPI |
| **Backend AI** | Google Gemini + custom NLP |
| **OCR** | PyTesseract + RapidOCR (ONNX Runtime) |
| **PDF Generation** | ReportLab |
| **Database** | MongoDB Atlas |
| **Authentication** | JWT + bcrypt |
| **Validation** | Pydantic |
| **Language** | Python 3.10+ / Dart 3.12 |
| **Server** | Uvicorn |

---

## Project Structure

```
backend/
└── app/
    ├── api/
    │   ├── auth.py                # Authentication endpoints
    │   ├── users.py               # User management
    │   ├── businesses.py          # Business CRUD
    │   ├── invoices.py            # Invoice management + payments
    │   ├── transactions.py        # Transaction management
    │   ├── ocr.py                 # OCR endpoints (invoice + payment)
    │   ├── financials.py          # Financial summaries, reports, PDF
    │   ├── copilot.py             # AI chat endpoint
    │   ├── voice.py               # Voice query endpoint
    │   ├── reminders.py           # Reminders CRUD + morning briefing
    │   └── notifications.py       # Notifications CRUD
    ├── core/
    │   └── security.py            # JWT utilities
    ├── database/
    │   ├── mongodb.py             # MongoDB connection
    │   ├── indexes.py             # Database indexes
    │   └── seed.py                # Default data seeding
    ├── models/                    # Document builders
    ├── schemas/                   # Pydantic schemas
    ├── services/                  # Business logic
    │   ├── ocr_service.py
    │   ├── invoice_extractor.py
    │   ├── payment_extractor.py
    │   ├── invoice_matching.py
    │   ├── payment_processing.py
    │   ├── financial_service.py
    │   ├── cashflow_service.py
    │   ├── reconciliation_service.py
    │   ├── anomaly_service.py
    │   ├── insight_service.py
    │   ├── copilot_service.py
    │   ├── voice_service.py
    │   ├── reminder_service.py
    │   ├── notification_service.py
    │   └── pdf_service.py
    ├── ai_tools/                  # AI tool definitions
    └── main.py                    # FastAPI application

mobile/
└── vypara_ai/
    └── lib/
        ├── main.dart
        ├── app/                  # App shell, routing, theme
        ├── core/                 # Network, storage, widgets, utils
        └── features/             # Feature modules
            ├── auth/             # Login, register, forgot password
            ├── home/             # Dashboard
            ├── invoices/         # Invoice list, create, details
            ├── transactions/     # Transaction list, create
            ├── records/          # OCR capture, review, confirm
            ├── voice/            # Voice query screen
            ├── ai_assistant/     # Copilot chat
            ├── cash_flow/        # Cash-flow forecast
            ├── reports/          # Financial reports + PDF download
            ├── reminders/        # Reminders list, create, edit
            ├── notifications/    # Notification center
            ├── insights/         # Insights list
            ├── customers/        # Customer management
            ├── suppliers/        # Supplier management
            ├── profile/          # User profile, business settings
            └── settings/         # App settings, language

website/
└── show_case/
    └── index.html                # Finalized landing page
```

---

## Getting Started

### Prerequisites

- Python 3.10+
- MongoDB Atlas account
- Tesseract OCR (optional, simulation mode available)
- Flutter 3.44+ (for mobile)

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

All endpoints except `/auth/login`, `/auth/register`, `/users/`, and `/auth/forgot-password` require JWT:

```
Authorization: Bearer <access_token>
```

### Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/auth/login` | Login, get JWT |
| `POST` | `/auth/register` | Register new user |
| `POST` | `/auth/forgot-password` | Request password reset |
| `POST` | `/auth/reset-password` | Reset password |
| `POST` | `/users/` | Create user |
| `GET` | `/users/me` | Get current user |
| `POST` | `/businesses/` | Create business |
| `GET` | `/businesses/` | List user's businesses |
| `POST` | `/invoices/` | Create invoice |
| `GET` | `/invoices/` | List invoices |
| `GET` | `/invoices/{id}` | Get invoice details |
| `PUT` | `/invoices/{id}` | Update invoice |
| `PATCH` | `/invoices/{id}/status` | Update invoice status |
| `DELETE` | `/invoices/{id}` | Delete invoice |
| `POST` | `/invoices/{id}/payments` | Apply payment to invoice |
| `POST` | `/transactions/` | Create transaction |
| `GET` | `/transactions/summary` | Transaction summary |
| `POST` | `/ocr/invoice` | Extract invoice from image |
| `POST` | `/ocr/invoice/confirm` | Confirm and save invoice |
| `POST` | `/ocr/payment` | Extract payment from image |
| `POST` | `/ocr/payment/confirm` | Confirm and record payment |
| `GET` | `/financials/income/{period}` | Income for period |
| `GET` | `/financials/expenses/{period}` | Expenses for period |
| `GET` | `/financials/profit/{period}` | Profit for period |
| `GET` | `/financials/report-overview/{period}` | Consolidated report overview |
| `GET` | `/financials/report-pdf/{period}` | Download PDF statement |
| `GET` | `/financials/cash-flow` | Cash-flow forecast |
| `GET` | `/financials/receivables/aging` | Receivable aging buckets |
| `GET` | `/financials/anomalies` | Unusual items list |
| `GET` | `/financials/insights` | Rule-based insights |
| `POST` | `/copilot/chat` | Ask copilot a question |
| `POST` | `/voice/query` | Voice query endpoint |
| `GET` | `/reminders/morning-briefing` | Morning briefing |
| `POST` | `/reminders/` | Create reminder |
| `GET` | `/reminders/` | List reminders |
| `GET` | `/reminders/{id}` | Get reminder |
| `PATCH` | `/reminders/{id}` | Update reminder |
| `DELETE` | `/reminders/{id}` | Delete reminder |
| `GET` | `/notifications/` | List notifications |
| `PATCH` | `/notifications/mark-all-read` | Mark all as read |
| `PATCH` | `/notifications/{id}/read` | Mark one as read |
| `DELETE` | `/notifications/{id}` | Delete notification |

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

### 4. Ask the Copilot

```bash
curl -X POST "http://localhost:8000/copilot/chat" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "YOUR_BUSINESS_ID",
    "message": "What is my profit today?"
  }'
```

### 5. Download Financial Report PDF

```bash
curl -X GET "http://localhost:8000/financials/report-pdf/month" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -o statement.pdf
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
Phase 1:  FastAPI Foundation
Phase 2:  MongoDB Atlas Connection
Phase 3:  JWT Authentication
Phase 4:  Invoice Management
Phase 5:  Transaction Management
Phase 6:  OCR / Document Intelligence
Phase 7:  UPI / Payment Screenshot Intelligence
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
Phase 19: Website Showcase
```

**Key principle:** Build the financial brain before the voice mouth. The voice agent should sit on top of a stable financial intelligence layer.

## Database Strategy

**Keep MongoDB Atlas.** There is no compelling reason to migrate to PostgreSQL at this stage. The existing MongoDB backend is already working and supports the required flexibility for document-based financial records.

## Mobile Application

The mobile app is a production Flutter application with 18 feature modules. It consumes the backend APIs and provides a native Android experience with trilingual support.

- **Framework:** Flutter 3.44 with Riverpod state management
- **Navigation:** GoRouter with auth guards
- **Networking:** Dio with JWT interceptors
- **Voice:** speech_to_text + flutter_tts
- **Notifications:** flutter_local_notifications with sound alerts
- **Files:** file_picker + open_filex + path_provider
- **Build:** 59 MB release APK, min SDK 21

## Website Showcase

The project includes a finalized showcase website at `website/show_case/index.html`:

- **Finalized landing page** with accurate tech stack and copy
- **Auto-advancing screenshot carousel** — cycles through app screenshots every 4 seconds
- **Tech stack section** — correct libraries and services
- **Download section** — APK download link, QR code, install instructions
- **Deployed:** View the showcase at the project website

## AI & Speech Stack

- **LLM:** Hybrid architecture — Google Gemini for NLP intent classification; custom rule-based classification for reliability
- **STT:** Platform speech recognition via speech_to_text plugin
- **TTS:** flutter_tts for spoken answers and morning briefing
- **Languages (MVP):** English + Hindi + Kannada
- **Anomaly Detection:** Rule/statistical based; three checks: duplicate invoices, payment above invoice, expense over 3x category average
- **Reports:** In-app first → ReportLab PDF → CSV export

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
- [x] Phase 8: Financial Intelligence Foundation
- [x] Phase 9: Cash-Flow Intelligence
- [x] Phase 10: Reconciliation Intelligence
- [x] Phase 11: Anomaly Detection
- [x] Phase 12: Insights Engine
- [x] Phase 13: AI Tool Layer
- [x] Phase 14: AI Copilot (Text Q&A)
- [x] Phase 15: Voice Backend
- [x] Phase 16: Reminders + Notifications
- [x] Phase 17: Dashboard + Reports
- [x] Phase 18: Mobile Application
- [x] Phase 19: Website Showcase

### Future
- [ ] WhatsApp direct bot integration
- [ ] Multi-GSTIN enterprise consolidation
- [ ] Cloud accounting integrations (Tally / Zoho sync)
- [ ] Advanced ML forecasting
- [ ] Bank statement parsing

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
  Built with FastAPI, MongoDB Atlas, Flutter, and PyTesseract
</p>
