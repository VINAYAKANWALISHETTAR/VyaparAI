# VyaparAI — Flutter Frontend Implementation Plan

## GOAL

Build a production-oriented Flutter mobile application that:
- Matches the reference design accurately
- Uses the existing FastAPI + MongoDB backend as the source of truth
- Follows the established feature-first Flutter architecture
- Never duplicates financial calculations on the device
- Never fakes backend integrations
- Clearly distinguishes: UI complete, API integrated, backend gap

---

## 1. BACKEND CAPABILITY MATRIX

### Verified from: `N:\VyaparAI\backend\app\`

| Feature | Backend API Exists | Endpoint Verified | Request Schema Verified | Response Schema Verified | Flutter Ready |
|---|---|---|---|---|---|
| Auth | Yes | Yes | Yes | Yes | Yes |
| Users | Yes | Yes | Yes | Partial | Yes |
| Businesses | Yes | Yes | Yes | Partial | Yes |
| Transactions | Yes | Yes | Yes | Yes | Yes |
| Transaction Summary | Yes | Yes | Yes | Yes | Yes |
| Invoices | Yes | Yes | Yes | Yes | Yes |
| Invoice Status | Yes | Yes | Yes | Yes | Yes |
| Invoice Payment | Yes | Yes | Yes | Yes | Yes |
| OCR Invoice Extract | Yes | Yes | Yes | Yes | Yes |
| OCR Invoice Confirm | Yes | Yes | Yes | Yes | Yes |
| OCR Payment Extract | Yes | Yes | Yes | Yes | Yes |
| OCR Payment Confirm | Yes | Yes | Yes | Yes | Yes |
| Financials Income | Yes | Yes | Yes | Yes | Yes |
| Financials Expenses | Yes | Yes | Yes | Yes | Yes |
| Financials Profit | Yes | Yes | Yes | Yes | Yes |
| Financials Receivables | Yes | Yes | Yes | Yes | Yes |
| Financials Receivables Overdue | Yes | Yes | Yes | Yes | Yes |
| Financials Receivables Aging | Yes | Yes | Yes | Yes | Yes |
| Financials Receivables Customer Summary | Yes | Yes | Yes | Yes | Yes |
| Financials Liabilities | Yes | Yes | Yes | Yes | Yes |
| Financials Liabilities Upcoming | Yes | Yes | Yes | Yes | Yes |
| Financials Liabilities Overdue | Yes | Yes | Yes | Yes | Yes |
| Financials Liabilities Supplier Summary | Yes | Yes | Yes | Yes | Yes |
| Financials Cash Position | Yes | Yes | Yes | Yes | Yes |
| Financials Cash Flow | Yes | Yes | Yes | Yes | Yes |
| Financials Anomalies | Yes | Yes | Yes | Yes | Yes |
| Financials Insights | Yes | Yes | Yes | Yes | Yes |
| Copilot Chat | Yes | Yes | Yes | Yes | Yes |
| Voice Query | Yes | Yes | Yes | Yes | Simulation mode |
| Reminders CRUD | Yes | Yes | Yes | Yes | Yes |
| Morning Briefing | Yes | Yes | Yes | Yes | Yes |
| Notifications List | Yes | Yes | Yes | Yes | Yes |
| Notifications Mark Read | Yes | Yes | Yes | Yes | Yes |
| Dashboard API | **No** | **No** | **No** | **No** | **BACKEND GAP** |
| Reports Daily/Weekly/Monthly | **No** | **No** | **No** | **No** | **BACKEND GAP** |
| Customers API | **No** | **No** | **No** | **No** | **BACKEND GAP** |
| Suppliers API | **No** | **No** | **No** | **No** | **BACKEND GAP** |
| Push Notifications (FCM/APNs) | **No** | **No** | **No** | **No** | **BACKEND GAP** |
| Localization Backend | **No** | **No** | **No** | **No** | **FRONTEND ONLY** |

---

## 2. ARCHITECTURE CONFIRMATION

### Existing foundation (do not change)
- `lib/main.dart` — minimal entry point, `ProviderScope` + `VyparaAIApp`
- `lib/app/app.dart` — `MaterialApp.router` with theme and `GoRouter`
- `lib/app/router.dart` — empty `GoRouter`, ready for routes
- `lib/app/theme/` — `app_theme.dart`, `app_colors.dart`, `app_text_styles.dart`, `app_spacing.dart`
- `lib/app/config/app_config.dart` — application config placeholder
- `lib/core/network/` — `api_client.dart`, `api_endpoints.dart`, `auth_interceptor.dart`, `network_exception.dart`
- `lib/core/storage/secure_storage.dart` — secure token storage abstraction
- `lib/core/errors/app_exception.dart` — application error base
- `lib/core/utils/` — `validators.dart`, `formatters.dart`
- `lib/core/widgets/` — `app_button.dart`, `app_text_field.dart`, `app_loader.dart`, `app_error.dart`, `app_empty_state.dart`
- `lib/features/` — empty, reserved for feature modules
- `lib/shared/` — empty, reserved for shared components

