<?php
require_once __DIR__ . '/../models/User.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';

class AdminController {
    private $userModel;

    public function __construct() {
        $this->userModel = new User();
    }

    // Összes felhasználó lekérése (csak admin)
    public function getAllUsers() {
        header('Content-Type: application/json');
        
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        // Admin hozzáférés ellenőrzése
        AuthMiddleware::requireAdmin();

        $users = $this->userModel->getAllUsers();
        
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'users' => $users,
            'count' => count($users)
        ]);
    }

    // Felhasználó lekérése ID alapján (csak admin)
    public function getUserById($userId) {
        header('Content-Type: application/json');
        
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        // Admin hozzáférés ellenőrzése
        AuthMiddleware::requireAdmin();

        $user = $this->userModel->getUserById($userId);

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

    // Felhasználó role frissítése (csak admin)
    public function updateUserRole($userId) {
        header('Content-Type: application/json');
        
        if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'PATCH') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        // Admin hozzáférés ellenőrzése
        AuthMiddleware::requireAdmin();

        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data) {
            $data = $_POST;
        }

        if (!isset($data['role'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Role is required']);
            return;
        }

        $result = $this->userModel->updateUserRole($userId, $data['role']);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Felhasználó törlése (csak admin)
    public function deleteUser($userId) {
        header('Content-Type: application/json');
        
        if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        // Admin hozzáférés ellenőrzése és jelenlegi felhasználó lekérése
        $payload = AuthMiddleware::requireAdmin();
        
        // Megakadályozza a saját fiók törlését
        if ($payload['user_id'] == $userId) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'You cannot delete your own account']);
            return;
        }

        $result = $this->userModel->deleteUser($userId);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Admin dashboard statisztikák lekérése
    public function dashboard() {
        header('Content-Type: application/json');
        
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        // Admin hozzáférés ellenőrzése
        AuthMiddleware::requireAdmin();

        $users = $this->userModel->getAllUsers();
        $totalUsers = count($users);
        $adminCount = count(array_filter($users, function($user) {
            return $user['role'] === 'admin';
        }));
        $userCount = $totalUsers - $adminCount;

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'stats' => [
                'total_users' => $totalUsers,
                'admin_count' => $adminCount,
                'user_count' => $userCount
            ],
            'users' => $users
        ]);
    }
}
