<?php

namespace Database\Seeders;

use App\Models\Categorie;
use Illuminate\Database\Seeder;

/**
 * Catégories système par défaut. Les identifiants sont identiques à ceux
 * créés par l'application mobile (DatabaseHelper._insertDefaultCategories)
 * pour que la synchronisation les reconnaisse.
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['cat_logement', 'Logement', 'home', '#E53935', 'depense'],
            ['cat_alimentation', 'Alimentation', 'restaurant', '#FB8C00', 'depense'],
            ['cat_transport', 'Transport', 'directions_car', '#1E88E5', 'depense'],
            ['cat_sante', 'Santé', 'local_hospital', '#00897B', 'depense'],
            ['cat_education', 'Éducation', 'school', '#8E24AA', 'depense'],
            ['cat_loisirs', 'Loisirs', 'sports_esports', '#F4511E', 'depense'],
            ['cat_habillement', 'Habillement', 'checkroom', '#D81B60', 'depense'],
            ['cat_telecom', 'Télécom', 'phone_android', '#039BE5', 'depense'],
            ['cat_autre_dep', 'Autres', 'more_horiz', '#546E7A', 'depense'],
            ['cat_salaire', 'Salaire', 'work', '#43A047', 'revenu'],
            ['cat_commerce', 'Commerce', 'storefront', '#00ACC1', 'revenu'],
            ['cat_freelance', 'Freelance', 'laptop', '#7CB342', 'revenu'],
            ['cat_investissement', 'Investissement', 'trending_up', '#F9A825', 'revenu'],
            ['cat_autre_rev', 'Autres', 'attach_money', '#6D4C41', 'revenu'],
        ];

        foreach ($categories as [$id, $nom, $icone, $couleur, $type]) {
            $categorie = Categorie::firstOrNew(['id' => $id]);
            $categorie->id = $id;
            $categorie->fill(compact('nom', 'icone', 'couleur', 'type'));
            $categorie->est_systeme = true;
            $categorie->updated_at ??= now()->startOfYear();
            $categorie->save();
        }
    }
}
