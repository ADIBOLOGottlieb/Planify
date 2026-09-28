<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\TransactionRequest;
use App\Models\Transaction;

/** Transactions (dépenses et revenus) de l'utilisateur. */
class TransactionController extends RessourceController
{
    protected string $modele = Transaction::class;

    protected string $requete = TransactionRequest::class;
}
