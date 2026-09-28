<?php

namespace Tests\Feature;

use Tests\TestCase;

class ExampleTest extends TestCase
{
    public function test_la_racine_redirige_vers_l_administration(): void
    {
        $this->get('/')->assertRedirect('/admin');
    }
}
