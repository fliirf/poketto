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