### Feature structure rule (mandatory for every feature)

```
features/<feature_name>/
├── data/
│   ├── datasources/
│   │   └── <feature>_remote_datasource.dart
│   ├── models/
│   │   ├── <feature>_request_model.dart
│   │   ├── <feature>_response_model.dart
│   │   └── <feature>_entity_model.dart
│   └── repositories/
│       └── <feature>_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── <feature>_entity.dart
│   └── repositories/
│       └── <feature>_repository.dart
└── presentation/
    ├── providers/
    │   └── <feature>_provider.dart
    ├── screens/
    │   ├── <feature>_screen.dart
    │   └── <feature>_details_screen.dart
    └── widgets/
        ├── <feature>_card.dart
        ├── <feature>_item.dart
        └── <feature>_filters.dart
```

### Data flow rule (mandatory)

```
Screen
  ↓
Provider
  ↓
Repository (domain contract)
  ↓
RepositoryImpl
  ↓
RemoteDataSource
  ↓
ApiClient
  ↓
FastAPI
```

**Never:**
- Screen → Dio/HTTP → FastAPI
- Provider → Dio/HTTP → FastAPI
- Feature-specific methods inside `core/network/api_client.dart`

---

## 3. DESIGN SYSTEM PLAN

### Tokens to establish in Phase 2

**`app_colors.dart`**
- Primary brand color: blue/purple gradient anchor
- Background: light
- Surface: white
- Error, success, warning, info
- Text primary / secondary / tertiary

**`app_text_styles.dart`**
- Display / headline for large financial numbers
- Title for section headers
- Body for content
- Caption / label for metadata
- Button text styles

**`app_spacing.dart`**
- xs, sm, md, lg, xl, xxl
- Screen padding constants
- Card spacing constants

**`app_radius.dart`** (new)
- sm, md, lg for card/border radius

**`app_shadows.dart`** (new)
- card shadow
- elevated shadow
- subtle shadow

**`app_theme.dart`**
- `ThemeData` assembly from tokens
- `ColorScheme.fromSeed`
- Consistent input decoration theme
- Consistent card theme

### Reference visual language (from plan)
- Light background
- Blue/purple branding
- Soft gradients
- Rounded cards
- Subtle shadows
- Strong but clean typography
- Large financial numbers
- Compact icons
- Generous spacing
- Rounded controls
- Prominent microphone
- Minimal clutter
- Card-based information architecture

---

## 4. PHASE-WISE IMPLEMENTATION PLAN

### PHASE 0 — Foundation (COMPLETE)
- Project structure created
- Architecture placeholders in place
- Dependencies added: dio, flutter_riverpod, go_router, flutter_secure_storage
- `flutter analyze` clean

### PHASE 1 — Backend Capability Audit (THIS DOCUMENT)
- [x] Read backend architecture docs
- [x] Inspect FastAPI routers, schemas, services, models
- [x] Map every existing endpoint
- [x] Identify backend gaps
- [x] Create capability matrix
- [x] Create this implementation plan

### PHASE 2 — Design System (COMPLETE)
**Goal:** Centralized theme tokens so every future screen looks consistent.

**Files to create/modify:**
- `lib/app/theme/app_colors.dart`
- `lib/app/theme/app_text_styles.dart`
- `lib/app/theme/app_spacing.dart`
- `lib/app/theme/app_radius.dart` (new)
- `lib/app/theme/app_shadows.dart` (new)
- `lib/app/theme/app_theme.dart`

**Files to create:**
- `lib/core/widgets/app_card.dart` — generic card wrapper
- `lib/core/widgets/app_section_header.dart` — section title + optional action

**Verification:**
- `flutter analyze`
- Visual check in Chrome: sample screen showing colors, typography, cards, shadows

**No product screens yet.**

---

### PHASE 3 — App Shell
**Goal:** Navigation, splash, authenticated shell, bottom nav, global header.

**Features to create:** none yet — only shell infrastructure.

