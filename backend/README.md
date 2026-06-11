# Poketto Backend

Laravel 12 backend for Poketto. This app is the REST API, database owner, rule-based warning engine, and current Blade admin panel host.

## Setup

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

## API

Use Bearer tokens from `/api/login` or `/api/register`.

- `POST /api/register`
- `POST /api/login`
- `POST /api/logout`
- `GET /api/me`
- `GET /api/dashboard/summary`
- `GET|POST /api/transactions`
- `GET|PUT|DELETE /api/transactions/{id}`
- `GET|POST /api/categories`
- `GET|PUT|DELETE /api/categories/{id}`
- `GET|PUT /api/user-settings`
- `GET /api/budget-alerts`
- `GET /api/exchange-rates`

Exchange rates use `EXCHANGE_RATE_API_KEY` when available and fall back to a safe stub.

## Deploy Backend Laravel ke Render Free + Supabase PostgreSQL

Local development boleh tetap SQLite, tetapi production di Render Free harus memakai Supabase PostgreSQL. Jangan pakai SQLite production karena filesystem Render Free tidak persistent.

### Supabase

Ambil connection info dari Supabase Dashboard > Project Settings > Database. Prioritaskan direct connection PostgreSQL:

```env
DB_CONNECTION=pgsql
DB_HOST=db.your-project-ref.supabase.co
DB_PORT=5432
DB_DATABASE=postgres
DB_USERNAME=postgres
DB_PASSWORD=your-supabase-database-password
DB_SSLMODE=require
DB_SCHEMA=public
DB_PGSQL_DISABLE_PREPARES=false
```

Jika memakai Supabase Transaction Pooler, gunakan host/port pooler dari dashboard dan aktifkan:

```env
DB_PGSQL_DISABLE_PREPARES=true
```

Service role key Supabase tidak boleh masuk frontend. Laravel backend tetap menjadi satu-satunya pihak yang mengakses database.

### Render Web Service

- Root Directory: `backend`
- If Render offers a PHP runtime, use this Build Command:

```bash
composer install --no-dev --optimize-autoloader && php artisan config:clear && php artisan route:clear && php artisan view:clear
```

- Start Command:

```bash
php artisan migrate --force && php artisan serve --host 0.0.0.0 --port $PORT
```

If Render does not offer a PHP runtime, choose Docker instead. Keep Root Directory as `backend`; Render will use `backend/Dockerfile`, install PHP extensions including `pdo_pgsql`, run migrations, and bind Laravel to `$PORT`.

### Environment Variables Render

```env
APP_NAME=Poketto
APP_ENV=production
APP_KEY=base64:generate-with-php-artisan-key-generate-show
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

Generate `APP_KEY`:

```bash
php artisan key:generate --show
```

### Local Validation

```bash
composer install
php artisan config:clear
php artisan migrate:fresh --seed
php artisan test
```
