# rideros_ai — Flutter app (Phase 3–4)

Android app for RiderOS AI. Flutter 3.47 / Dart 3.13. Architecture: `docs/SYSTEM_ARCHITECTURE.md` §2.1.
API contract: `backend/README.md`.

Status: **P3a** (design system, router + auth guard, API client with token refresh, splash, login,
register, forgot/reset password, onboarding) and **P3b** (bottom navigation, home dashboard, TrueProfit
dashboard with trend chart, income / expense / work-session lists and forms), **P3c** (Pickup Intelligence,
Shift Simulator, Profile; Pickup was removed on 2026-11-18 and its tab is now the Road map) and **Phase 4** (end-to-end journey against the real API, reset deep link).

## Run

```powershell
# repository root: backend + DB (API on http://127.0.0.1:8000/api/v1)
docker compose up --build

cd mobile
flutter pub get
flutter run                                   # Android emulator: API at http://10.0.2.2:8000/api/v1 (default)
# physical device over USB:
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

- `API_BASE_URL` is a build-time define. Release builds refuse a non-`https` URL.
- Plain HTTP is allowed only in **debug** builds and only to `10.0.2.2`, `127.0.0.1` and `localhost`
  (`android/app/src/debug/res/xml/network_security_config.xml`).
- Forgot password (D5): in development the backend has no e-mail provider and writes the reset link to its log
  (`docker compose logs backend`, line `DEV ONLY password reset link`). Open it on the emulator with
  `adb shell am start -a android.intent.action.VIEW -d "'rideros://reset-password?token=...'"`, or paste the
  whole link (or the token) on the "ตั้งรหัสผ่านใหม่" screen. The link opens the reset screen signed in or out;
  after a reset the server signs out every device, so the app signs out too and shows the login screen.

## Checks

```powershell
flutter analyze                 # must report no issues
flutter test                    # unit + widget + navigation tests
flutter test --coverage         # coverage/lcov.info
dart format --set-exit-if-changed lib test
```

### End-to-end journey (Phase 4)

Needs the compose stack (`docker compose up -d` at the root, `/api/v1/ready` ok with the model) and the
emulator `emulator-5554`. One command builds, installs and drives the real app through the UI, then checks
the numbers against PostgreSQL:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_journey_test.dart -d emulator-5554
```

- Journey (`integration_test/app_journey_test.dart`): Register (signs in) → Onboarding → Logout → Login →
  Dashboard → add income → add expense → TrueProfit → two scenarios → Compare. It clears the stored refresh token first; the ride intro plays as in the real app.
- Host driver (`test_driver/integration_test.dart`): compares what the screens showed with SQL through
  `docker compose exec db psql` (profile, today's revenue/expenses/net/hours/
  net per hour, each compared scenario, best net), prints every check, then deletes the throwaway
  `e2e+<timestamp>@example.com` account with `DELETE /me` and checks that no rows are left.
- `$env:E2E_KEEP = "1"` keeps the account. When a check fails the account is kept for a look.
- About 40 s on the emulator after the first build.

After changing a freezed/json model or `lib/l10n/app_th.arb`:

```powershell
dart run build_runner build     # *.freezed.dart, *.g.dart
flutter gen-l10n                # lib/l10n/app_localizations*.dart (also runs on pub get / build)
```

## Layout

```
lib/
  main.dart                 ProviderScope (automatic provider retry off) + RiderOsApp
  app/                      app.dart, routes.dart, router.dart (authRedirect guard, bottom-nav shell), app_shell.dart,
                            theme/ (tokens, light/dark)
  core/
    config/                 AppConfig (API_BASE_URL)
    errors/                 AppFailure (sealed), mapToFailure (dio → failure), Thai failure messages
    network/                dio clients, AuthInterceptor (bearer + refresh-and-retry), SessionTokenManager
    storage/                RefreshTokenStore (flutter_secure_storage)
    presentation/           SubmitNotifier (one-shot form actions)
    utils/                  validators (mirror backend rules), Decimal JSON converters
    widgets/                design-system widgets: buttons, fields, banners, Loading/Error/Empty, AsyncValueView
  features/<name>/          data/ → domain/ → presentation/
    auth/                   session controller, login, register, forgot/reset, splash
    onboarding/             first rider profile
    profile/                rider profile model + repository
    dashboard/              home: today + this week (server figures), shortcuts
    profit/                 TrueProfit: summary/trends, records (income, expenses, work sessions) + forms
  l10n/                     app_th.arb (Thai UI strings) + generated localizations
test/
  helpers/                  fakes, fake HTTP adapter, pump helpers
  unit/                     core, features, router guard
  widget/                   screens (validation + states) and navigation (whole app)
```

## TrueProfit rules in the app

- No money maths on the device: every total, net profit and per-hour value comes from `/profit/summary` and
  `/profit/trends`. After each create/update/delete `profitDataRevisionProvider` is bumped and every list and
  summary reloads. Money is shown from `Decimal` (never `double`); the chart converts only to draw bar heights.
- Work sessions are entered as start date + start/end time in the device's time zone and sent with the offset.
  An end at or before the start is the next day; equal times are rejected.
- Income may link to a work session that started on the same date; a linked record sends `working_hours: null`
  (the backend counts the session's hours instead).

## Session and tokens

- Access token (15 min) in memory only; refresh token (30 days, rotated) in Android Keystore-backed secure
  storage. Android auto backup is off so the encrypted value is never restored to another device.
- A 401 with `token_expired` / `invalid_token` / `not_authenticated` triggers one shared refresh
  (single flight, so a rotated refresh token is never sent twice) and a retry. A rejected refresh token clears
  the session and returns to login with "เซสชันหมดอายุ".
- Start-up: stored refresh token → refresh → `GET /me` → `GET /me/rider-profile`. `is_configured: false` opens
  onboarding. Offline at start keeps the token and shows a retry.
- Money and other decimals use `Decimal` and travel as JSON strings, never `double`.
