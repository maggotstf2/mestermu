<?php
require_once __DIR__ . '/../models/User.php';
require_once __DIR__ . '/../utils/JWT.php';
require_once __DIR__ . '/../utils/RateLimiter.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';

class AuthController {
    private $userModel;

    public function __construct() {
        $this->userModel = new User();
    }

    // Regisztrációs endpoint
    public function signup() {
        header('Content-Type: application/json');
        
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        RateLimiter::throttleOrFail(
            'signup',
            RateLimiter::getClientIp(),
            5,      // max 5 regisztráció / óra / IP
            3600
        );

        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data) {
            $data = $_POST;
        }

        $username = isset($data['username']) ? trim($data['username']) : '';
        $email = isset($data['email']) ? trim($data['email']) : '';
        $password = isset($data['password']) ? $data['password'] : '';
        $firstName = isset($data['first_name']) ? trim($data['first_name']) : '';
        $lastName = isset($data['last_name']) ? trim($data['last_name']) : '';

        $result = $this->userModel->createUser($username, $email, $password, $firstName, $lastName);

        if ($result['success']) {
            http_response_code(201);
            echo json_encode([
                'success' => true,
                'message' => $result['message'],
                'user_id' => $result['user_id']
            ]);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Bejelentkezési endpoint
    public function login() {
        header('Content-Type: application/json');
        
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        RateLimiter::throttleOrFail(
            'login',
            RateLimiter::getClientIp(),
            5,       // max 5 bejelentkezési kísérlet / 5 perc / IP
            300
        );

        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data) {
            $data = $_POST;
        }

        $username = isset($data['username']) ? trim($data['username']) : '';
        $password = isset($data['password']) ? $data['password'] : '';

        $result = $this->userModel->authenticate($username, $password);

        if ($result['success']) {
            // JWT token generálása
            $token = JWT::generateToken(
                $result['user']['id'],
                $result['user']['username'],
                $result['user']['role']
            );

            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => $result['message'],
                'token' => $token,
                'user' => $result['user']
            ]);
        } else {
            http_response_code(401);
            echo json_encode($result);
        }
    }

    // Jelenlegi felhasználó profiljának lekérése
    public function profile() {
        header('Content-Type: application/json');
        
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        require_once __DIR__ . '/../middleware/AuthMiddleware.php';
        $payload = AuthMiddleware::authenticate();

        $user = $this->userModel->getUserById($payload['user_id']);

        if ($user) {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'user' => $user
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found']);
        }
    }

    // Felhasználónév frissítése (auth)
    public function updateUsername() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'PATCH') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        $newUsername = $data['new_username'] ?? $data['newUsername'] ?? $data['username'] ?? '';
        $newUsername = is_string($newUsername) ? trim($newUsername) : '';

        if ($newUsername === '') {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'new_username is required']);
            return;
        }

        if (strlen($newUsername) > 32) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Username is too long']);
            return;
        }

        $result = $this->userModel->updateUsername(
            (int)$payload['user_id'],
            (string)$payload['username'],
            (string)$newUsername
        );

        if (!($result['success'] ?? false)) {
            http_response_code(400);
            echo json_encode($result);
            return;
        }

        // Frissítsük a JWT-et is, hogy a későbbi /orders /reservations hívások
        // már az új username-nel menjenek.
        $token = JWT::generateToken(
            (int)$payload['user_id'],
            (string)$newUsername,
            (string)$payload['role']
        );

        $user = $this->userModel->getUserById((int)$payload['user_id']);

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Username updated successfully',
            'token' => $token,
            'user' => $user
        ]);
    }

    // Jelszó frissítése (auth)
    public function updatePassword() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'PATCH') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        $newPassword = $data['new_password'] ?? $data['newPassword'] ?? '';
        $newPassword = is_string($newPassword) ? $newPassword : '';

        if ($newPassword === '') {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'new_password is required']);
            return;
        }

        $result = $this->userModel->updatePassword((string)$payload['username'], (string)$newPassword);

        if (!($result['success'] ?? false)) {
            http_response_code(400);
            echo json_encode($result);
            return;
        }

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Password updated successfully'
        ]);
    }
}
