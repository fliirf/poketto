<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Poketto - Keuangan Teratur, Hidup Makmur</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700;800&display=swap" rel="stylesheet">
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <style>
        body { 
            background-color: #f8f9fa; 
            font-family: 'Poppins', sans-serif;
            color: #333;
        }

        .navbar {
            background-color: #ffffff !important;
            border-bottom: 2px solid #f28f33;
            padding: 15px 0;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        }

        .navbar-brand {
            font-weight: 800;
            color: #f28f33 !important;
            font-size: 1.5rem;
            letter-spacing: 1px;
        }

        .nav-link-custom {
            color: #666;
            font-weight: 600;
            font-size: 0.95rem;
            text-decoration: none;
            transition: 0.3s;
        }

        .nav-link-custom:hover {
            color: #f28f33;
        }

        .btn-register-nav {
            background-color: #f28f33;
            color: white !important;
            border-radius: 20px;
            padding: 6px 25px;
            font-weight: 600;
            font-size: 0.95rem;
            transition: 0.3s;
            border: none;
        }

        .btn-register-nav:hover {
            background-color: #e07e22;
            transform: translateY(-1px);
            box-shadow: 0 4px 10px rgba(242, 143, 51, 0.3);
        }

        .user-name {
            font-weight: 600;
            color: #333;
        }

        /* Container styling agar tidak terlalu mepet ke pinggir */
        .main-content {
            padding-top: 40px;
            padding-bottom: 40px;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg sticky-top">
        <div class="container">
            <a class="navbar-brand" href="{{ Auth::check() ? '/dashboard' : '/' }}">
                POKETTO
            </a>
            
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>

            <div class="collapse navbar-collapse" id="navbarNav">
                <div class="ms-auto">
                    <ul class="navbar-nav align-items-center gap-3">
                        @guest
                            <li class="nav-item">
                                <a class="nav-link-custom" href="/login">Masuk</a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link btn-register-nav" href="/register">Daftar</a>
                            </li>
                        @endguest

                        @auth
                            <li class="nav-item d-none d-lg-block">
                                <span class="text-muted small">Selamat datang,</span>
                                <span class="user-name">{{ Auth::user()->name }}</span>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link-custom" href="{{ route('dashboard') }}">Dashboard</a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link-custom" href="{{ route('transactions.index') }}">Transaksi</a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link-custom" href="{{ route('categories.index') }}">Kategori</a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link-custom" href="{{ route('settings.edit') }}">Settings</a>
                            </li>
                            <li class="nav-item">
                                <form action="/logout" method="POST" class="d-inline">
                                    @csrf
                                    <button type="submit" class="btn btn-outline-danger btn-sm rounded-pill px-3">
                                        <i class="bi bi-box-arrow-right me-1"></i> Logout
                                    </button>
                                </form>
                            </li>
                        @endauth
                    </ul>
                </div>
            </div>
        </div>
    </nav>

    <div class="container main-content">
        @if(session('success'))
            <div class="alert alert-success alert-dismissible fade show border-0 shadow-sm rounded-4 px-4 mb-4" role="alert">
                {{ session('success') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
        @endif

        @if(session('error'))
            <div class="alert alert-danger alert-dismissible fade show border-0 shadow-sm rounded-4 px-4 mb-4" role="alert">
                {{ session('error') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
        @endif

        @if($errors->any())
            <div class="alert alert-danger border-0 shadow-sm rounded-4 px-4 mb-4" role="alert">
                <strong>Input belum valid.</strong>
                <ul class="mb-0 mt-2">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        @yield('content')
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</body>
</html>
