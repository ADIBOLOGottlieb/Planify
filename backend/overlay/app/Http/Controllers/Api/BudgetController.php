<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\BudgetRequest;
use App\Models\Budget;

/** Budgets de l'utilisateur. */
class BudgetController extends RessourceController
{
    protected string $modele = Budget::class;

    protected string $requete = BudgetRequest::class;
}