**Files to create:**
- `lib/app/router.dart` — GoRouter with route structure:
  - `/` → splash redirect
  - `/splash` → SplashScreen
  - `/login` → LoginScreen
  - `/register` → RegisterScreen
  - `/app/home` → HomeScreen
  - `/app/reports` → ReportsScreen
  - `/app/ai` → AIScreen
  - `/app/records` → RecordsScreen
  - `/app/settings` → SettingsScreen
  - `/app/transactions` → TransactionsScreen
  - `/app/invoices` → InvoicesScreen
  - `/app/customers` → CustomersScreen
  - `/app/suppliers` → SuppliersScreen
  - `/app/cash-flow` → CashFlowScreen
  - `/app/reminders` → RemindersScreen
  - `/app/notifications` → NotificationsScreen
  - `/app/upload` → UploadScreen
  - `/app/voice` → VoiceScreen
  - detail routes: `/app/transactions/:id`, `/app/invoices/:id`, etc.

- `lib/features/auth/presentation/screens/splash_screen.dart`
  - Logo, app name, tagline
  - Short animation/transition
  - Session check → route to home or login

**Files to create (shell widgets):**
- `lib/core/widgets/app_bottom_nav.dart` — 5-tab bottom nav
- `lib/core/widgets/app_header.dart` — top bar with language + notification
- `lib/core/widgets/language_selector.dart`
- `lib/core/widgets/notification_button.dart`

**Providers to create:**
- `lib/features/auth/presentation/providers/auth_provider.dart`
  - State: `initial`, `loading`, `authenticated`, `unauthenticated`, `error`
  - Methods: `checkSession()`, `login()`, `logout()`, `register()`

**Data layer for auth:**
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`
  - `login(email, password)` → `POST /auth/login`
  - `register(name, email, password)` → `POST /users/`
- `lib/features/auth/data/models/login_request.dart`
- `lib/features/auth/data/models/login_response.dart`
- `lib/features/auth/data/models/user_model.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/features/auth/domain/entities/user.dart`
- `lib/features/auth/domain/repositories/auth_repository.dart`

**State handling:**
- Loading → splash animation
- Authenticated → `/app/home`
- Unauthenticated → `/login`
- Error → show error, allow retry

**Verification:**
- Chrome: splash → login → register → home shell
- Bottom nav renders 5 tabs
- Logout returns to login

---

### PHASE 4 — Authentication UI
**Goal:** Login, register, forgot-password placeholder, session management.

**Screens:**
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/register_screen.dart`
- `lib/features/auth/presentation/screens/forgot_password_screen.dart` (placeholder — no backend endpoint)

**Widgets:**
- `lib/features/auth/presentation/widgets/login_form.dart`
- `lib/features/auth/presentation/widgets/register_form.dart`
- `lib/features/auth/presentation/widgets/auth_header.dart`

**API integration:**
- Wire auth provider to real backend endpoints
- Store JWT in `SecureStorage`
- Attach JWT via `AuthInterceptor`

**Error states:**
- Invalid credentials
- Network failure
- Validation errors

**Verification:**
- Real login against backend
- Token persisted
- Protected routes redirect to login on expired token

---

### PHASE 5 — Home Dashboard
**Goal:** Central business overview screen.

**API dependencies:**
- `GET /financials/income/today`
- `GET /financials/expenses/today`
- `GET /financials/profit/today`
- `GET /financials/cash-position`
- `GET /financials/receivables`
- `GET /financials/receivables/overdue`
- `GET /financials/liabilities`
- `GET /financials/liabilities/upcoming`
- `GET /financials/insights`
- `GET /financials/anomalies`
- `GET /reminders/morning-briefing` (optional)

**Feature structure:**
```
features/home/
├── data/
│   ├── datasources/
│   │   └── home_remote_datasource.dart
│   ├── models/
│   │   ├── dashboard_summary_model.dart
│   │   ├── metric_card_model.dart
│   │   └── attention_item_model.dart
│   └── repositories/
│       └── home_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── dashboard_summary.dart
│   │   ├── metric_card.dart
│   │   └── attention_item.dart
│   └── repositories/
│       └── home_repository.dart
└── presentation/
    ├── providers/
    │   └── home_provider.dart
    ├── screens/
    │   └── home_screen.dart
    └── widgets/
        ├── greeting_header.dart
        ├── metric_card.dart
        ├── profit_chart_placeholder.dart
        ├── needs_attention_section.dart
        ├── attention_card.dart
        ├── quick_actions.dart
        ├── ask_ai_section.dart
        └── voice_microphone_button.dart
```

