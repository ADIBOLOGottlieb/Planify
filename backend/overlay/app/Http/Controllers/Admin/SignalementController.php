<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Signalement;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;

/** Traitement des problèmes signalés depuis l'application. */
class SignalementController extends Controller
{
    public function index(): View
    {
        return view('admin.signalements', [
            'signalements' => Signalement::orderBy('est_traite')->latest()->paginate(20),
        ]);
    }

    public function basculer(Signalement $signalement): RedirectResponse
    {
        $signalement->update(['est_traite' => ! $signalement->est_traite]);

        return back()->with('succes', $signalement->est_traite ? 'Signalement traité.' : 'Signalement rouvert.');
    }
}
