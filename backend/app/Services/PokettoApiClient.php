<?php

namespace App\Services;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;
use Illuminate\Validation\ValidationException;

class PokettoApiClient
{
    public function get(string $path, array $query = []): array
    {
        return $this->dispatch('GET', $path, $query);
    }

    public function post(string $path, array $payload = []): array
    {
        return $this->dispatch('POST', $path, $payload);
    }

    public function put(string $path, array $payload = []): array
    {
        return $this->dispatch('PUT', $path, $payload);
    }

    public function delete(string $path): array
    {
        return $this->dispatch('DELETE', $path);
    }

    private function dispatch(string $method, string $path, array $payload = []): array
    {
        $this->ensureToken();

        $server = [
            'HTTP_ACCEPT' => 'application/json',
            'CONTENT_TYPE' => 'application/json',
        ];

        if (session('api_token')) {
            $server['HTTP_AUTHORIZATION'] = 'Bearer '.session('api_token');
        }

        $request = Request::create(
            '/api/'.ltrim($path, '/'),
            $method,
            $method === 'GET' ? $payload : [],
            [],
            [],
            $server,
            $method === 'GET' ? null : json_encode($payload),
        );

        Log::info('Web API client request', [
            'method' => $method,
            'path' => '/api/'.ltrim($path, '/'),
            'payload' => $payload,
            'user_id' => Auth::id(),
            'has_token' => (bool) session('api_token'),
        ]);

        $response = Route::dispatch($request);
        $decoded = json_decode($response->getContent(), true) ?: [];

        Log::info('Web API client response', [
            'method' => $method,
            'path' => '/api/'.ltrim($path, '/'),
            'status' => $response->getStatusCode(),
            'response' => $decoded,
        ]);

        if ($response->getStatusCode() >= 400) {
            if ($response->getStatusCode() === 422) {
                throw ValidationException::withMessages($decoded['errors'] ?? ['api' => [$decoded['message'] ?? 'Validation failed']]);
            }

            if ($response->getStatusCode() === 401) {
                abort(401, 'Sesi API web tidak valid. Silakan login ulang.');
            }

            abort($response->getStatusCode(), $decoded['message'] ?? 'API request failed');
        }

        return $decoded['data'] ?? [];
    }

    private function ensureToken(): void
    {
        if (! Auth::check() || session('api_token')) {
            return;
        }

        session()->put('api_token', Auth::user()->createToken('poketto-web')->plainTextToken);
    }
}
