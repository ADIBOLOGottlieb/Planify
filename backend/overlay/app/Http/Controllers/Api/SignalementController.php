<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Problème signalé depuis l'application, consultable par l'administrateur. */
class SignalementController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'sujet' => ['required', 'string', 'max:150'],
            'message' => ['required', 'string', 'max:5000'],
        ]);

        $signalement = $request->user()->signalements()->create($data);

        return response()->json($signalement, 201);
    }
}
