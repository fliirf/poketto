@extends('layouts.app')

@section('content')
<style>
    @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap');
    @import url('https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css');

    body {
        font-family: 'Poppins', sans-serif;
        background-color: #ffffff;
        color: #333;
    }

    .auth-container {
        max-width: 400px;
        margin: 50px auto;
        padding: 20px;
        text-align: center;
    }

    .brand-section {
        margin-bottom: 40px;
    }

    .brand-logo {
        width: 300px;
        height: auto;
    }

    .brand-name {
        font-weight: 800;
        font-size: 1.8rem;
        color: #f28f33;
        letter-spacing: 1px;
        margin-bottom: 0;
    }

    .brand-tagline {
        font-size: 0.85rem;
        color: #666;
        font-weight: 400;
    }

    .page-title {
        font-weight: 700;
        font-size: 1.5rem;
        margin-bottom: 30px;
        color: #000;
    }

    /* Input Styling */
    .input-group-custom {
        position: relative;
        margin-bottom: 20px;
    }

    .form-control-custom {
        width: 100%;
        padding: 12px 20px 12px 45px;
        border-radius: 30px;
        border: 1.5px solid #e0e0e0;
        background-color: #fff;
        font-size: 0.95rem;
        transition: all 0.3s;
    }

    .form-control-custom:focus {
        outline: none;
        border-color: #f28f33;
        box-shadow: 0 0 8px rgba(242, 143, 51, 0.2);
    }

    .input-icon-left {
        position: absolute;
        left: 18px;
        top: 50%;
        transform: translateY(-50%);
        color: #999;
        font-size: 1.1rem;
    }

    .input-icon-right {
        position: absolute;
        right: 18px;
        top: 50%;
        transform: translateY(-50%);
        color: #999;
        cursor: pointer;
        font-size: 1.1rem;
    }

    /* Button Styling */
    .btn-poketto {
        background-color: #f28f33;
        color: white;
        border: none;
        border-radius: 30px;
        padding: 12px;
        width: 100%;
        font-weight: 700;
        font-size: 1.1rem;
        margin-top: 10px;
        box-shadow: 0 4px 15px rgba(242, 143, 51, 0.3);
        transition: 0.3s;
    }

    .btn-poketto:hover {
        background-color: #e07e22;
        transform: translateY(-2px);
    }

    .auth-footer {
        margin-top: 25px;
        font-size: 0.9rem;
        color: #666;
    }

    .auth-footer a {
        color: #f28f33;
        text-decoration: none;
        font-weight: 600;
    }

    .forgot-password {
        display: block;
        text-align: right;
        font-size: 0.8rem;
        margin-top: -15px;
        margin-bottom: 20px;
        margin-right: 10px;
        color: #999;
        text-decoration: none;
    }
</style>

<div class="auth-container">
    <div class="brand-section">
        <img src="cute-removebg-preview 1.png" alt="Logo" class="brand-logo">
        <h1 class="brand-name">POKETTO</h1>
        <p class="brand-tagline">Keuangan Teratur, Hidup Makmur</p>
    </div>

    <h2 class="page-title">Masuk ke Akun Anda</h2>

    @if($errors->any())
        <div class="alert alert-danger" style="border-radius: 20px; font-size: 0.85rem;">
            <i class="bi bi-exclamation-circle me-2"></i> {{ $errors->first() }}
        </div>
    @endif

    <form action="/login" method="POST">
        @csrf
        
        <div class="input-group-custom">
            <i class="bi bi-envelope input-icon-left"></i>
            <input type="email" name="email" class="form-control-custom" placeholder="Email atau Username" value="{{ old('email') }}" required>
        </div>

        <div class="input-group-custom">
            <i class="bi bi-lock input-icon-left"></i>
            <input type="password" name="password" id="loginPass" class="form-control-custom" placeholder="Kata Sandi" required>
            <i class="bi bi-eye-slash input-icon-right" onclick="toggleLoginPass()"></i>
        </div>

        <a href="#" class="forgot-password">Lupa Kata Sandi?</a>

        <button type="submit" class="btn-poketto">Masuk</button>
    </form>

    <div class="auth-footer">
        Belum punya akun? <a href="/register">Daftar</a>
    </div>
</div>

<script>
    function toggleLoginPass() {
        const input = document.getElementById('loginPass');
        const icon = event.target;
        if (input.type === "password") {
            input.type = "text";
            icon.classList.replace('bi-eye-slash', 'bi-eye');
        } else {
            input.type = "password";
            icon.classList.replace('bi-eye', 'bi-eye-slash');
        }
    }
</script>
@endsection