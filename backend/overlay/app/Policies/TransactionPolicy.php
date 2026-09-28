<?php

namespace App\Policies;

/** Accès aux éléments « Transaction » réservé à leur propriétaire. */
class TransactionPolicy extends ProprietairePolicy
{
}