**Screen layout:**
- Greeting header: “Good Morning, Ramesh 👋”
- Language selector + notification button
- 2x2 or stacked metric cards: Today’s Income, Today’s Expenses, Today’s Profit, Cash/Receivables
- Needs Attention section: actionable cards with View/Remind actions
- Quick Actions: Upload, Camera, Record, Add Transaction
- Large AI microphone button

**State handling:**
- Loading: skeleton cards
- Success: render real data
- Empty: “No data available yet”
- Error: error state with retry
- Partial: show available metrics, mark missing as unavailable

**No hardcoded financial values.**

**Verification:**
- Real API data displayed
- Compare layout against reference image
- Chrome + mobile size testing

---

### PHASE 6 — Records (Transactions + Invoices)
**Goal:** List, filter, create, view transactions and invoices.

**Feature structure:**
```
features/transactions/
├── data/
│   ├── datasources/
│   │   └── transactions_remote_datasource.dart
│   ├── models/
│   │   ├── transaction_model.dart
│   │   └── transaction_create_model.dart
│   └── repositories/
│       └── transactions_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── transaction.dart
│   └── repositories/
│   └── transactions_repository.dart
└── presentation/
    ├── providers/
    │   └── transactions_provider.dart
    ├── screens/
    │   ├── transactions_screen.dart
    │   └── transaction_details_screen.dart
    └── widgets/
        ├── transaction_card.dart
        ├── transaction_search.dart
        ├── transaction_filters.dart
        └── add_transaction_fab.dart

features/invoices/
├── data/
│   ├── datasources/
│   │   └── invoices_remote_datasource.dart
│   ├── models/
│   │   ├── invoice_model.dart
│   │   ├── invoice_create_model.dart
│   │   └── payment_apply_model.dart
│   └── repositories/
│       └── invoices_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── invoice.dart
│   │   └── payment.dart
│   └── repositories/
│   └── invoices_repository.dart
└── presentation/
    ├── providers/
    │   └── invoices_provider.dart
    ├── screens/
    │   ├── invoices_screen.dart
    │   └── invoice_details_screen.dart
    └── widgets/
        ├── invoice_card.dart
        ├── invoice_status_badge.dart
        └── apply_payment_bottom_sheet.dart
```

**Backend endpoints used:**
- `GET /transactions/`
- `GET /transactions/{id}`
- `POST /transactions/`
- `PUT /transactions/{id}`
- `DELETE /transactions/{id}`
- `GET /transactions/summary`
- `GET /invoices/`
- `GET /invoices/{id}`
- `POST /invoices/`
- `PUT /invoices/{id}`
- `DELETE /invoices/{id}`
- `PATCH /invoices/{id}/status`
- `POST /invoices/{id}/payments`

**Transaction filters:**
- Type: All / Income / Expense
- Date range
- Category
- Source
- Business

**Invoice features:**
- Status badges: unpaid, partially_paid, paid, overdue
- Apply payment flow
- Payment confirmation

**Verification:**
- Real CRUD operations
- Filters reflect backend query params
- Chrome + mobile testing

---

### PHASE 7 — Upload / OCR
**Goal:** Upload invoices and payment screenshots, review extracted data, confirm.

**Feature structure:**
```
features/uploads/
├── data/
│   ├── datasources/
│   │   ├── ocr_remote_datasource.dart
│   │   └── upload_remote_datasource.dart
│   ├── models/
│   │   ├── ocr_extraction_model.dart
│   │   ├── payment_extraction_model.dart
│   │   └── ocr_confirm_request_model.dart
│   └── repositories/
│       └── uploads_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── ocr_extraction.dart
│   │   └── payment_extraction.dart
│   └── repositories/
│   └── uploads_repository.dart
└── presentation/
    ├── providers/
    │   ├── upload_provider.dart
    │   └── ocr_review_provider.dart
    ├── screens/
    │   ├── upload_screen.dart
    │   ├── camera_screen.dart
    │   ├── ocr_review_screen.dart
    │   └── payment_review_screen.dart
    └── widgets/
        ├── upload_option_grid.dart
        ├── upload_preview.dart
        ├── ocr_invoice_form.dart
        ├── payment_match_card.dart
        └── confidence_indicator.dart
```

**Backend endpoints used:**
- `POST /ocr/invoice`
- `POST /ocr/invoice/confirm`
- `POST /ocr/payment`
- `POST /ocr/payment/confirm`

**States:**
- SELECT → VALIDATE → UPLOAD → PROCESS → EXTRACT → REVIEW → CONFIRM → SAVE

