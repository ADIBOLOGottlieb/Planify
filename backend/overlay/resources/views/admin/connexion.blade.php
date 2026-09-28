@extends('admin.layout')
@section('titre', 'Connexion')

@section('contenu')
<div class="row justify-content-center mt-5">
    <div class="col-md-5 col-lg-4">
        <div class="card carte-stat p-4">
            <h1 class="h4 mb-1"><i class="bi bi-wallet2 text-success"></i> Planify</h1>
            <p class="text-secondary mb-4">Interface d'administration</p>
            <form method="POST" action="{{ url()->current() }}">
                @csrf
                <div class="mb-3">
                    <label class="form-label" for="email">Email</label>
                    <input class="form-control @error('email') is-invalid @enderror" id="email" name="email" type="email" value="{{ old('email') }}" required autofocus>
                    @error('email')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>
                <div class="mb-4">
                    <label class="form-label" for="password">Mot de passe</label>
                    <input class="form-control" id="password" name="password" type="password" required>
                </div>
                <button class="btn btn-success w-100">Se connecter</button>
            </form>
        </div>
    </div>
</div>
@endsection
