<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require dirname(__DIR__) . '/config/app.php';
db()->exec('DELETE FROM rate_limits WHERE window_start < ' . (int) (time() / 60 - 1440));
