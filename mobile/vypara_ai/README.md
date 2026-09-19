# VyparaAI Flutter

Flutter mobile client for VyparaAI.

## Final Architecture

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_text_styles.dart
├── core/
│   ├── constants/
│   │   ├── api_endpoints.dart
│   │   └── app_constants.dart
│   ├── errors/
│   │   └── app_exception.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   └── helpers.dart
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       └── app_loader.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── widgets/
│   │   │   ├── login_form.dart
│   │   │   └── auth_header.dart
│   │   ├── models/
│   │   │   └── user_model.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   ├── repositories/
│   │   │   └── auth_repository.dart
│   │   └── services/
│   │       └── auth_service.dart
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   ├── widgets/
│   │   │   └── home_header.dart
│   │   ├── models/
│   │   ├── providers/
│   │   │   └── home_provider.dart
│   │   └── repositories/
│   │       └── home_repository.dart
│   ├── profile/
│   │   ├── screens/
│   │   │   └── profile_screen.dart
│   │   ├── widgets/
│   │   ├── models/
│   │   ├── providers/
│   │   │   └── profile_provider.dart
│   │   └── repositories/
│   │       └── profile_repository.dart
│   └── [other_features]/
└── shared/
    ├── models/
    └── widgets/
```

## Where Things Live

| What | Where | Why |
|------|-------|-----|
| Root app widget | `lib/app/app.dart` | Single entry point for MaterialApp |
| Routes | `lib/app/router.dart` | Central navigation configuration |
| Theme | `lib/app/theme/` | Global design system |
| API endpoints | `lib/core/constants/api_endpoints.dart` | Centralized backend paths |
| App constants | `lib/core/constants/app_constants.dart` | App-wide config values |
| API client | `lib/core/network/api_client.dart` | Single Dio instance |
| Secure storage | `lib/core/storage/storage_service.dart` | Token/session storage |
| Errors | `lib/core/errors/` | App and network exceptions |
| Utils | `lib/core/utils/` | Validators, formatters, helpers |
| Reusable widgets | `lib/core/widgets/` | App-wide generic UI components |
| Feature screens | `lib/features/<feature>/screens/` | Full pages |
| Feature widgets | `lib/features/<feature>/widgets/` | Feature-specific UI |
| Feature providers | `lib/features/<feature>/providers/` | Riverpod state |
| Feature models | `lib/features/<feature>/models/` | API DTOs |
| Feature repositories | `lib/features/<feature>/repositories/` | Data contracts |
| Feature services | `lib/features/<feature>/services/` | API calls |
| Shared models | `lib/shared/models/` | Cross-feature models |
| Shared widgets | `lib/shared/widgets/` | Cross-feature widgets |

## Deep Dive: Each File and Folder

### `lib/main.dart`
**Purpose:** Minimal entry point.
**What it does:** Initializes Flutter bindings and launches `App`.
**Rule:** Never put feature logic, API calls, or navigation here.

### `lib/app/app.dart`
**Purpose:** Root Flutter application configuration.
**What it does:** Wraps the app in `MaterialApp.router`, sets theme and router.
**Rule:** Keep it minimal. Only app-wide configuration belongs here.

### `lib/app/router.dart`
**Purpose:** Central navigation configuration.
**What it does:** Defines all app routes using `GoRouter`.
**Rule:** Add routes here when screens are implemented. Example:
```dart
GoRoute(path: '/login', builder: (context, state) => const LoginScreen())
```

### `lib/app/theme/app_theme.dart`
**Purpose:** Theme assembly.
**What it does:** Builds `ThemeData` from colors, text styles, and spacing.
**Rule:** All screens must use this theme. Never hardcode theme values in screens.

### `lib/app/theme/app_colors.dart`
**Purpose:** Color palette.
**What it does:** Defines all app colors and `ColorScheme` for light/dark modes.
**Rule:** Add new colors here. Never use hardcoded `Color(0xFF...)` in screens.

### `lib/app/theme/app_text_styles.dart`
**Purpose:** Typography system.
**What it does:** Defines `TextTheme` with consistent font sizes, weights, and spacing.
**Rule:** Use these styles everywhere. Never hardcode `fontSize` or `fontWeight` in screens.

### `lib/core/constants/api_endpoints.dart`
**Purpose:** Centralized API endpoint paths.
**What it does:** Stores all FastAPI endpoint strings as constants.
**Rule:** Only add endpoints confirmed by the backend. Never invent endpoints.

### `lib/core/constants/app_constants.dart`
**Purpose:** App-wide configuration constants.
**What it does:** Stores base URL, app name, feature flags.
**Rule:** Use environment variables for values that change per build.

### `lib/core/errors/app_exception.dart`
**Purpose:** Application error hierarchy.
**What it does:** Defines `AppException` and subtypes like `ValidationException`, `StorageException`.
**Rule:** Throw these from repositories and services. Catch in providers.

### `lib/core/errors/network_exception.dart`
**Purpose:** Network error representation.
**What it does:** Wraps `DioException` into a readable `NetworkException` with message, status code, and data.
**Rule:** Convert Dio errors to this in the API client or interceptor.

### `lib/core/utils/validators.dart`
**Purpose:** Input validation logic.
**What it does:** Provides reusable validators for email, password, required fields.
**Rule:** Use in `TextFormField.validator`. Never put validation logic in screens.

### `lib/core/utils/formatters.dart`
**Purpose:** Value formatting logic.
**What it does:** Provides formatters for phone numbers, capitalization, etc.
**Rule:** Use when displaying formatted values. Never inline formatting in screens.

### `lib/core/utils/helpers.dart`
**Purpose:** Generic helper methods.
**What it does:** Small reusable utilities that don't fit elsewhere.
**Rule:** Keep generic. No feature-specific logic.

### `lib/core/widgets/app_button.dart`
**Purpose:** Reusable button component.
**What it does:** Styled `ElevatedButton` with loading state and full-width option.
**Rule:** Use this instead of raw `ElevatedButton` everywhere.

### `lib/core/widgets/app_text_field.dart`
**Purpose:** Reusable text field component.
**What it does:** Styled `TextFormField` with label, hint, validator, and keyboard type.
**Rule:** Use this instead of raw `TextFormField` everywhere.

### `lib/core/widgets/app_loader.dart`
**Purpose:** Loading indicator component.
**What it does:** Centered `CircularProgressIndicator` with optional message.
**Rule:** Show when providers are in loading state.

### `lib/core/network/api_client.dart`
**Purpose:** Central HTTP client.
**What it does:** Configures Dio with base URL, timeouts, headers, logging, and auth interceptor.
**Rule:** All HTTP must go through this. Never instantiate Dio elsewhere.

### `lib/core/storage/storage_service.dart`
**Purpose:** Secure local storage abstraction.
**What it does:** Wraps `FlutterSecureStorage` for token storage with encrypted shared preferences on Android.
**Rule:** Use for access tokens, refresh tokens, and sensitive data. Never store tokens in plain text.

### `lib/features/auth/`
**Purpose:** Authentication feature isolation.
**What it contains:** Login, register, forgot password screens, auth widgets, user model, auth provider, auth repository, auth service.

### `lib/features/auth/screens/login_screen.dart`
**Purpose:** Login page.
**What it does:** Full page UI for user login.
**Rule:** Must consume `AuthProvider`. Must not call API directly.

### `lib/features/auth/screens/register_screen.dart`
**Purpose:** Registration page.
**What it does:** Full page UI for new user sign-up.
**Rule:** Must consume `AuthProvider`.

### `lib/features/auth/screens/forgot_password_screen.dart`
**Purpose:** Password recovery page.
**What it does:** Full page UI for password reset flow.
**Rule:** Must consume `AuthProvider`.

### `lib/features/auth/widgets/login_form.dart`
**Purpose:** Reusable login form UI.
**What it does:** Combines email/password fields with submit button.
**Rule:** Feature-specific widget. Used only within auth feature.

### `lib/features/auth/widgets/auth_header.dart`
**Purpose:** Reusable auth header UI.
**What it does:** Logo/title shown on auth screens.
**Rule:** Feature-specific widget. Used only within auth feature.

### `lib/features/auth/models/user_model.dart`
**Purpose:** User API model.
**What it does:** Maps FastAPI JSON response to Dart object.
**Rule:** Add `fromJson`/`toJson`/`toEntity` methods.

### `lib/features/auth/providers/auth_provider.dart`
**Purpose:** Authentication state management.
**What it does:** Manages login/logout/register state using Riverpod.
**Rule:** Must call repository, never datasource directly.

### `lib/features/auth/repositories/auth_repository.dart`
**Purpose:** Authentication data contract.
**What it does:** Abstract class defining auth data operations.
**Rule:** Implementation goes in `data/repositories/` when data layer is added.

### `lib/features/auth/services/auth_service.dart`
**Purpose:** Authentication API communication.
**What it does:** Calls FastAPI auth endpoints using `ApiClient`.
**Rule:** This is the only place auth feature calls the API.

### `lib/features/home/`
**Purpose:** Home/dashboard feature isolation.
**What it contains:** Home screen, home widgets, home provider, home repository.

### `lib/features/home/screens/home_screen.dart`
**Purpose:** Main dashboard page.
**What it does:** Shows post-login content.
**Rule:** Must consume `HomeProvider`.

### `lib/features/home/widgets/home_header.dart`
**Purpose:** Home header component.
**What it does:** Reusable header for home screen.
**Rule:** Feature-specific widget.

### `lib/features/home/providers/home_provider.dart`
**Purpose:** Home state management.
**What it does:** Manages home screen data using Riverpod.

### `lib/features/home/repositories/home_repository.dart`
**Purpose:** Home data contract.
**What it does:** Abstract class defining home data operations.

### `lib/features/profile/`
**Purpose:** User profile feature isolation.
**What it contains:** Profile screen, profile provider, profile repository.

### `lib/features/profile/screens/profile_screen.dart`
**Purpose:** User profile page.
**What it does:** Shows user info and settings.
**Rule:** Must consume `ProfileProvider`.

### `lib/features/profile/providers/profile_provider.dart`
**Purpose:** Profile state management.
**What it does:** Manages profile data using Riverpod.

### `lib/features/profile/repositories/profile_repository.dart`
**Purpose:** Profile data contract.
**What it does:** Abstract class defining profile data operations.

### `lib/shared/models/`
**Purpose:** Cross-feature model storage.
**What it does:** Holds models used by multiple features.
**Rule:** Use sparingly. Only for truly shared models.

### `lib/shared/widgets/`
**Purpose:** Cross-feature widget storage.
**What it does:** Holds widgets used by multiple features.
**Rule:** Use sparingly. Only for truly shared widgets.

## Rules

1. **One feature per folder under `lib/features/`** — auth, home, profile, etc.
2. **Screens live in `lib/features/<feature>/screens/`** — never in `core/`, `app/`, or `shared/`.
3. **Feature widgets live in `lib/features/<feature>/widgets/`** — only genuinely app-wide reusable widgets go in `lib/core/widgets/`.
4. **State management lives in `lib/features/<feature>/providers/`** — use Riverpod.
5. **API calls go through `lib/core/network/api_client.dart`** — never call Dio or HTTP directly from screens or providers.
6. **Endpoint paths go in `lib/core/constants/api_endpoints.dart`** — only add confirmed backend endpoints.
7. **Keep `main.dart` minimal** — it only launches the app.
8. **No product feature logic in `app/`, `core/`, or `shared/`**.

## Adding a New Feature

1. Create `lib/features/<feature_name>/`
2. Add subfolders: `screens/`, `widgets/`, `models/`, `providers/`, `repositories/`, `services/`
3. Add domain contracts in `repositories/`
4. Add API methods in `services/` using `ApiClient`
5. Add models in `models/`
6. Add providers in `providers/`
7. Add screens and widgets
8. Register routes in `lib/app/router.dart`

## FastAPI Integration Flow

```
Screen → Provider → Repository → RemoteDataSource → ApiClient → FastAPI
```

- The UI never calls Dio, HTTP, or FastAPI directly.
- All HTTP goes through `lib/core/network/api_client.dart`.
- Add auth headers in the auth interceptor inside `api_client.dart`.

## State Management

- Use Riverpod for all state management.
- One provider per feature concern.
- Provider states: initial, loading, success, error.

## Theme

- Global theme in `lib/app/theme/`
- `app_colors.dart` — color palette
- `app_text_styles.dart` — typography
- `app_theme.dart` — ThemeData assembly

## Validation

```bash
flutter pub get
flutter analyze
```
