<?php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// preflight OPTIONS request kezelese
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/users/user.php';

$method = $_SERVER['REQUEST_METHOD'];
$path = $_SERVER['REQUEST_URI'] ?? '/';

// JSON bemenet
$input = json_decode(file_get_contents('php://input'), true);

$user = new User();

switch ($method) {
    case 'POST':
        // bejelentkezes vegpontja
        if (isset($input['action']) && $input['action'] === 'login') {
            $username = $input['username'] ?? '';
            $password = $input['password'] ?? '';
            
            $result = $user->login($username, $password);
            http_response_code($result['success'] ? 200 : 401);
            echo json_encode($result);
            exit();
        }
        
        // regisztracio vegpontja
        if (isset($input['action']) && $input['action'] === 'register') {
            $username = $input['username'] ?? '';
            $email = $input['email'] ?? '';
            $password = $input['password'] ?? '';
            $firstName = $input['first_name'] ?? '';
            $lastName = $input['last_name'] ?? '';
            
            $result = $user->createUser($username, $email, $password, $firstName, $lastName);
            http_response_code($result['success'] ? 201 : 400);
            echo json_encode($result);
            exit();
        }
        
        // token vegpont hitelesites
        if (isset($input['action']) && $input['action'] === 'validate') {
            $token = $input['token'] ?? '';
            
            // auth header
            $headers = getallheaders();
            if (empty($token) && isset($headers['Authorization'])) {
                $authHeader = $headers['Authorization'];
                if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
                    $token = $matches[1];
                }
            }
            
            $result = User::validateToken($token);
            http_response_code($result['success'] ? 200 : 401);
            echo json_encode($result);
            exit();
        }
        
        // amennyiben ervenytelen a muvelet
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Érvénytelen művelet']);
        break;
        
    case 'GET':
        // info vegpont csekkolas
        echo json_encode([
            'success' => true,
            'message' => 'Login/Registration API',
            'endpoints' => [
                'POST /index.php' => [
                    'action: login' => 'Bejelentkezés (username, password)',
                    'action: register' => 'Regisztráció (username, email, password, first_name, last_name)',
                    'action: validate' => 'Token validálás (token vagy Authorization header)'
                ]
            ]
        ]);
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Nem támogatott HTTP metódus']);
        break;
}

