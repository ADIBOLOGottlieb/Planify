<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<\App\Models\User>
 */
class UserFactory extends Factory
{
    public function definition(): array
    {
        return [
            'nom' => fake()->lastName(),
            'prenom' => fake()->firstName(),
            'email' => Str::lower(fake()->unique()->safeEmail()),
            'email_verified_at' => now(),
            'password' => 'MotDePasse1',
            'devise' => 'FCFA',
            'remember_token' => Str::random(10),
        ];
    }

    public function nonVerifie(): static
    {
        return $this->state(fn () => ['email_verified_at' => null]);
    }
}
