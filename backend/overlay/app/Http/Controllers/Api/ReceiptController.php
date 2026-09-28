<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Téléversement des photos de reçus (justificatifs). Les fichiers sont
 * stockés sous un nom aléatoire de 40 caractères, dans un dossier propre à
 * l'utilisateur (disque « public », voir `php artisan storage:link`).
 */
class ReceiptController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'file' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $chemin = $request->file('file')->storeAs(
            'receipts/'.$request->user()->id,
            Str::random(40).'.'.$request->file('file')->extension(),
            'public',
        );

        return response()->json(['url' => Storage::disk('public')->url($chemin)], 201);
    }
}
