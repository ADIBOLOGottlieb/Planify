<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Auth\Events\Verified;
use Illuminate\Contracts\View\View;

/**
 * Lien reçu par email après l'inscription. Le lien est signé : il ne peut
 * pas être falsifié et expire après 60 minutes.
 */
class VerifyEmailController extends Controller
{
    public function __invoke(string $id, string $hash): View
    {
        $user = User::findOrFail($id);
        abort_unless(hash_equals(sha1($user->getEmailForVerification()), $hash), 403);

        if (! $user->hasVerifiedEmail()) {
            $user->markEmailAsVerified();
            event(new Verified($user));
        }

        return view('verification', ['prenom' => $user->prenom]);
    }
}