**File handling:**
- Support image types only (backend requirement)
- Validate file size before upload
- Show preview
- Display extracted fields
- Allow edit before confirm
- Never auto-save uncertain data

**Backend gap handling:**
- Video: unsupported → show clear message
- Audio: unsupported → show clear message
- PDF: verify backend support before adding

**Verification:**
- Real OCR extraction
- Real confirm/save
- Chrome + mobile testing

---

### PHASE 8 — Customers / Suppliers
**Goal:** List customers/suppliers, view balances, payment history.

**Note:** Backend has no dedicated `/customers` or `/suppliers` endpoints. This feature must derive data from transactions and invoices.

**Feature structure:**
```
features/customers/
├── data/
│   ├── datasources/
│   │   ├── customers_remote_datasource.dart
│   │   └── transactions_remote_datasource.dart
│   ├── models/
│   │   └── customer_summary_model.dart
│   └── repositories/
│       └── customers_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── customer.dart
│   └── repositories/
│   └── customers_repository.dart
└── presentation/
    ├── providers/
    │   └── customers_provider.dart
    ├── screens/
    │   ├── customers_screen.dart
    │   └── customer_details_screen.dart
    └── widgets/
        ├── customer_card.dart
        ├── customer_balance.dart
        └── payment_history_list.dart
```

**Backend endpoints used:**
- `GET /transactions/` — derive customer names from transactions
- `GET /invoices/` — derive outstanding from invoices
- `GET /financials/receivables/customer-summary`
- `GET /financials/receivables/customer/{customer_id}`

**Backend gap:** No customer creation/update/delete API. UI must show read-only with “backend gap” note if user attempts unsupported action.

**Verification:**
- Real data from invoices/transactions
- Chrome + mobile testing

---

### PHASE 9 — Reports
**Goal:** Financial reports with date ranges, type filters, summary cards.

**Note:** Backend has no `/reports/daily`, `/weekly`, `/monthly` endpoints. Use existing financials endpoints.

**Feature structure:**
```
features/reports/
├── data/
│   ├── datasources/
│   │   └── reports_remote_datasource.dart
│   ├── models/
│   │   └── report_summary_model.dart
│   └── repositories/
│       └── reports_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── report_summary.dart
│   └── repositories/
│   └── reports_repository.dart
└── presentation/
    ├── providers/
    │   └── reports_provider.dart
    ├── screens/
    │   └── reports_screen.dart
    └── widgets/
        ├── report_summary_card.dart
        ├── date_range_selector.dart
        ├── report_type_selector.dart
        └── report_chart_placeholder.dart
```

**Backend endpoints used:**
- `GET /financials/income/today|week|month`
- `GET /financials/expenses/today|week|month`
- `GET /financials/profit/today|week|month`
- `GET /financials/receivables`
- `GET /financials/liabilities`
- `GET /financials/cash-position`
- `GET /financials/cash-flow`
- `GET /financials/insights`
- `GET /financials/anomalies`

**Backend gap:** No report download PDF/Excel. “Download” button must show “backend gap” state.

**Verification:**
- Real financial data
- Date range applied client-side from backend period data
- Chrome + mobile testing

---

### PHASE 10 — Cash Flow
**Goal:** Cash flow forecast screen with period selector.

**Feature structure:**
```
features/cash_flow/
├── data/
│   ├── datasources/
│   │   └── cash_flow_remote_datasource.dart
│   ├── models/
│   │   └── cash_flow_model.dart
│   └── repositories/
│       └── cash_flow_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── cash_flow.dart
│   └── repositories/
│   └── cash_flow_repository.dart
└── presentation/
    ├── providers/
    │   └── cash_flow_provider.dart
    ├── screens/
    │   └── cash_flow_screen.dart
    └── widgets/
        ├── cash_flow_metric_card.dart
        ├── period_selector.dart
        └── cash_flow_chart.dart
```

**Backend endpoints used:**
- `GET /financials/cash-flow?days=7|30|90`
- `GET /financials/cash-position`

**Verification:**
- Real backend cash flow data
- Period selector works
- Chrome + mobile testing

---

### PHASE 11 — Reminders / Notifications
**Goal:** Reminders list, create, update, delete. Notifications list, mark as read.

