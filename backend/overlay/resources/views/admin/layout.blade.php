<!doctype html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('titre', 'Administration') — Planify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        body { background: #f5f7fa; }
        .navbar { background: #0f172a; }
        .carte-stat { border: 0; border-radius: 14px; box-shadow: 0 2px 8px rgba(0,0,0,.05); }
        .carte-stat .valeur { font-size: 1.8rem; font-weight: 700; }
        .pastille { width: 14px; height: 14px; border-radius: 50%; display: inline-block; vertical-align: middle; }
    </style>
</head>
<body>
@auth
<nav class="navbar navbar-expand-lg navbar-dark mb-4">
    <div class="container">
        <a class="navbar-brand fw-bold" href="{{ route('admin.tableau') }}">
            <i class="bi bi-wallet2 text-success"></i> Planify <small class="text-secondary">admin</small>
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#menu">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="menu">
            <ul class="navbar-nav me-auto">
                <li class="nav-item"><a class="nav-link @if(request()->routeIs('admin.tableau')) active @endif" href="{{ route('admin.tableau') }}">Statistiques</a></li>
                <li class="nav-item"><a class="nav-link @if(request()->routeIs('admin.categories.*')) active @endif" href="{{ route('admin.categories.index') }}">Catégories système</a></li>
                <li class="nav-item"><a class="nav-link @if(request()->routeIs('admin.signalements*')) active @endif" href="{{ route('admin.signalements') }}">Signalements</a></li>
            </ul>
            <form method="POST" action="{{ route('admin.deconnexion') }}">
                @csrf
                <button class="btn btn-outline-light btn-sm"><i class="bi bi-box-arrow-right"></i> Déconnexion</button>
            </form>
        </div>
    </div>
</nav>
@endauth
<main class="container pb-5">
    @if (session('succes'))
        <div class="alert alert-success">{{ session('succes') }}</div>
    @endif
    @yield('contenu')
</main>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
