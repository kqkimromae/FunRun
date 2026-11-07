<?php
declare(strict_types=1);

define('APP_ROOT', dirname(__DIR__));

function load_env(string $file): void
{
    if (!is_file($file)) return;
    foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) continue;
        [$key, $value] = explode('=', $line, 2);
        $key = trim($key);
        $value = trim(trim($value), "\"'");
        if ($key !== '' && getenv($key) === false) putenv($key . '=' . $value);
    }
}

load_env(APP_ROOT . '/.env');
date_default_timezone_set(getenv('APP_TIMEZONE') ?: 'Asia/Bangkok');

function env_value(string $key, string $default = ''): string
{
    $value = getenv($key);
    return $value === false ? $default : $value;
}

$publicPath = env_value('APP_PUBLIC_PATH');
$storagePath = env_value('APP_STORAGE_PATH');
define('PUBLIC_ROOT', rtrim($publicPath !== '' ? $publicPath : APP_ROOT . '/public', '/\\'));
define('STORAGE_ROOT', rtrim($storagePath !== '' ? $storagePath : APP_ROOT . '/storage', '/\\'));

function app_url(string $path = ''): string
{
    return rtrim(env_value('APP_URL'), '/') . '/' . ltrim($path, '/');
}

function public_image_url(?string $path): string
{
    if ($path === null || trim($path) === '') return '';
    if (str_starts_with($path, '/uploads/')) return $path;
    $parts = explode('/', ltrim($path, '/'));
    return '/storage/' . implode('/', array_map('rawurlencode', $parts));
}

function db(): PDO
{
    static $pdo;
    if ($pdo instanceof PDO) return $pdo;
    $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', env_value('DB_HOST', 'localhost'), env_value('DB_PORT', '3306'), env_value('DB_DATABASE', 'fun_pun'));
    $pdo = new PDO($dsn, env_value('DB_USERNAME'), env_value('DB_PASSWORD'), [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
    $pdo->exec("SET time_zone = '+07:00'");
    return $pdo;
}

function e(mixed $value): string
{
    return htmlspecialchars((string) ($value ?? ''), ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function unicode_length(string $value): int
{
    $count = preg_match_all('/./us', $value, $matches);
    return $count === false ? strlen($value) : $count;
}

function csv_safe(mixed $value): string
{
    $value = (string) ($value ?? '');
    return preg_match('/^[=+@\-]/u', $value) ? "'" . $value : $value;
}

function redirect(string $path): never
{
    header('Location: ' . app_url($path), true, 303);
    exit;
}

function csrf_token(): string
{
    return $_SESSION['_csrf'] ??= bin2hex(random_bytes(32));
}

function csrf_field(): string
{
    return '<input type="hidden" name="_csrf" value="' . e(csrf_token()) . '">';
}

function verify_csrf(): void
{
    $sent = $_POST['_csrf'] ?? '';
    if (!is_string($sent) || !hash_equals(csrf_token(), $sent)) {
        http_response_code(419);
        exit('เซสชันหมดอายุ กรุณากลับไปโหลดหน้าเว็บใหม่');
    }
}

function flash(string $key, mixed $value = null): mixed
{
    if (func_num_args() > 1) { $_SESSION['_flash'][$key] = $value; return null; }
    $value = $_SESSION['_flash'][$key] ?? null;
    unset($_SESSION['_flash'][$key]);
    return $value;
}

function setting(string $key, string $default = ''): string
{
    $stmt = db()->prepare('SELECT `value` FROM settings WHERE `key` = ? LIMIT 1');
    $stmt->execute([$key]);
    $value = $stmt->fetchColumn();
    return $value === false ? $default : (string) $value;
}

function age_group(int $age): string
{
    return match (true) {
        $age <= 18 => 'รุ่นอายุไม่เกิน 18 ปี',
        $age <= 29 => 'รุ่นอายุ 19-29 ปี',
        $age <= 39 => 'รุ่นอายุ 30-39 ปี',
        $age <= 49 => 'รุ่นอายุ 40-49 ปี',
        $age <= 59 => 'รุ่นอายุ 50-59 ปี',
        default => 'รุ่นอายุ 60 ปีขึ้นไป',
    };
}

function pickup_display(string $value): string
{
    return match ($value) {
        '29 ม.ค. (17:00-20:00)', '2027-01-29' => '29/01/2027 · รับล่วงหน้า 17:00–20:00 น.',
        '30 ม.ค. (09:00-15:00)', '2027-01-30' => '30/01/2027 · รับหน้างาน 09:00–15:00 น.',
        default => $value,
    };
}

function money_for(string $applicantType, string $distance, bool $noShirt): int
{
    $prices = [
        'general' => ['5km' => ['shirt' => 299, 'bib' => 200], '10km' => ['shirt' => 349, 'bib' => 250], 'vip' => ['shirt' => 1000, 'bib' => 1000]],
        'student' => ['5km' => ['shirt' => 289, 'bib' => 200], '10km' => ['shirt' => 339, 'bib' => 250], 'vip' => ['shirt' => 1000, 'bib' => 1000]],
    ];
    return $prices[$applicantType][$distance][$noShirt && $distance !== 'vip' ? 'bib' : 'shirt'] ?? 0;
}

function allocate_bib(PDO $pdo, int $eventId, string $distance, string $gender, string $group): string
{
    $ageCode = match ($group) {
        'รุ่นอายุไม่เกิน 18 ปี' => '18',
        'รุ่นอายุ 19-29 ปี' => '19',
        'รุ่นอายุ 30-39 ปี' => '30',
        'รุ่นอายุ 40-49 ปี' => '40',
        'รุ่นอายุ 50-59 ปี' => '50',
        'รุ่นอายุ 60 ปีขึ้นไป' => '60',
        default => throw new InvalidArgumentException('รุ่นอายุไม่ถูกต้อง'),
    };
    $category = $distance === 'vip' ? 'V' : ($gender === 'ชาย' ? 'M' : 'W') . $ageCode;
    $stmt = $pdo->prepare('INSERT INTO bib_counters (event_id, category, last_number, created_at, updated_at) VALUES (?, ?, 1, NOW(), NOW()) ON DUPLICATE KEY UPDATE last_number = last_number + 1, updated_at = NOW()');
    $stmt->execute([$eventId, $category]);
    $q = $pdo->prepare('SELECT last_number FROM bib_counters WHERE event_id = ? AND category = ? FOR UPDATE');
    $q->execute([$eventId, $category]);
    $number = (int) $q->fetchColumn();
    return $category . '-' . str_pad((string) $number, 3, '0', STR_PAD_LEFT);
}

function admin_required(): void
{
    if (empty($_SESSION['admin_email'])) redirect('admin/login');
}