**Feature structure:**
```
features/reminders/
├── data/
│   ├── datasources/
│   │   └── reminders_remote_datasource.dart
│   ├── models/
│   │   ├── reminder_model.dart
│   │   ├── reminder_create_model.dart
│   │   └── morning_briefing_model.dart
│   └── repositories/
│       └── reminders_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── reminder.dart
│   │   └── morning_briefing.dart
│   └── repositories/
│   └── reminders_repository.dart
└── presentation/
    ├── providers/
    │   └── reminders_provider.dart
    ├── screens/
    │   ├── reminders_screen.dart
    │   └── morning_briefing_screen.dart
    └── widgets/
        ├── reminder_card.dart
        ├── reminder_form.dart
        └── briefing_summary_card.dart

features/notifications/
├── data/
│   ├── datasources/
│   │   └── notifications_remote_datasource.dart
│   ├── models/
│   │   └── notification_model.dart
│   └── repositories/
│       └── notifications_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── notification.dart
│   └── repositories/
│   └── notifications_repository.dart
└── presentation/
    ├── providers/
    │   └── notifications_provider.dart
    ├── screens/
    │   └── notifications_screen.dart
    └── widgets/
        └── notification_card.dart
```

**Backend endpoints used:**
- `GET /reminders/morning-briefing`
- `POST /reminders/`
- `GET /reminders/`
- `GET /reminders/{id}`
- `PATCH /reminders/{id}`
- `DELETE /reminders/{id}`
- `GET /notifications/`
- `PATCH /notifications/{id}/read`

**Backend gap:** No push notification registration (FCM/APNs). In-app notifications only.

**Verification:**
- Real CRUD operations
- Morning briefing displays real data
- Chrome + mobile testing

---

### PHASE 12 — AI Chat
**Goal:** Text-based AI assistant using `/copilot/chat`.

**Feature structure:**
```
features/ai_assistant/
├── data/
│   ├── datasources/
│   │   └── ai_remote_datasource.dart
│   ├── models/
│   │   ├── ai_message_model.dart
│   │   └── ai_response_model.dart
│   └── repositories/
│       └── ai_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── ai_message.dart
│   │   └── ai_response.dart
│   └── repositories/
│   └── ai_repository.dart
└── presentation/
    ├── providers/
    │   └── ai_chat_provider.dart
    ├── screens/
    │   ├── ai_chat_screen.dart
    │   └── ai_action_screen.dart
    └── widgets/
        ├── ai_message_bubble.dart
        ├── user_message_bubble.dart
        ├── ai_action_card.dart
        ├── chat_input.dart
        └── suggested_actions.dart
```

**Backend endpoints used:**
- `POST /copilot/chat`

**Backend behavior:**
- Rule-based intent classification
- Tool execution via financial/analytics tools
- Natural language explanation returned
- LLM never calculates financial values

**States:**
- Loading: typing indicator
- Success: render AI response + optional action cards
- Error: show error, allow retry
- Empty: initial state with suggested questions

**Never hardcode AI responses.**

**Verification:**
- Real backend response displayed
- Action cards trigger follow-up API calls where applicable
- Chrome + mobile testing

---

### PHASE 13 — Voice Assistant
**Goal:** Voice interaction via `POST /voice/query`.

**Feature structure:**
```
features/ai_assistant/
└── presentation/
    ├── screens/
    │   └── voice_assistant_screen.dart
    └── widgets/
        ├── voice_waveform.dart
        ├── microphone_button.dart
        └── voice_transcript.dart
```

**Backend endpoints used:**
- `POST /voice/query`

**Voice state machine:**
- IDLE
- REQUESTING_PERMISSION
- LISTENING
- PROCESSING
- TRANSCRIBING
- AI_PROCESSING
- SPEAKING
- COMPLETED

**Error states:**
- MICROPHONE_PERMISSION_DENIED
- RECORDING_FAILED
- UPLOAD_FAILED
- STT_FAILED
- AI_FAILED
- NETWORK_ERROR

**Backend reality:**
- Backend uses simulation mode for STT by default (`VOICE_SIMULATION_MODE=true`)
- Backend returns structured response: transcription, answer, intent, language
- No actual TTS in backend yet — UI shows text response

**Verification:**
- Real backend response displayed
- State machine transitions correct
- Chrome + mobile testing with microphone permissions

---

### PHASE 14 — Language / Localization
**Goal:** Multi-language support.

**Architecture:**
- `lib/l10n/` or `lib/core/localization/`
- `AppLocalizations` via `flutter_localizations`
- `intl` package for ARB files
- Language selector in header and settings

**Supported languages (from plan):**
- English (default)
- Hindi
- Tamil
- Telugu
- Kannada
- Malayalam
- Bengali

**Implementation:**
- Do not hardcode strings in widgets
- Use `AppLocalizations.of(context).stringKey`
- Language preference stored in `SecureStorage`

