<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

/**
 * Tâches planifiées. Sur le serveur, une seule entrée cron suffit :
 *   * * * * * cd /var/www/planify-api && php artisan schedule:run >> /dev/null 2>&1
 */
class Kernel extends ConsoleKernel
{
    protected function schedule(Schedule $schedule): void
    {
        $fuseau = 'Africa/Lome';

        $schedule->command('planify:rapports-hebdomadaires')->weeklyOn(1, '08:00')->timezone($fuseau);
        $schedule->command('planify:relancer-inactifs')->dailyAt('19:00')->timezone($fuseau);
        $schedule->command('planify:nettoyer')->dailyAt('03:00')->timezone($fuseau);
        $schedule->command('sanctum:prune-expired --hours=24')->daily();
    }

    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
