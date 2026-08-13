# AgriAdvisor Frontend

A cross-platform Flutter client for the AgriAdvisor agricultural advisory system. It provides a farmer-focused mobile experience together with responsive advisor and Extension Planning Area (EPA) workspaces, all backed by the companion Laravel REST API.

> **Backend API:** [AgriAdvisor Backend](https://github.com/wellsmzati-create/agri-advisor-backend.git)
>
> Replace `your-username` with the owning GitHub account after both repositories are published.

## System repositories

| Component | Technology | Repository |
| --- | --- | --- |
| Frontend | Flutter and Dart | This repository |
| Backend API | Laravel and PHP | [AgriAdvisor Backend](https://github.com/wellsmzati-create/agri-advisor-backend.git) |

The backend must be running and reachable for authentication and application data. Protected requests use Laravel Sanctum bearer tokens and the versioned `/api/v1` API.

## User experiences

- **Farmers:** register and sign in, manage farms, browse crops and advice, view crop recommendations, receive seasonal notices and notifications, and chat with advisors.
- **Agricultural advisors:** use the responsive web workspace to manage farmers, farms, crop records, recommendations, crops, farming tips, seasonal notices, conversations, outbreaks, and broadcasts.
- **EPA officers:** access oversight dashboards, activity information, reports, outbreak validation, user administration, and regional notifications.
- **Role-aware navigation:** authenticated users are routed to the correct shell and theme for their assigned backend role.

## Highlights

- Flutter UI for Android and web-oriented dashboards
- Material role-specific themes
- Provider-based authentication and farmer state
- Repository-style API service layer over the `http` package
- Runtime API configuration through `--dart-define`
- Laravel Sanctum bearer-token authentication
- Automatic session handling for unauthorized responses
- Shared-preferences token persistence
- Responsive advisor and EPA workspaces
- Charts, animations, network-image caching, and internationalized formatting
- Widget tests and Flutter static analysis

## Technology stack

| Area | Technology |
| --- | --- |
| Framework | Flutter |
| Language | Dart 3.7+ |
| State management | Provider |
| Networking | `http` |
| Local preferences | `shared_preferences` |
| UI | Material, Google Fonts, Flutter Animate |
| Data visualization | FL Chart |
| Image loading | Cached Network Image |
| Testing | Flutter Test |

## Project structure

```text
lib/
|-- main.dart                 # Application bootstrap and providers
|-- app_routing.dart          # Platform and role-aware shell selection
|-- models/                   # API-facing application models
|-- providers/                # Authentication and farmer state
|-- services/
|   |-- api_client.dart       # HTTP, headers, timeouts, and API errors
|   |-- api_service.dart      # Application-facing API operations
|   `-- token_storage.dart    # Persisted Sanctum token
|-- screens/                  # Farmer mobile screens
|-- web/                      # Advisor responsive web workspace
|-- epa/                      # EPA oversight workspace
|-- theme/                    # Farmer visual system
`-- widgets/                  # Shared UI components

android/                      # Android platform host
test/                         # Flutter widget tests
```

Additional project documentation is available in:

- [`FARMER_APP_SYSTEM_DESIGN.md`](FARMER_APP_SYSTEM_DESIGN.md)
- [`TESTING_GUIDE.md`](TESTING_GUIDE.md)
- [`RUN_ON_NEW_LAPTOP.md`](RUN_ON_NEW_LAPTOP.md)

## Prerequisites

- Flutter stable with a Dart SDK compatible with `^3.7.0`
- Git
- Android Studio and the Android SDK for Android development
- Chrome for Flutter web development
- A running copy of the [AgriAdvisor backend](https://github.com/wellsmzati-create/agri-advisor-backend.git)
- An Android emulator, physical Android device, or supported browser

Install Flutter using the [official Flutter setup guide](https://docs.flutter.dev/get-started/install), then verify the toolchain:

```bash
flutter doctor
flutter devices
```

Resolve the platform issues reported by `flutter doctor` before continuing.

## Installation

### 1. Clone both repositories

```bash
git clone https://github.com/your-username/agri-advisor-backend.git
git clone https://github.com/your-username/agri-advisor-frontend.git
```

Replace `your-username` with the actual GitHub organization or username.

### 2. Start the Laravel backend

Follow the complete installation guide in the [backend README](https://github.com/wellsmzati-create/agri-advisor-backend#backend-installation). At minimum:

```bash
cd agri-advisor-backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

On Windows PowerShell, create the environment file with:

```powershell
Copy-Item .env.example .env
```

If the backend uses an asynchronous queue connection, run a worker in another terminal:

```bash
php artisan queue:work --tries=3 --timeout=120
```

The queue worker is required for queued AI recommendations to progress from `pending` to `generated`.

### 3. Install Flutter dependencies

```bash
cd agri-advisor-frontend
flutter pub get
```

### 4. Select the correct API URL

Pass the backend base URL at build or run time:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_BACKEND_HOST:8000/api/v1
```

Common development values are:

| Flutter target | `API_BASE_URL` |
| --- | --- |
| Android emulator | `http://10.0.2.2:8000/api/v1` |
| Chrome on the backend computer | `http://127.0.0.1:8000/api/v1` |
| Physical Android device | `http://YOUR_COMPUTER_LAN_IP:8000/api/v1` |
| Production | `https://api.your-domain.example/api/v1` |

The source currently contains a private-LAN development address as its fallback. Always provide `API_BASE_URL` explicitly so that builds do not accidentally depend on that machine-specific default.

For a physical device, connect the phone and computer to the same trusted network and start Laravel on an accessible interface:

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

`localhost` on an Android emulator or phone refers to that emulator or phone, not to the computer hosting Laravel. Do not expose Laravel's development server directly to the public internet.

### 5. Run the application

Android emulator or physical device:

```bash
flutter devices
flutter run -d DEVICE_ID --dart-define=API_BASE_URL=http://YOUR_BACKEND_HOST:8000/api/v1
```

Chrome:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

If this checkout does not contain Flutter's `web/` platform scaffold, generate it once before running Chrome:

```bash
flutter create --platforms=web .
```

Review generated changes before committing them.

## Full-stack startup order

1. Start the backend database and any configured queue or cache service.
2. Run Laravel migrations and optional development seeders.
3. Start the Laravel API.
4. Start the Laravel queue worker when using an asynchronous queue.
5. Confirm the selected `/api/v1` URL is reachable from the target device.
6. Run `flutter pub get` in this repository.
7. Launch Flutter with an explicit `API_BASE_URL`.

## Authentication and demo data

The app sends the Sanctum token returned by the backend as:

```http
Authorization: Bearer YOUR_TOKEN
Accept: application/json
Content-Type: application/json
```

When the backend is seeded for local development, its default demonstration accounts include:

| Role | Email | Password |
| --- | --- | --- |
| Farmer | `farmer@agri.local` | `password` |
| Advisor | `advisor@agri.local` | `password` |
| EPA officer | `epa@agri.local` | `password` |

> These are predictable development credentials. Never use them in production, publish a populated development database, or ship them as production defaults.

## Testing and code quality

Install dependencies and run static analysis:

```bash
flutter pub get
flutter analyze
```

Run the automated tests:

```bash
flutter test
```

Format and verify Dart source:

```bash
dart format lib test
dart format --output=none --set-exit-if-changed lib test
```

See [`TESTING_GUIDE.md`](TESTING_GUIDE.md) for the manual Android and advisor-dashboard validation flows.

## Building

### Android APK

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.your-domain.example/api/v1
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.your-domain.example/api/v1
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

### Web

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.your-domain.example/api/v1
```

Output is written to `build/web/`.

PowerShell users can place the commands on one line instead of using the Bash line-continuation character.

## Production checklist

Before publishing a mobile or web release:

- Replace all placeholder repository and deployment URLs.
- Pass an HTTPS production API URL through `--dart-define`.
- Configure the backend CORS policy for the deployed web origin.
- Replace the Android package identifier and application label if required.
- Configure a private Android upload key; the current release configuration uses debug signing and is not store-ready.
- Review Android cleartext traffic settings and disable cleartext HTTP for production.
- Never embed backend secrets, AI provider keys, database credentials, or administrative tokens in the Flutter build.
- Treat client-side role checks as navigation behavior only; enforce authorization on the backend.
- Review token-storage requirements. The current implementation uses `shared_preferences`; sensitive production deployments should use platform-backed secure storage.
- Test release builds on real target devices and verify session expiry, offline errors, slow networks, and unavailable backend behavior.
- Review agricultural recommendations with qualified domain experts before consequential use.

## Troubleshooting

### The phone cannot connect to Laravel

- Confirm the API process is still running.
- Confirm the phone and computer are on the same network.
- Use the computer's LAN IPv4 address, not `localhost`.
- Open the backend URL in the phone browser to test basic reachability.
- Allow the selected PHP executable and TCP port through the private-network firewall.
- Check that `API_BASE_URL` includes `/api/v1` and has no trailing slash.

### Authentication succeeds in Postman but not Flutter

- Confirm Flutter is calling the same backend environment.
- Check the API response is JSON rather than an HTML error page.
- Clear old app data if it contains a stale token.
- Verify the backend user's status and assigned role.

### Recommendations remain pending

- Start the Laravel queue worker.
- Verify the backend queue configuration and failed-jobs table.
- Check backend logs and AI provider configuration.

### Chrome reports CORS errors

- Add the exact Flutter web origin to the backend CORS configuration.
- Clear Laravel's cached configuration after changing environment or CORS settings.
- Do not solve production CORS issues by allowing every origin with credentials.

## Contributing

Contributions are welcome. Please keep changes focused, preserve role-based behavior, and:

1. Create a branch from the default branch.
2. Keep networking logic in the service layer rather than widgets.
3. Add or update tests for behavioral changes.
4. Run `flutter analyze`, `flutter test`, and the formatter.
5. Document changes to API contracts, runtime definitions, platforms, or build requirements.

Do not include real farmer information, production tokens, API keys, signing keys, generated builds, IDE files, or crash dumps in commits or issues.

## Security

Report suspected vulnerabilities privately to the repository maintainers instead of opening a public issue. Add a monitored security contact or a `SECURITY.md` file before publication.

## License

No root license file is currently present. Add a `LICENSE` file with the intended open-source license and correct copyright holder before publishing; do not assume the backend's package license automatically applies to this repository.

---

AgriAdvisor keeps farmers, advisors, and extension officers connected through one role-aware client and a shared, versioned agricultural API.
