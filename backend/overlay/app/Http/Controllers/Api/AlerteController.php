<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\AlerteRequest;
use App\Models\Alerte;

/** Historique des notifications de l'utilisateur. */
class AlerteController extends RessourceController
{
    protected string $modele = Alerte::class;

    protected string $requete = AlerteRequest::class;
}
