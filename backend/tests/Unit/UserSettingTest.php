<?php

namespace Tests\Unit;

use App\Models\UserSetting;
use Tests\TestCase;

class UserSettingTest extends TestCase
{
    public function test_boolean_attributes_are_pgsql_safe_literals_on_pgsql_connection(): void
    {
        config([
            'database.connections.pgsql_boolean_test' => [
                'driver' => 'pgsql',
                'host' => '127.0.0.1',
                'database' => 'testing',
                'username' => 'testing',
                'password' => 'testing',
            ],
        ]);

        $settings = new UserSetting();
        $settings->setConnection('pgsql_boolean_test');
        $settings->notification_enabled = true;
        $settings->location_enabled = false;

        $this->assertSame('true', $settings->getAttributes()['notification_enabled']);
        $this->assertSame('false', $settings->getAttributes()['location_enabled']);
    }

    public function test_postgres_boolean_shorthand_values_are_read_correctly(): void
    {
        $settings = new UserSetting();
        $settings->setRawAttributes([
            'notification_enabled' => 't',
            'location_enabled' => 'f',
        ]);

        $this->assertTrue($settings->notification_enabled);
        $this->assertFalse($settings->location_enabled);
    }
}
