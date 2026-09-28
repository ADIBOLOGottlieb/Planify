<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\ObjectifRequest;
use App\Models\Objectif;

/** Objectifs d'épargne de l'utilisateur. */
class ObjectifController extends RessourceController
{
    protected string $modele = Objectif::class;

    protected string $requete = ObjectifRequest::class;
}
