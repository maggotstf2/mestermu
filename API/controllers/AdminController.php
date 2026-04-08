<?php
require_once __DIR__ . '/../models/User.php';
require_once __DIR__ . '/../models/Product.php';
require_once __DIR__ . '/../models/Order.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/RateLimiter.php';

class AdminController {
    private $userModel;
    private $productModel;
    private $orderModel;

    public function __construct() {
        $this->userModel = new User();
        $this->productModel = new Product();
        $this->orderModel = new Order();
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
        $payload = AuthMiddleware::requireAdmin();

        RateLimiter::throttleOrFail(
            'admin-user-role',
            (string)$payload['user_id'],
            30,   // max 30 role módosítás / óra / admin
            3600
        );

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

        RateLimiter::throttleOrFail(
            'admin-delete-user',
            (string)$payload['user_id'],
            20,   // max 20 törlés / óra / admin
            3600
        );
        
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

        $productStats = [
            'total_products' => $this->productModel->countProducts([]),
        ];
        $orders=$this->orderModel->getAllOrders();
        $totalOrders=count($orders);

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'stats' => [
                'total_users' => $totalUsers,
                'admin_count' => $adminCount,
                'user_count' => $userCount,
                'total_products' => $productStats['total_products'],
                'total_orders' => $totalOrders
            ],
            'users' => $users
        ]);
    }

    // Összes rendelés lekérése (csak admin)
    public function getAllOrders() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        AuthMiddleware::requireAdmin();

        $orders = $this->orderModel->getAllOrders();

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'orders' => $orders,
            'count' => count($orders)
        ]);
    }

    public function getAllOrdersSummary() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        AuthMiddleware::requireAdmin();

        $rows = $this->orderModel->getAllOrdersSummary();

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'orders' => $rows,
            'count' => count($rows)
        ]);
    }

    // Rendelés státusz opciók (admin): DB-ben szereplő státuszok
    public function getOrderStatusOptions() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        AuthMiddleware::requireAdmin();

        $options = $this->orderModel->getOrderStatusOptions();

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'items' => $options,
            'count' => count($options),
        ]);
    }

    public function updateOrderStatus($orderId) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'PATCH' && $_SERVER['REQUEST_METHOD'] !== 'PUT') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::requireAdmin();

        RateLimiter::throttleOrFail(
            'admin-order-status',
            (string)$payload['user_id'],
            300,
            3600
        );

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        if (!isset($data['status'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Status is required']);
            return;
        }

        // $normalized = strtolower(trim((string)$data['status']));
        // $status = $normalized === 'delivered' ? 'Delivered' : ($normalized === 'processing' ? 'Processing' : null);
        // if ($status === null) {
        //     http_response_code(400);
        //     echo json_encode(['success' => false, 'message' => 'Invalid status']);
        //     return;
        // }
        $status=trim((string)$data['status']);

        $result = $this->orderModel->updateOrderStatus((int)$orderId, $status);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
            return;
        }

        if (($result['message'] ?? '') === 'Order not found') {
            http_response_code(404);
            echo json_encode($result);
            return;
        }

        http_response_code(400);
        echo json_encode($result);
    }

    // ---- TERMÉK ADMIN FUNKCIÓK ----

    // Új termék létrehozása
    public function createProduct() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::requireAdmin();

        RateLimiter::throttleOrFail(
            'admin-product-create',
            (string)$payload['user_id'],
            60,   // max 60 termék létrehozás / óra / admin
            3600
        );

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        $result = $this->productModel->createProduct($data);

        if ($result['success']) {
            http_response_code(201);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Termék frissítése
    public function updateProduct($id) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'PATCH') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::requireAdmin();

        RateLimiter::throttleOrFail(
            'admin-product-update',
            (string)$payload['user_id'],
            120,   // max 120 módosítás / óra / admin
            3600
        );

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        $result = $this->productModel->updateProduct((int)$id, $data);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Termék törlése
    public function deleteProduct($id) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::requireAdmin();

        RateLimiter::throttleOrFail(
            'admin-product-delete',
            (string)$payload['user_id'],
            60,   // max 60 törlés / óra / admin
            3600
        );

        $result = $this->productModel->deleteProduct((int)$id);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Készlet státusz: kifogyott
    public function setProductOutOfStock($id) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'PATCH') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::requireAdmin();

        RateLimiter::throttleOrFail(
            'admin-product-stock',
            (string)$payload['user_id'],
            300,   // max 300 stock művelet / óra / admin
            3600
        );

        $result = $this->productModel->setInStock((int)$id, false);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Készlet státusz: újra készleten
    public function setProductInStock($id) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'PATCH') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::requireAdmin();

        RateLimiter::throttleOrFail(
            'admin-product-stock',
            (string)$payload['user_id'],
            300,   // max 300 stock művelet / óra / admin
            3600
        );

        $result = $this->productModel->setInStock((int)$id, true);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Készlet mennyiség módosítása
    public function updateProductQuantity($id) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'PATCH') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::requireAdmin();

        RateLimiter::throttleOrFail(
            'admin-product-quantity',
            (string)$payload['user_id'],
            300,   // max 300 quantity módosítás / óra / admin
            3600
        );

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        if (!isset($data['quantity'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Quantity is required']);
            return;
        }

        $result = $this->productModel->updateQuantity((int)$id, (int)$data['quantity']);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Készlet mennyiség növelése (addToProductQuantity)
    public function addProductQuantity($id) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'PATCH') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::requireAdmin();

        RateLimiter::throttleOrFail(
            'admin-product-quantity-add',
            (string)$payload['user_id'],
            300,   // max 300 "add quantity" / óra / admin
            3600
        );

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        if (!isset($data['quantity'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'quantity is required']);
            return;
        }

        $result = $this->productModel->addToQuantity((int)$id, (int)$data['quantity']);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }
}
