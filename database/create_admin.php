<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require dirname(__DIR__) . '/config/app.php';

function ask(string $label): string
{
    fwrite(STDOUT, $label);
    return trim((string) fgets(STDIN));
}

$name = ask('Admin display name: ');
$email = strtolower(ask('Admin email: '));
$password = ask('Admin password (12+ characters): ');

if ($name === '' || unicode_length($name) > 255) {
    fwrite(STDERR, "Name is required and must be at most 255 characters.\n");
    exit(1);
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 255) {
    fwrite(STDERR, "Enter a valid email address.\n");
    exit(1);
}
if (strlen($password) < 12) {
    fwrite(STDERR, "Use a password with at least 12 characters.\n");
    exit(1);
}

$pdo = db();
$pdo->beginTransaction();

try {
    $existing = $pdo->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
    $existing->execute([$email]);
    if ($existing->fetchColumn()) {
        throw new RuntimeException('This email already has an account.');
    }

    $roleQuery = $pdo->prepare('SELECT id FROM roles WHERE name = ? AND guard_name = ? LIMIT 1');
    $roleQuery->execute(['admin', 'web']);
    $roleId = $roleQuery->fetchColumn();
    if (!$roleId) {
        throw new RuntimeException('Admin role is missing. Import database/schema.sql first.');
    }

    $insertUser = $pdo->prepare('INSERT INTO users (name, email, password, created_at, updated_at) VALUES (?, ?, ?, NOW(), NOW())');
    $insertUser->execute([$name, $email, password_hash($password, PASSWORD_DEFAULT)]);
    $userId = (int) $pdo->lastInsertId();

    $assignRole = $pdo->prepare('INSERT INTO model_has_roles (role_id, model_type, model_id) VALUES (?, ?, ?)');
    $assignRole->execute([(int) $roleId, 'App\\Models\\User', $userId]);
    $pdo->commit();

    fwrite(STDOUT, "Admin account created. You can now sign in at /admin/login.\n");
} catch (Throwable $error) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    fwrite(STDERR, $error->getMessage() . "\n");
    exit(1);
}
