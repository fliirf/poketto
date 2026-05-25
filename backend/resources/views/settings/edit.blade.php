@extends('layouts.app')

@section('content')
<div class="container" style="max-width: 720px;">
    <div class="card border-0 shadow-sm" style="border-radius: 16px;">
        <div class="card-body p-4">
            <h4 class="fw-bold mb-4">User Settings</h4>
            <form action="{{ route('settings.update') }}" method="POST">
                @csrf
                @method('PUT')
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Daily Budget</label>
                        <input type="number" name="daily_budget" class="form-control rounded-pill" value="{{ old('daily_budget', $settings->daily_budget ?? 100000) }}" min="0" step="1" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Monthly Budget</label>
                        <input type="number" name="monthly_budget" class="form-control rounded-pill" value="{{ old('monthly_budget', $settings->monthly_budget ?? 2500000) }}" min="0" step="1" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Currency</label>
                        <input type="text" name="currency" class="form-control rounded-pill" value="{{ old('currency', $settings->currency ?? 'IDR') }}" maxlength="8" required>
                    </div>
                    <div class="col-md-6 d-flex align-items-end gap-4">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" role="switch" name="notification_enabled" value="1" id="notificationEnabled" {{ old('notification_enabled', $settings->notification_enabled ?? true) ? 'checked' : '' }}>
                            <label class="form-check-label" for="notificationEnabled">Notifikasi</label>
                        </div>
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" role="switch" name="location_enabled" value="1" id="locationEnabled" {{ old('location_enabled', $settings->location_enabled ?? true) ? 'checked' : '' }}>
                            <label class="form-check-label" for="locationEnabled">Lokasi</label>
                        </div>
                    </div>
                </div>

                <div class="mt-4">
                    <button type="submit" class="btn btn-dark rounded-pill px-4">Simpan Settings</button>
                    <a href="{{ route('dashboard') }}" class="btn btn-link text-decoration-none text-muted">Kembali</a>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
