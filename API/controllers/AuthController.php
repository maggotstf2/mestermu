<?php
require_once __DIR__ . '/../models/User.php';
require_once __DIR__ . '/../utils/JWT.php';

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
}
