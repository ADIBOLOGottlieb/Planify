<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\CodeReinitialisation;
use App\Notifications\VerificationEmail;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Str;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    private function inscrire(array $surcharges = []): \Illuminate\Testing\TestResponse
    {
        return $this->postJson('/api/register', array_merge([
            'id' => (string) Str::uuid(),
            'nom' => 'Doe',
            'prenom' => 'Alice',
            'email' => 'Alice@Example.com',
            'password' => 'MotDePasse1',
            'password_confirmation' => 'MotDePasse1',
            'devise' => 'FCFA',
        ], $surcharges));
    }

    public function test_inscription_renvoie_un_jeton_et_envoie_l_email_de_verification(): void
    {
        Notification::fake();
        $id = (string) Str::uuid();

        $this->inscrire(['id' => $id])
            ->assertCreated()
            ->assertJsonPath('user.id', $id)
            ->assertJsonPath('user.email', 'alice@example.com')
            ->assertJsonPath('user.email_verifie', false)
            ->assertJsonStructure(['token']);

        $user = User::find($id);
        $this->assertTrue(Hash::check('MotDePasse1', $user->password), 'mot de passe haché (bcrypt)');
        $this->assertNotSame('MotDePasse1', $user->password);
        Notification::assertSentTo($user, VerificationEmail::class);
    }

    public function test_email_deja_utilise_refuse(): void
    {
        $this->inscrire();
        $this->inscrire(['id' => (string) Str::uuid(), 'email' => 'alice@example.com'])
            ->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'Cet email est déjà utilisé.');
    }

    public function test_mot_de_passe_faible_refuse(): void
    {
        $this->inscrire(['password' => 'faible', 'password_confirmation' => 'faible'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('password');
    }

    public function test_connexion_et_jeton_expirant_apres_24_heures(): void
    {
        $this->inscrire();

        $reponse = $this->postJson('/api/login', ['email' => 'alice@example.com', 'password' => 'MotDePasse1'])
            ->assertOk();

        $jeton = $reponse->json('token');
        $this->getJson('/api/user', ['Authorization' => "Bearer $jeton"])
            ->assertOk()
            ->assertJsonPath('prenom', 'Alice');

        $expiration = User::first()->tokens()->latest('id')->first()->expires_at;
        $this->assertTrue($expiration->between(now()->addHours(23), now()->addHours(25)));
    }

    public function test_mauvais_mot_de_passe_refuse(): void
    {
        $this->inscrire();
        $this->postJson('/api/login', ['email' => 'alice@example.com', 'password' => 'Mauvais123'])
            ->assertStatus(401)
            ->assertJsonPath('message', 'Email ou mot de passe incorrect.');
    }

    public function test_blocage_apres_cinq_echecs(): void
    {
        $this->inscrire();
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/login', ['email' => 'alice@example.com', 'password' => 'Mauvais123'])->assertStatus(401);
        }

        $this->postJson('/api/login', ['email' => 'alice@example.com', 'password' => 'MotDePasse1'])
            ->assertStatus(429);
    }

    public function test_acces_refuse_sans_jeton(): void
    {
        $this->getJson('/api/transactions')->assertUnauthorized();
    }

    public function test_reinitialisation_par_code_email(): void
    {
        Notification::fake();
        $this->inscrire();
        $user = User::first();

        $this->postJson('/api/forgot-password', ['email' => 'alice@example.com'])->assertOk();

        $code = null;
        Notification::assertSentTo($user, CodeReinitialisation::class, function ($notification) use (&$code) {
            $code = (fn () => $this->code)->call($notification);

            return true;
        });

        $this->postJson('/api/reset-password', [
            'email' => 'alice@example.com', 'code' => '000000',
            'password' => 'Nouveau123', 'password_confirmation' => 'Nouveau123',
        ])->assertStatus(422);

        $this->postJson('/api/reset-password', [
            'email' => 'alice@example.com', 'code' => $code,
            'password' => 'Nouveau123', 'password_confirmation' => 'Nouveau123',
        ])->assertOk();

        $this->assertTrue(Hash::check('Nouveau123', $user->fresh()->password));
        $this->assertSame(0, $user->tokens()->count(), 'les sessions existantes sont révoquées');
    }

    public function test_mot_de_passe_oublie_ne_revele_pas_les_comptes(): void
    {
        Notification::fake();
        $this->postJson('/api/forgot-password', ['email' => 'inconnu@example.com'])
            ->assertOk()
            ->assertJsonPath('message', 'Si un compte existe pour cet email, un code vient d\'être envoyé.');
        Notification::assertNothingSent();
    }

    public function test_suppression_du_compte_efface_les_donnees(): void
    {
        $jeton = $this->inscrire()->json('token');
        $entetes = ['Authorization' => "Bearer $jeton"];
        $this->postJson('/api/transactions', [
            'id' => 't1', 'montant' => 2500, 'type' => 'depense',
            'date_transaction' => '2026-04-13T10:00:00.000', 'mode_paiement' => 'especes',
            'categorie_id' => 'cat_transport',
        ], $entetes)->assertCreated();

        $this->deleteJson('/api/user', [], $entetes)->assertOk();

        $this->assertDatabaseCount('users', 0);
        $this->assertDatabaseCount('transactions', 0);
    }

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }
}
