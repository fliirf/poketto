# PROJECT_STATE

## Current Goal

Poketto is being stabilized as an integrated personal finance tracker where Laravel backend is the single source of truth, Blade web/admin consumes the backend API/service layer, and Flutter mobile consumes the same API with SQLite fallback only for offline/demo.

Recent focus: fix Laravel Blade web/admin bugs:

- Web transaction amount input must accept small values like `10`.
- Web transaction forms must not expose location inputs.
- Web dashboard and transaction history need date/month/type/category filters.
- Chart data must come from real backend/database data and respect filters.

## Architecture

```txt
web/admin Blade ─┐
                 ├── Laravel Backend REST API ─── Database
Flutter mobile ──┘
```

- `backend/`: Laravel 12 app, REST API, DB/migrations, business logic, current Blade admin UI.
- `mobile/`: Flutter app, API-first, secure token storage, geolocation, SQLite fallback.
- `web/`: env/docs placeholder for future standalone web client; active web UI is Blade in `backend/`.

## Key Decisions So Far

- Use Laravel Sanctum token auth for API.
- Web Blade uses session auth, then `App\Services\PokettoApiClient` dispatches internal `/api/*` requests with a web Sanctum token.
- Backend owns warnings, dashboard summary, filters, exchange-rate fetch/stub, and database writes.
- Mobile may keep SQLite, but API/backend is primary source when token exists.
- Location fields remain in API/database for mobile, but are hidden from web/admin forms.
- App timezone set to `Asia/Jakarta` via `APP_TIMEZONE`.

## Changed Files Of Interest

Backend/API:

- `backend/routes/api.php`
- `backend/routes/web.php`
- `backend/app/Services/PokettoApiClient.php`
- `backend/app/Services/BudgetAlertService.php`
- `backend/app/Services/ExchangeRateService.php`
- `backend/app/Http/Controllers/Api/AuthController.php`
- `backend/app/Http/Controllers/Api/TransactionController.php`
- `backend/app/Http/Controllers/Api/CategoryController.php`
- `backend/app/Http/Controllers/Api/DashboardController.php`
- `backend/app/Http/Controllers/Api/UserSettingsController.php`
- `backend/app/Http/Controllers/TransactionController.php`
- `backend/app/Http/Controllers/CategoryController.php`
- `backend/app/Http/Controllers/UserSettingsController.php`
- `backend/app/Models/*` for `UserSetting`, `BudgetAlert`, `ExchangeRate`, and updated relations/fillables.
- `backend/database/migrations/*` added Sanctum and proposal tables/columns.
- `backend/config/app.php`
- `backend/config/services.php`
- `backend/.env.example`

Blade web/admin:

- `backend/resources/views/layouts/app.blade.php`
- `backend/resources/views/dashboard.blade.php`
- `backend/resources/views/transactions/create.blade.php`
- `backend/resources/views/transactions/edit.blade.php`
- `backend/resources/views/transactions/index.blade.php`
- `backend/resources/views/categories/index.blade.php`
- `backend/resources/views/categories/edit.blade.php`
- `backend/resources/views/settings/edit.blade.php`

Mobile touched lightly:

- `mobile/lib/data/services/user_settings_service.dart`
- `mobile/lib/data/repositories/user_settings_repository.dart`
- `mobile/lib/data/repositories/app_repositories.dart`
- `mobile/lib/budget_settings_page.dart`
- `mobile/.env.example`

Docs/config:

- `README.md`
- `backend/README.md`
- `web/README.md`
- `web/.env.example`
- `.gitignore`
- `PROJECT_STATE.md`

## Current API Surface

Protected by `auth:sanctum` unless noted:

- `POST /api/register` public
- `POST /api/login` public
- `POST /api/logout`
- `GET /api/me`
- `GET /api/dashboard/summary`
- `GET|POST /api/transactions`
- `GET|PUT|PATCH|DELETE /api/transactions/{transaction}`
- `GET|POST /api/categories`
- `GET|PUT|PATCH|DELETE /api/categories/{category}`
- `GET|PUT /api/user-settings`
- `GET /api/budget-alerts`
- `GET /api/exchange-rates`

Filters now supported:

- `GET /api/transactions?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD`
- `GET /api/transactions?month=YYYY-MM`
- `GET /api/transactions?type=income|expense`
- `GET /api/transactions?category_id=ID`
- Same filter params supported by `GET /api/dashboard/summary`.

## Recent Manual Test Results

Passed via web session + CSRF and API smoke tests:

- Web create category.
- Web update settings/daily budget.
- Web create transaction amount `10`.
- Web create transaction amount `25000`.
- Web transaction saves without location (`location_* = null`).
- API/mobile-style transaction with `location_name` appears in web.
- Transaction date range filter works.
- Dashboard month filter changes summary/chart data.
- Warning appears when daily/category threshold is crossed.

## Commands To Run

Backend:

```bash
cd backend
composer install
php artisan migrate
php artisan route:list
php artisan test
npm install
npm run build
php artisan serve --host=127.0.0.1 --port=8000
```

Mobile:

```bash
cd mobile
dart pub get
flutter test --no-pub
flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Dev URL:

- Web/admin: `http://127.0.0.1:8000`
- Mobile emulator API base: `http://10.0.2.2:8000/api`

## Pending Tasks

- Consider adding focused feature tests for API filters and web form submissions.
- Consider making PDF export respect the new filter model beyond simple month/year.
- Consider reducing noisy `Log::info` entries in `PokettoApiClient` after debugging is no longer needed.
- Verify category delete behavior when transactions exist; current API deletes category and may cascade/null depending DB constraints.
- Polish UI copy/encoding artifacts in Blade views where old emoji/text renders oddly.

## Known Bugs / Risks

- Git status is large because earlier assimilation moved `pokettotubes-main/` to `mobile/` and `poketto-web/` to `backend/`; expect many deletes/adds from that structural rename.
- Existing root `.idea/*` files show local modifications; avoid reverting user/IDE changes.
- Browser automation plugin had trouble typing due to virtual clipboard; manual validation was done through HTTP web session + CSRF instead.
- Web is still Blade inside Laravel, not a separate Next.js frontend.
- Exchange rate endpoint is a safe stub unless `EXCHANGE_RATE_API_KEY` is configured.

## Last Validation

Last successful backend validation:

```bash
php artisan route:list
php artisan test
npm run build
```

Results:

- Route list: passed, 44 routes.
- Tests: passed, 2 tests.
- Vite build: passed.
