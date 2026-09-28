<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tables métier de Planify (MLD). Les identifiants sont des chaînes
 * générées par le client (UUID, ou « cat_… » pour les catégories système)
 * afin de permettre la saisie hors ligne puis la synchronisation.
 * Les dates ont une précision à la milliseconde : `updated_at` sert à
 * résoudre les conflits de synchronisation (la version la plus récente gagne).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->string('nom', 50);
            $table->string('icone', 50);
            $table->string('couleur', 7);
            $table->enum('type', ['depense', 'revenu']);
            $table->boolean('est_systeme')->default(false);
            $table->boolean('est_archivee')->default(false);
            $table->foreignUuid('utilisateur_id')->nullable()->constrained('users')->cascadeOnDelete();
            $table->dateTime('updated_at', 3)->nullable();
        });

        Schema::create('comptes', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->string('nom', 50);
            $table->decimal('solde', 15, 2)->default(0);
            $table->string('icone', 50);
            $table->string('couleur', 7);
            $table->string('operateur', 20)->nullable();
            $table->foreignUuid('utilisateur_id')->constrained('users')->cascadeOnDelete();
            $table->dateTime('updated_at', 3)->nullable();
        });

        Schema::create('transactions', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->decimal('montant', 15, 2);
            $table->enum('type', ['depense', 'revenu']);
            $table->dateTime('date_transaction', 3);
            $table->string('description', 500)->nullable();
            $table->string('mode_paiement', 30)->default('especes');
            $table->string('justificatif')->nullable();
            // Pas de clé étrangère stricte : une catégorie ou un compte
            // supprimé laisse l'historique intact (affiché « Autre »).
            $table->string('categorie_id', 64)->index();
            $table->string('compte_id', 64)->nullable()->index();
            $table->foreignUuid('utilisateur_id')->constrained('users')->cascadeOnDelete();
            $table->dateTime('date_creation', 3)->nullable();
            $table->dateTime('updated_at', 3)->nullable();
            $table->index(['utilisateur_id', 'date_transaction']);
        });

        Schema::create('budgets', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->decimal('montant_alloue', 15, 2);
            $table->decimal('montant_depense', 15, 2)->default(0);
            $table->decimal('montant_reporte', 15, 2)->default(0);
            $table->enum('periode', ['hebdomadaire', 'mensuel', 'annuel'])->default('mensuel');
            $table->dateTime('date_debut', 3);
            $table->dateTime('date_fin', 3);
            $table->string('categorie_id', 64)->nullable()->index();
            $table->foreignUuid('utilisateur_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedTinyInteger('seuil_alerte')->default(80);
            $table->boolean('statut_alerte')->default(false);
            $table->boolean('alerte_80_envoyee')->default(false);
            $table->boolean('alerte_100_envoyee')->default(false);
            $table->dateTime('updated_at', 3)->nullable();
        });

        Schema::create('alertes', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->string('type_alerte', 30);
            $table->text('message');
            $table->dateTime('date_envoi', 3);
            $table->boolean('est_lue')->default(false);
            $table->string('budget_id', 64)->nullable()->index();
            $table->foreignUuid('utilisateur_id')->constrained('users')->cascadeOnDelete();
            $table->dateTime('updated_at', 3)->nullable();
        });

        Schema::create('objectifs', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->string('nom', 100);
            $table->decimal('montant_cible', 15, 2);
            $table->decimal('montant_actuel', 15, 2)->default(0);
            $table->dateTime('date_echeance', 3);
            $table->enum('statut', ['en_cours', 'atteint', 'abandonne'])->default('en_cours');
            $table->foreignUuid('utilisateur_id')->constrained('users')->cascadeOnDelete();
            $table->dateTime('updated_at', 3)->nullable();
        });

        Schema::create('transactions_recurrentes', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->decimal('montant', 15, 2);
            $table->enum('type', ['depense', 'revenu']);
            $table->dateTime('date_debut', 3);
            $table->dateTime('prochaine_date', 3);
            $table->enum('periodicite', ['hebdomadaire', 'mensuel', 'annuel']);
            $table->string('description', 500)->nullable();
            $table->string('mode_paiement', 30)->default('especes');
            $table->string('categorie_id', 64)->index();
            $table->string('compte_id', 64)->nullable();
            $table->boolean('actif')->default(true);
            $table->foreignUuid('utilisateur_id')->constrained('users')->cascadeOnDelete();
            $table->dateTime('updated_at', 3)->nullable();
        });

        // Problèmes signalés depuis l'application (page « À propos »).
        Schema::create('signalements', function (Blueprint $table) {
            $table->id();
            $table->foreignUuid('utilisateur_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('sujet', 150);
            $table->text('message');
            $table->boolean('est_traite')->default(false);
            $table->timestamps();
        });

        // Codes à 6 chiffres envoyés par email pour « mot de passe oublié ».
        Schema::create('password_reset_codes', function (Blueprint $table) {
            $table->string('email', 100)->primary();
            $table->string('code_hash');
            $table->unsignedTinyInteger('tentatives')->default(0);
            $table->timestamp('expires_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('password_reset_codes');
        Schema::dropIfExists('signalements');
        Schema::dropIfExists('transactions_recurrentes');
        Schema::dropIfExists('objectifs');
        Schema::dropIfExists('alertes');
        Schema::dropIfExists('budgets');
        Schema::dropIfExists('transactions');
        Schema::dropIfExists('comptes');
        Schema::dropIfExists('categories');
    }
};
