<?php

namespace Tests\Feature;

use App\Models\Categorie;
use App\Models\Signalement;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    public function test_redirection_vers_la_connexion(): void
    {
        $this->get('/admin')->assertRedirect(route('login'));
    }

    public function test_utilisateur_non_admin_refuse(): void
    {
        $this->actingAs(User::factory()->create(['nom' => 'D', 'prenom' => 'A']))
            ->get('/admin')->assertForbidden();
    }

    public function test_connexion_admin_et_tableau_de_bord(): void
    {
        User::factory()->create(['nom' => 'A', 'prenom' => 'B', 'email' => 'admin@planify.tg', 'password' => 'Admin1234', 'is_admin' => true]);

        $this->post('/admin/connexion', ['email' => 'admin@planify.tg', 'password' => 'Admin1234'])
            ->assertRedirect(route('admin.tableau'));
        $this->get('/admin')->assertOk()->assertSee('Statistiques globales');
    }

    public function test_gestion_des_categories_systeme(): void
    {
        $admin = User::factory()->create(['nom' => 'A', 'prenom' => 'B', 'is_admin' => true]);

        $this->actingAs($admin)->post('/admin/categories', [
            'nom' => 'Cérémonies', 'icone' => 'celebration', 'couleur' => '#8E24AA', 'type' => 'depense',
        ])->assertRedirect(route('admin.categories.index'));

        $categorie = Categorie::where('nom', 'Cérémonies')->firstOrFail();
        $this->assertTrue((bool) $categorie->est_systeme);

        $this->actingAs($admin)->delete("/admin/categories/{$categorie->id}");
        $this->assertTrue((bool) $categorie->fresh()->est_archivee);
    }

    public function test_traitement_des_signalements(): void
    {
        $admin = User::factory()->create(['nom' => 'A', 'prenom' => 'B', 'is_admin' => true]);
        $signalement = Signalement::create(['sujet' => 'Bug', 'message' => 'Plantage']);

        $this->actingAs($admin)->get('/admin/signalements')->assertOk()->assertSee('Plantage');
        $this->actingAs($admin)->patch("/admin/signalements/{$signalement->id}");
        $this->assertTrue($signalement->fresh()->est_traite);
    }
}
