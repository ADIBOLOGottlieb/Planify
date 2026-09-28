<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\RecurrenceRequest;
use App\Models\Recurrence;

/** Transactions récurrentes de l'utilisateur. */
class RecurrenceController extends RessourceController
{
    protected string $modele = Recurrence::class;

    protected string $requete = RecurrenceRequest::class;
}
