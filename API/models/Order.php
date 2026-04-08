<?php
require_once __DIR__ . '/../database/Database.php';

class Order {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getOrderStatusOptions(): array {
        $default = 'Feldolgozás alatt';
        try {
            $stmt = $this->db->prepare("SELECT DISTINCT status FROM orders ORDER BY status ASC");
            $stmt->execute();
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
            $options = [];
            foreach ($rows as $r) {
                $v = trim((string)($r['status'] ?? ''));
                if ($v !== '') {
                    $options[] = $v;
                }
            }
            if (!in_array($default, $options, true)) {
                array_unshift($options, $default);
            }
            return $options;
        } catch (PDOException $e) {
            return [$default];
        }
    }

    public function getAllOrdersSummary(): array {
        try {
            $stmt = $this->db->prepare(
                "SELECT
                    o.id,
                    o.order_date,
                    o.sum,
                    o.status,
                    o.user_id,
                    u.username,
                    u.first_name,
                    u.last_name,
                    COALESCE(SUM(oi.quantity), 0) AS items_quantity,
                    COUNT(oi.id) AS items_lines
                 FROM orders o
                 JOIN user u ON u.id = o.user_id
                 LEFT JOIN order_items oi ON oi.orders_id = o.id
                 GROUP BY o.id, o.order_date, o.sum, o.status, o.user_id, u.username, u.first_name, u.last_name
                 ORDER BY o.id ASC"
            );
            $stmt->execute();
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $stmt->closeCursor();
            return $rows ?: [];
        } catch (PDOException $e) {
            return [];
        }
    }

    public function createOrder(string $username): array {
        try {
            $stmt = $this->db->prepare("CALL createOrder(:username)");
            $stmt->execute([':username' => $username]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();

            $newId = $row ? (int)($row['new_order_id'] ?? 0) : 0;
            if ($newId <= 0) {
                return ['success' => false, 'message' => 'Failed to create order'];
            }

            return ['success' => true, 'message' => 'Order created successfully', 'order_id' => $newId];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function getUserOrders(string $username): array {
        try {
            $stmt = $this->db->prepare("CALL getUserOrders(:username)");
            $stmt->execute([':username' => $username]);
            $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $stmt->closeCursor();

            return $orders ?: [];
        } catch (PDOException $e) {
            return [];
        }
    }

    public function getAllOrders(): array {
        try {
            $stmt = $this->db->prepare("CALL getAllOrders()");
            $stmt->execute();
            $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $stmt->closeCursor();

            return $orders ?: [];
        } catch (PDOException $e) {
            return [];
        }
    }

    public function updateOrderStatus(int $orderId, string $status): array {
        $status = trim($status);
        $allowed = $this->getOrderStatusOptions();
        if ($status === '' || !in_array($status, $allowed, true)) {
            return ['success' => false, 'message' => 'Invalid status'];
        }

        try {
            $stmt = $this->db->prepare("UPDATE orders SET status = :status WHERE id = :id");
            $stmt->execute([
                ':status' => $status,
                ':id' => $orderId
            ]);

            if ($stmt->rowCount() === 0) {
                $existsStmt = $this->db->prepare("SELECT 1 FROM orders WHERE id = :id LIMIT 1");
                $existsStmt->execute([':id' => $orderId]);
                if (!$existsStmt->fetchColumn()) {
                    return ['success' => false, 'message' => 'Order not found'];
                }
            }

            return ['success' => true, 'message' => 'Order status updated successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function getOrderDetails(int $orderId, string $username): array {
        if (!$this->userOwnsOrder($orderId, $username)) {
            return ['success' => false, 'message' => 'Order not found'];
        }

        try {
            $stmt = $this->db->prepare("CALL getOrderDetails(:order_id)");
            $stmt->execute([':order_id' => $orderId]);
            $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $stmt->closeCursor();

            return ['success' => true, 'items' => $items ?: []];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function addOrderItem(int $orderId, int $productId, int $quantity, string $username): array {
        if (!$this->userOwnsOrder($orderId, $username)) {
            return ['success' => false, 'message' => 'Order not found'];
        }

        if ($quantity <= 0) {
            return ['success' => false, 'message' => 'Quantity must be > 0'];
        }

        try {
            $stmt = $this->db->prepare("CALL addOrderItem(:order_id, :product_id, :quantity)");
            $stmt->execute([
                ':order_id' => $orderId,
                ':product_id' => $productId,
                ':quantity' => $quantity
            ]);
            $stmt->closeCursor();

            return ['success' => true, 'message' => 'Order item added successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function updateOrderItemQuantity(int $orderId, int $productId, int $newQuantity, string $username): array {
        if (!$this->userOwnsOrder($orderId, $username)) {
            return ['success' => false, 'message' => 'Order not found'];
        }

        if ($newQuantity <= 0) {
            return ['success' => false, 'message' => 'Quantity must be > 0'];
        }

        try {
            $stmt = $this->db->prepare("CALL updateOrderItemQuantity(:order_id, :product_id, :new_quantity)");
            $stmt->execute([
                ':order_id' => $orderId,
                ':product_id' => $productId,
                ':new_quantity' => $newQuantity
            ]);
            $stmt->closeCursor();

            return ['success' => true, 'message' => 'Order item updated successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function deleteOrder(int $orderId, string $username): array {
        if (!$this->userOwnsOrder($orderId, $username)) {
            return ['success' => false, 'message' => 'Order not found'];
        }

        try {
            $stmt = $this->db->prepare("CALL deleteOrder(:order_id)");
            $stmt->execute([':order_id' => $orderId]);
            $stmt->closeCursor();

            return ['success' => true, 'message' => 'Order deleted successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    private function userOwnsOrder(int $orderId, string $username): bool {
        $stmt = $this->db->prepare(
            "SELECT 1
             FROM orders o
             JOIN user u ON o.user_id = u.id
             WHERE o.id = :order_id AND u.username = :username
             LIMIT 1"
        );
        $stmt->execute([
            ':order_id' => $orderId,
            ':username' => $username
        ]);

        return (bool)$stmt->fetchColumn();
    }
}

