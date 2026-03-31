<?php
require_once __DIR__ . '/../models/Order.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';

class OrderController {
    private $orderModel;

    public function __construct() {
        $this->orderModel = new Order();
    }

    // Új rendelés létrehozása (auth)
    public function create() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();
        $username = $payload['username'];

        $result = $this->orderModel->createOrder($username);

        if ($result['success']) {
            http_response_code(201);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Saját rendelések listája (auth)
    public function list() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();
        $orders = $this->orderModel->getUserOrders($payload['username']);

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'orders' => $orders,
            'count' => count($orders)
        ]);
    }

    // Rendelés tételei (auth, csak saját)
    public function details($orderId) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();
        $result = $this->orderModel->getOrderDetails((int)$orderId, $payload['username']);

        if (!($result['success'] ?? false)) {
            http_response_code(404);
            echo json_encode($result);
            return;
        }

        http_response_code(200);
        echo json_encode($result);
    }

    // Tétel hozzáadása rendeléshez (auth, csak saját)
    public function addItem($orderId) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        if (!isset($data['product_id']) || !isset($data['quantity'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'product_id and quantity are required']);
            return;
        }

        $result = $this->orderModel->addOrderItem((int)$orderId, (int)$data['product_id'], (int)$data['quantity'], $payload['username']);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Tétel mennyiségének módosítása (auth, csak saját)
    public function updateItemQuantity($orderId, $productId) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'PATCH' && $_SERVER['REQUEST_METHOD'] !== 'PUT') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        if (!isset($data['quantity'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'quantity is required']);
            return;
        }

        $result = $this->orderModel->updateOrderItemQuantity((int)$orderId, (int)$productId, (int)$data['quantity'], $payload['username']);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Rendelés törlése (auth, csak saját)
    public function delete($orderId) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();
        $result = $this->orderModel->deleteOrder((int)$orderId, $payload['username']);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }
}

