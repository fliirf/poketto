# Poketto

Poketto is a personal finance tracker monorepo with Laravel as the REST API backend and Next.js as the main web frontend.

## Architecture

```txt
Next.js Web Frontend
        |
        +-- Laravel REST API -- Database
        |
Flutter Mobile App
```

The backend owns database access, authentication, dashboard summaries, exchange-rate fetching, and rule-based financial warnings. Mobile consumes the same API and keeps SQLite only as an offline/demo fallback.

## Folder Structure

```txt
poketto/
├── backend/  # Laravel REST API, database, legacy Blade fallback/PDF export
├── .web/     # Next.js user-facing web frontend
├── web/      # Legacy web notes placeholder
├── mobile/   # Flutter app
├── README.md
└── .gitignore
```

## Tech Stack

- Backend: Laravel 12, Sanctum, Eloquent, MySQL-compatible migrations.
- Web: Next.js in `/.web`, consuming the Laravel REST API.
- Mobile: Flutter, HTTP API client, secure token storage, SQLite fallback, geolocation.

## Backend Setup

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

Set this in `backend/.env` so legacy Laravel web routes redirect to Next.js:

```txt
FRONTEND_WEB_URL=http://127.0.0.1:3000
```

Currency exchange rates use ExchangeRate-API. Add a real key to enable live rates:

```txt
EXCHANGE_RATE_API_KEY=your_exchange_rate_api_key
```

Without a key or stored rates, the dashboard keeps loading and shows an honest "Kurs mata uang belum tersedia" fallback.

## Deploy Backend Laravel ke Render Free + Supabase PostgreSQL

Backend Laravel bisa tetap memakai SQLite untuk local development, tetapi production di Render harus memakai PostgreSQL dari Supabase karena filesystem Render Free tidak persistent.

### 1. Siapkan Supabase PostgreSQL

1. Buat project Supabase.
2. Buka Project Settings > Database.
3. Ambil direct connection PostgreSQL host, port, database, username, dan password.
4. Pakai direct connection lebih dulu untuk backend Render. Jika memakai Transaction Pooler, set `DB_PGSQL_DISABLE_PREPARES=true` di Render.
5. Jangan pernah expose Supabase service role key ke Next.js atau mobile. Laravel backend saja yang mengakses database.

### 2. Buat Web Service di Render

- Type: Web Service
- Root Directory: `backend`
- Runtime: PHP, if available
- Build Command:

```bash
composer install --no-dev --optimize-autoloader && php artisan config:clear && php artisan route:clear && php artisan view:clear
```

- Start Command:

```bash
php artisan migrate --force && php artisan serve --host 0.0.0.0 --port $PORT
```

If PHP is not listed in Render, choose **Docker**. Keep Root Directory as `backend`; Render will use `backend/Dockerfile`, install Laravel dependencies and PostgreSQL PHP extensions, then run the same migrate-and-serve startup flow.

### 3. Environment Variables Render

```env
APP_NAME=Poketto
APP_ENV=production
APP_KEY=base64:generate-this-locally-or-in-render-shell
APP_DEBUG=false
APP_URL=https://your-render-service.onrender.com
FRONTEND_WEB_URL=https://your-nextjs-frontend-domain

DB_CONNECTION=pgsql
DB_HOST=db.your-project-ref.supabase.co
DB_PORT=5432
DB_DATABASE=postgres
DB_USERNAME=postgres
DB_PASSWORD=your-supabase-database-password
DB_SSLMODE=require
DB_SCHEMA=public
DB_PGSQL_DISABLE_PREPARES=false

SESSION_DRIVER=database
CACHE_STORE=database
QUEUE_CONNECTION=database
LOG_CHANNEL=stack
LOG_LEVEL=error
EXCHANGE_RATE_API_KEY=
```

Generate `APP_KEY` sekali dengan:

```bash
cd backend
php artisan key:generate --show
```

Jika Render memakai Supabase Transaction Pooler, ubah:

```env
DB_HOST=aws-xxx.pooler.supabase.com
DB_PORT=6543
DB_USERNAME=postgres.your-project-ref
DB_PGSQL_DISABLE_PREPARES=true
```

### 4. Local Database

Local development tetap bisa memakai SQLite:

```env
DB_CONNECTION=sqlite
DB_DATABASE=database/database.sqlite
```

Lalu jalankan:

```bash
cd backend
composer install
php artisan config:clear
php artisan migrate:fresh --seed
php artisan test
```

## Next.js Web Setup

```bash
cd .web
npm install
cp .env.example .env.local
npm run dev -- --hostname 127.0.0.1 --port 3000
```

Set this in `.web/.env.local`:

```txt
NEXT_PUBLIC_API_BASE_URL=http://127.0.0.1:8000/api
```

The Next.js app is the main user-facing web UI. Laravel Blade views are preserved as legacy/fallback files; GET web routes redirect to Next.js. The legacy PDF export route remains in Laravel until it is migrated.

## Mobile Setup

```bash
cd mobile
dart pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

## API Endpoints

- `POST /api/register`
- `POST /api/login`
- `POST /api/logout`
- `GET /api/me`
- `GET /api/dashboard/summary`
- `GET|POST|PUT|DELETE /api/transactions`
- `GET /api/transactions/export-pdf`
- `GET|POST|PUT|DELETE /api/categories`
- `GET|PUT /api/user-settings`
- `GET /api/budget-alerts`
- `GET /api/exchange-rates`

## Demo Flow

1. Run backend with `php artisan serve --host=127.0.0.1 --port=8000`.
2. Run Next.js web from `/.web`.
3. Run mobile separately with `API_BASE_URL=http://10.0.2.2:8000/api`.
4. Register/login.
5. Add category and monthly budget from web.
6. Add transactions from web or mobile.
7. Check dashboard summary and reports.
8. Add expenses until budget warnings appear.
9. Logout.
