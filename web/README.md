# Poketto Web

The active user-facing web frontend is the Next.js app in `/.web`.
Laravel remains the REST API backend, while Blade views in `backend/resources/views`
are preserved as legacy/fallback files and for the existing PDF export route.

Use this in `/.web/.env.local`:

```txt
NEXT_PUBLIC_API_BASE_URL=http://127.0.0.1:8000/api
```

Use this in `backend/.env`:

```txt
FRONTEND_WEB_URL=http://127.0.0.1:3000
EXCHANGE_RATE_API_KEY=your_exchange_rate_api_key
```

`EXCHANGE_RATE_API_KEY` is optional for local development. If it is empty and no rates are stored yet, the Next.js dashboard keeps the exchange-rate card visible and shows a fallback message.

Run locally:

```bash
cd backend
php artisan serve --host=127.0.0.1 --port=8000

cd ../.web
npm install
npm run dev -- --hostname 127.0.0.1 --port 3000
```
