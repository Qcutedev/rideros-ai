# rideros_ai — Flutter app (Phase 3)

Android app for RiderOS AI. Flutter 3.47 / Dart 3.13. Architecture: `docs/SYSTEM_ARCHITECTURE.md` §2.1.
API contract: `backend/README.md`.

Status: **P3a** (design system, router + auth guard, API client with token refresh, splash, login,
register, forgot/reset password, onboarding) and **P3b** (bottom navigation, home dashboard, TrueProfit
dashboard with trend chart, income / expense / work-session lists and forms). P3c screens follow.

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
  (`docker compose logs backend`, line `DEV ONLY password reset link`). Paste the whole link (or the token) on
  the "ตั้งรหัสผ่านใหม่" screen.

## Checks

```powershell
flutter analyze                 # must report no issues
flutter test                    # unit + widget + navigation tests
flutter test --coverage         # coverage/lcov.info
dart format --set-exit-if-changed lib test
```

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
