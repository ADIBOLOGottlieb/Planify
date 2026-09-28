<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;

/** Connexion à l'interface d'administration (session web). */
class ConnexionController extends Controller
{
    public function formulaire(): View
    {
        return view('admin.connexion');
    }

    public function connecter(Request $request): RedirectResponse
    {
        $identifiants = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);
        $identifiants['email'] = Str::lower($identifiants['email']);

        $cle = 'admin|'.$identifiants['email'].'|'.$request->ip();
        if (RateLimiter::tooManyAttempts($cle, 5)) {
            return back()->withErrors(['email' => 'Trop de tentatives. Réessayez dans 15 minutes.']);
        }

        if (! Auth::attempt($identifiants + ['is_admin' => true])) {
            RateLimiter::hit($cle, 15 * 60);

            return back()->withErrors(['email' => 'Identifiants incorrects.'])->onlyInput('email');
        }

        RateLimiter::clear($cle);
        $request->session()->regenerate();

        return redirect()->intended(route('admin.tableau'));
    }

    public function deconnecter(Request $request): RedirectResponse
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login');
    }
}