**Backend gap:**
- No backend localization API
- Frontend-only localization

**Verification:**
- Language switcher updates all screens
- Persistent across app restarts

---

### PHASE 15 — Settings
**Goal:** Settings screen with profile, business, preferences.

**Feature structure:**
```
features/settings/
├── data/
│   ├── datasources/
│   │   ├── settings_remote_datasource.dart
│   │   └── auth_remote_datasource.dart
│   ├── models/
│   │   └── business_model.dart
│   └── repositories/
│       └── settings_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── business.dart
│   └── repositories/
│   └── settings_repository.dart
└── presentation/
    ├── providers/
    │   └── settings_provider.dart
    ├── screens/
    │   ├── settings_screen.dart
    │   ├── profile_screen.dart
    │   ├── business_profile_screen.dart
    │   ├── notifications_settings_screen.dart
    │   └── privacy_screen.dart
    └── widgets/
        ├── settings_tile.dart
        ├── settings_section.dart
        └── logout_button.dart
```

**Backend endpoints used:**
- `GET /users/` (implicit via current_user)
- `GET /businesses/`
- `PUT /businesses/{id}` (if implemented)

**Backend gap:**
- No profile update endpoint
- No privacy/export/delete endpoints
- No subscription endpoint

**Verification:**
- Logout clears session and routes to login
- Profile data displayed from backend user object

---

### PHASE 16 — Global UX Polish
**Goal:** Consistent behavior across all screens.

**Items:**
- Loading skeletons everywhere
- Empty states everywhere
- Error states with retry everywhere
- Unauthorized redirect to login
- Network failure handling
- Keyboard safe areas
- Scroll behavior
- Touch target sizing (48x48 min)
- Bottom nav active state
- Pull-to-refresh where applicable
- Haptic feedback on actions (optional)
- Accessibility labels

---

### PHASE 17 — Real-Device Testing
**Goal:** Verify on actual Android/iOS hardware.

**Checklist:**
- Small phone layout
- Normal phone layout
- Large phone / small tablet
- Portrait orientation
- Keyboard open behavior
- Slow network simulation
- Network failure simulation
- Permission denied states
- Camera denied states
- Microphone denied states
- Large upload handling
- Battery usage
- Scroll performance

---

## 5. FEATURE-TO-BACKEND MAPPING SUMMARY

### Features implementable now (backend ready)
1. Authentication (login, register, session)
2. Home Dashboard (financials endpoints)
3. Transactions (CRUD + summary)
4. Invoices (CRUD + payment)
5. OCR Invoice extraction + confirm
6. OCR Payment extraction + confirm + reconcile
7. Cash Flow
8. Reminders + Morning Briefing
9. Notifications (list + mark read)
10. AI Chat (Copilot)
11. Voice Assistant (with simulation mode caveat)
12. Settings (read-only profile/business)

### Features requiring backend first (backend gaps)
1. **Dashboard API** — no `GET /dashboard`
2. **Reports API** — no `/reports/daily|weekly|monthly`
3. **Customers API** — no `/customers/` endpoints
4. **Suppliers API** — no `/suppliers/` endpoints
5. **Push Notifications** — no FCM/APNs integration
6. **Profile Update** — no `PUT /users/{id}`
7. **Business Update** — incomplete
8. **PDF/Excel Export** — not in backend

### Frontend-only features
1. Language/Localization (no backend API needed)

---

## 6. IMPLEMENTATION ORDER (MANDATORY)

```
PHASE 0  Foundation                    ✅ COMPLETE
PHASE 1  Backend Audit                 ✅ THIS DOCUMENT
PHASE 2  Design System                 ← START HERE FIRST
PHASE 3  App Shell                     (Splash, Router, Nav, Theme)
PHASE 4  Authentication                (Login, Register, Session)
PHASE 5  Home Dashboard                (Financial metrics, Attention, Quick Actions)
PHASE 6  Records                       (Transactions + Invoices)
PHASE 7  Upload / OCR                  (Invoice + Payment extraction)
PHASE 8  Customers / Suppliers         (Read-only from invoices/transactions)
PHASE 9  Reports                       (Financial summaries from existing endpoints)
PHASE 10 Cash Flow                     (Cash flow forecast)
PHASE 11 Reminders / Notifications     (CRUD + morning briefing)
PHASE 12 AI Chat                       (Copilot chat)
PHASE 13 Voice Assistant               (Voice query)
PHASE 14 Language / Localization       (Frontend-only)
PHASE 15 Settings                      (Profile, Business, Preferences)
PHASE 16 Global UX Polish              (Loading, Empty, Error states everywhere)
PHASE 17 Real-Device Testing
```

