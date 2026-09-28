<?php

namespace Tests\Feature;

use App\Models\Categorie;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RessourcesApiTest extends TestCase
{
    use RefreshDatabase;

    private User $alice;

    private User $bob;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
        $this->alice = User::factory()->create(['nom' => 'Doe', 'prenom' => 'Alice']);
        $this->bob = User::factory()->create(['nom' => 'Doe', 'prenom' => 'Bob']);
    }

    private function transaction(array $surcharges = []): array
    {
        return array_merge([
            'id' => 'tx-1',
            'montant' => 2500,
            'type' => 'depense',
            'date_transaction' => '2026-04-13T10:00:00.000',
            'description' => 'Zémidjan',
            'mode_paiement' => 'mobile_money',
            'categorie_id' => 'cat_transport',
            'utilisateur_id' => 'ignore',
            'updated_at' => '2026-04-13T10:00:00.123',
        ], $surcharges);
    }

    public function test_creation_avec_identifiant_client_et_format_de_reponse(): void
    {
        Sanctum::actingAs($this->alice);

        $this->postJson('/api/transactions', $this->transaction())
            ->assertCreated()
            ->assertJsonPath('id', 'tx-1')
            ->assertJsonPath('montant', 2500.0)
            ->assertJsonPath('utilisateur_id', $this->alice->id)
            ->assertJsonPath('date_transaction', '2026-04-13T10:00:00.000')
            ->assertJsonPath('updated_at', '2026-04-13T10:00:00.123');
    }

    public function test_creation_rejouee_met_a_jour_sans_doublon(): void
    {
        Sanctum::actingAs($this->alice);
        $this->postJson('/api/transactions', $this->transaction())->assertCreated();
        $this->postJson('/api/transactions', $this->transaction(['montant' => 3000]))->assertOk();

        $this->assertSame(1, Transaction::count());
        $this->assertEquals(3000, Transaction::first()->montant);
    }

    public function test_montant_negatif_refuse(): void
    {
        Sanctum::actingAs($this->alice);
        $this->postJson('/api/transactions', $this->transaction(['montant' => -500]))
            ->assertStatus(422)
            ->assertJsonPath('errors.montant.0', 'Le montant doit être supérieur à zéro.');
    }

    public function test_un_utilisateur_ne_voit_pas_les_donnees_d_un_autre(): void
    {
        Sanctum::actingAs($this->alice);
        $this->postJson('/api/transactions', $this->transaction())->assertCreated();

        Sanctum::actingAs($this->bob);
        $this->getJson('/api/transactions')->assertOk()->assertJsonCount(0);
        $this->getJson('/api/transactions/tx-1')->assertForbidden();
        $this->putJson('/api/transactions/tx-1', $this->transaction(['montant' => 1]))->assertForbidden();
        $this->deleteJson('/api/transactions/tx-1')->assertForbidden();
        // Écraser l'élément d'un autre via un « upsert » est aussi refusé.
        $this->postJson('/api/transactions', $this->transaction(['montant' => 1]))->assertForbidden();

        $this->assertEquals(2500, Transaction::find('tx-1')->montant);
    }

    public function test_categorie_personnelle_d_un_autre_utilisateur_refusee(): void
    {
        Sanctum::actingAs($this->bob);
        $this->postJson('/api/categories', [
            'id' => 'cat-bob', 'nom' => 'Tontine', 'icone' => 'request_quote',
            'couleur' => '#1E88E5', 'type' => 'depense',
        ])->assertCreated();

        Sanctum::actingAs($this->alice);
        $this->postJson('/api/transactions', $this->transaction(['categorie_id' => 'cat-bob']))
            ->assertStatus(422)
            ->assertJsonPath('errors.categorie_id.0', 'Catégorie inconnue.');
    }

    public function test_categories_systeme_visibles_mais_non_modifiables(): void
    {
        Sanctum::actingAs($this->alice);
        $this->getJson('/api/categories')->assertOk()->assertJsonCount(Categorie::where('est_systeme', true)->count());

        $this->putJson('/api/categories/cat_transport', [
            'id' => 'cat_transport', 'nom' => 'Piraté', 'icone' => 'x', 'couleur' => '#000000', 'type' => 'depense',
        ])->assertForbidden();
        $this->deleteJson('/api/categories/cat_transport')->assertForbidden();
    }

    public function test_crud_complet_des_budgets(): void
    {
        Sanctum::actingAs($this->alice);
        $budget = [
            'id' => 'b-1', 'montant_alloue' => 50000, 'periode' => 'mensuel',
            'date_debut' => '2026-04-01T00:00:00.000', 'date_fin' => '2026-04-30T00:00:00.000',
            'categorie_id' => 'cat_alimentation', 'seuil_alerte' => 80,
        ];

        $this->postJson('/api/budgets', $budget)->assertCreated()->assertJsonPath('seuil_alerte', 80);
        $this->putJson('/api/budgets/b-1', array_merge($budget, ['montant_alloue' => 60000]))
            ->assertOk()->assertJsonPath('montant_alloue', 60000.0);
        $this->getJson('/api/budgets')->assertJsonCount(1);
        $this->deleteJson('/api/budgets/b-1')->assertNoContent();
        $this->getJson('/api/budgets')->assertJsonCount(0);
    }

    public function test_suppression_d_un_element_inexistant_renvoie_404(): void
    {
        Sanctum::actingAs($this->alice);
        $this->deleteJson('/api/objectifs/inexistant')->assertNotFound();
    }
}
