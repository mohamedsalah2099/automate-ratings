<?php
declare(strict_types=1);

// Simple PHP script to send a push notification via FCM HTTP v1 legacy API (server key).
// Expects JSON body: { "token": "DEVICE_OR_TOPIC", "title": "...", "body": "...", "data": { ... }, "isTopic": false }

header('Content-Type: application/json');

function respond(int $status, array $payload): void {
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

// Load env
$dotenvPath = __DIR__ . '/.env';
if (!file_exists($dotenvPath)) {
    respond(500, [ 'error' => 'Missing .env with FCM_SERVER_KEY' ]);
}

$env = parse_ini_file($dotenvPath, false, INI_SCANNER_RAW) ?: [];
$serverKey = $env['FCM_SERVER_KEY'] ?? getenv('FCM_SERVER_KEY');
$projectSenderId = $env['FCM_SENDER_ID'] ?? getenv('FCM_SENDER_ID');

if (!$serverKey) {
    respond(500, [ 'error' => 'FCM_SERVER_KEY not configured' ]);
}

// Read input
$raw = file_get_contents('php://input');
if ($raw === false || $raw === '') {
    respond(400, [ 'error' => 'Empty request body' ]);
}

$json = json_decode($raw, true);
if (!is_array($json)) {
    respond(400, [ 'error' => 'Invalid JSON' ]);
}

$target = $json['token'] ?? $json['to'] ?? null;
$title = $json['title'] ?? '';
$body = $json['body'] ?? '';
$data = $json['data'] ?? [];
$isTopic = (bool)($json['isTopic'] ?? false);

if (!$target) {
    respond(400, [ 'error' => 'token (device token) or to is required' ]);
}

// Compose payload
$payload = [
    'priority' => 'high',
    'data' => $data,
    'notification' => [
        'title' => $title,
        'body' => $body,
    ],
];

if ($isTopic) {
    // Expect target to be a bare topic name without "/topics/" prefix
    $payload['to'] = '/topics/' . ltrim((string)$target, '/');
} else {
    $payload['to'] = (string)$target;
}

// Send via cURL
$ch = curl_init('https://fcm.googleapis.com/fcm/send');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: key=' . $serverKey,
]);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 15);

$response = curl_exec($ch);
$errno = curl_errno($ch);
$error = curl_error($ch);
$statusCode = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($errno !== 0) {
    respond(502, [ 'error' => 'cURL error', 'details' => $error ]);
}

$decoded = json_decode((string)$response, true);

respond($statusCode >= 200 && $statusCode < 300 ? 200 : $statusCode, [
    'status' => $statusCode,
    'request' => $payload,
    'response' => $decoded ?? $response,
]);