**Do not skip phases.**
**Do not build UI before verifying backend.**
**Do not fake backend integrations.**

---

## 7. BACKEND GAP DOCUMENTATION FORMAT

When a feature cannot be fully implemented because the backend does not support it, document it exactly as:

```
BACKEND GAP: <feature name>
Missing: <specific endpoint or capability>
Impact: <what the user sees instead>
Workaround: <if any>
Backend ticket: <if known>
Example:
BACKEND GAP: Dashboard API
Missing: GET /dashboard
Impact: Home screen shows partial data from multiple endpoints instead of single aggregated call
Workaround: None — use parallel calls to financials endpoints
Backend ticket: Phase 17 in implementation_plan.md
```

---

## 8. DEFINITION OF DONE (PER FEATURE)

A feature is complete only when ALL of these are true:
- [ ] UI matches reference design
- [ ] Navigation works
- [ ] Backend endpoint verified and documented
- [ ] Request schema matches backend
- [ ] Response schema parsed correctly
- [ ] Authentication works
- [ ] Loading state implemented
- [ ] Empty state implemented
- [ ] Error state implemented with retry
- [ ] Real backend data displayed
- [ ] User actions work end-to-end
- [ ] No fake data
- [ ] No duplicated business logic
- [ ] Mobile layout verified
- [ ] Chrome verification passed
- [ ] No analyzer warnings introduced
- [ ] Architecture rules followed
- [ ] Backend gaps documented (if any)

---

## 9. CODE QUALITY RULES

1. Run `flutter analyze` after every meaningful change
2. Fix all analyzer issues before proceeding
3. Never suppress warnings to make analyzer pass
4. No dynamic types unless absolutely necessary
5. Strong typing everywhere
6. Each file has one clear responsibility
7. No giant files (>300 lines triggers review)
8. No duplicate components
9. No feature-specific code in `core/`
10. No HTTP calls in screens or providers

---

## 10. TESTING CHECKLIST (PER FEATURE)

- [ ] Widget test for screen structure
- [ ] Provider test for state transitions
- [ ] Repository test with mock datasource
- [ ] Datasource test with mock API client
- [ ] Error state test
- [ ] Empty state test
- [ ] Loading state test
- [ ] Real API integration test (when backend available)

---

## 11. REMAINING BACKEND WORK (FOR REFERENCE)

From `docs/implementation_plan.md`, the backend still needs:

| Phase | Feature | Status |
|---|---|---|
| 17 | Dashboard + Reports API | Pending |
| 18 | Mobile Application | Pending |

Until Phase 17 is complete, the Flutter app must:
- Use existing financials endpoints as data sources
- Document missing endpoints as backend gaps
- Never invent dashboard/report API contracts

---

## 12. ARCHITECTURE DECISIONS

| Decision | Choice | Reason |
|---|---|---|
| State management | Riverpod | Established in existing foundation |
| Routing | GoRouter | Established in existing foundation |
| HTTP client | Dio via ApiClient | Established in existing foundation |
| Secure storage | flutter_secure_storage | Established in existing foundation |
| Feature structure | data/domain/presentation per feature | Mandatory per architecture rules |
| Financial calculations | Backend only | Backend is source of truth |
| AI responses | Backend only | Never fake or hardcode |
| Localization | Frontend intl only | No backend localization API |
| Voice | Backend-dependent | Simulation mode available, TTS pending |

---

## 13. WHAT THIS PLAN DOES NOT COVER

- React Native / Expo (reference mentioned Expo, but project is Flutter)
- Backend implementation (separate task)
- Push notification infrastructure (FCM/APNs)
- PDF/Excel export
- Subscription/billing system
- Advanced ML-based anomaly detection
- Business memory / personalization layer
- Multi-business switching UI (backend may not support)

---

## 14. NEXT IMMEDIATE ACTION

**PHASE 2 — Design System**

Create/update:
1. `lib/app/theme/app_colors.dart`
2. `lib/app/theme/app_text_styles.dart`
3. `lib/app/theme/app_spacing.dart`
4. `lib/app/theme/app_radius.dart`
5. `lib/app/theme/app_shadows.dart`
6. `lib/app/theme/app_theme.dart`
7. `lib/core/widgets/app_card.dart`
8. `lib/core/widgets/app_section_header.dart`

Then proceed to PHASE 3.

---

*This document is the single source of truth for Flutter frontend implementation. Every feature must follow the phases, architecture rules, and backend capability matrix defined here.*
