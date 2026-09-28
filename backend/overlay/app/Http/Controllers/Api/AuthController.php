<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Notifications\CodeReinitialisation;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

/**
 * Authentification de l'application mobile (Laravel Sanctum).
 * Chaque connexion délivre un jeton Bearer valable 24 heures.
 */
class AuthController extends Controller
{
    /** Tentatives de connexion échouées tolérées avant blocage. */
    public const MAX_TENTATIVES = 5;

    /** Durée du blocage, en secondes (15 minutes). */
    public const DUREE_BLOCAGE = 15 * 60;

    private function regleMotDePasse(): Password
    {
        return Password::min(8)->mixedCase()->numbers();
    }

    private function jeton(User $user, ?string $appareil = null): string
    {
        return $user->createToken($appareil ?: 'mobile', ['*'], now()->addDay())->plainTextToken;
    }

    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id' => ['sometimes', 'uuid', 'unique:users,id'],
            'nom' => ['required', 'string', 'max:50'],
            'prenom' => ['required', 'string', 'max:50'],
            'email' => ['required', 'email', 'max:100', 'unique:users,email'],
            'password' => ['required', 'confirmed', $this->regleMotDePasse()],
            'devise' => ['sometimes', 'string', 'max:10'],
        ], [
            'email.unique' => 'Cet email est déjà utilisé.',
        ]);

        $data['email'] = Str::lower($data['email']);
        $user = User::create($data);
        event(new Registered($user)); // envoie l'email de vérification

        return response()->json([
            'token' => $this->jeton($user),
            'user' => $user->versApi(),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['sometimes', 'string', 'max:100'],
        ]);

        $cle = 'login|'.Str::lower($data['email']).'|'.$request->ip();
        if (RateLimiter::tooManyAttempts($cle, self::MAX_TENTATIVES)) {
            $minutes = (int) ceil(RateLimiter::availableIn($cle) / 60);

            return response()->json([
                'message' => "Trop de tentatives échouées. Compte bloqué pendant encore {$minutes} min.",
            ], 429);
        }

        $user = User::where('email', Str::lower($data['email']))->first();
        if (! $user || ! Hash::check($data['password'], $user->password)) {
            RateLimiter::hit($cle, self::DUREE_BLOCAGE);

            return response()->json(['message' => 'Email ou mot de passe incorrect.'], 401);
        }
        if ($user->statut !== 'actif') {
            return response()->json(['message' => 'Ce compte est désactivé.'], 403);
        }

        RateLimiter::clear($cle);

        return response()->json([
            'token' => $this->jeton($user, $data['device_name'] ?? null),
            'user' => $user->versApi(),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Déconnecté.']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json($request->user()->versApi());
    }

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'nom' => ['sometimes', 'string', 'max:50'],
            'prenom' => ['sometimes', 'string', 'max:50'],
            'devise' => ['sometimes', 'string', 'max:10'],
        ]);
        $request->user()->update($data);

        return response()->json($request->user()->versApi());
    }

    public function changePassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'ancien_mot_de_passe' => ['required', 'current_password:sanctum'],
            'password' => ['required', 'confirmed', $this->regleMotDePasse()],
        ], [
            'ancien_mot_de_passe.current_password' => 'Ancien mot de passe incorrect.',
        ]);

        $user = $request->user();
        $user->update(['password' => $data['password']]);
        // Les autres appareils devront se reconnecter.
        $user->tokens()->where('id', '!=', $user->currentAccessToken()->id)->delete();

        return response()->json(['message' => 'Mot de passe modifié.']);
    }

    public function destroy(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->tokens()->delete();
        $user->delete(); // les données liées sont supprimées en cascade

        return response()->json(['message' => 'Compte supprimé.']);
    }

    public function resendVerification(Request $request): JsonResponse
    {
        if ($request->user()->hasVerifiedEmail()) {
            return response()->json(['message' => 'Email déjà vérifié.']);
        }
        $request->user()->sendEmailVerificationNotification();

        return response()->json(['message' => 'Email de vérification envoyé.']);
    }

    public function deviceToken(Request $request): JsonResponse
    {
        $data = $request->validate(['token_fcm' => ['required', 'string', 'max:4096']]);
        $request->user()->forceFill(['token_fcm' => $data['token_fcm']])->save();

        return response()->json(['message' => 'Appareil enregistré.']);
    }

    /**
     * Envoie un code à 6 chiffres par email. La réponse est identique que le
     * compte existe ou non, pour ne pas révéler les adresses inscrites.
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);
        $email = Str::lower($data['email']);
        $user = User::where('email', $email)->first();

        if ($user) {
            $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
            DB::table('password_reset_codes')->updateOrInsert(
                ['email' => $email],
                ['code_hash' => Hash::make($code), 'tentatives' => 0, 'expires_at' => now()->addMinutes(15)],
            );
            $user->notify(new CodeReinitialisation($code));
        }

        return response()->json([
            'message' => 'Si un compte existe pour cet email, un code vient d\'être envoyé.',
        ]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['required', 'digits:6'],
            'password' => ['required', 'confirmed', $this->regleMotDePasse()],
        ]);
        $email = Str::lower($data['email']);
        $ligne = DB::table('password_reset_codes')->where('email', $email)->first();
        $invalide = response()->json(['message' => 'Code invalide ou expiré.'], 422);

        if (! $ligne || now()->greaterThan($ligne->expires_at) || $ligne->tentatives >= self::MAX_TENTATIVES) {
            return $invalide;
        }
        if (! Hash::check($data['code'], $ligne->code_hash)) {
            DB::table('password_reset_codes')->where('email', $email)->increment('tentatives');

            return $invalide;
        }

        $user = User::where('email', $email)->firstOrFail();
        $user->update(['password' => $data['password']]);
        $user->tokens()->delete();
        DB::table('password_reset_codes')->where('email', $email)->delete();

        return response()->json(['message' => 'Mot de passe réinitialisé.']);
    }
}
