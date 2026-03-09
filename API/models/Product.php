<?php
require_once __DIR__ . '/../database/Database.php';

class Product {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getProducts(array $filters = []): array {
        $sql = "SELECT id, name, brand, cat, subcat, tag1, tag2, price, quantity, in_stock, description, is_bundled FROM product WHERE 1=1";
        $params = [];

        if (isset($filters['in_stock_only']) && $filters['in_stock_only']) {
            $sql .= " AND in_stock = 1";
        }

        if (!empty($filters['cat'])) {
            $sql .= " AND cat = :cat";
            $params[':cat'] = $filters['cat'];
        }

        if (!empty($filters['subcat'])) {
            $sql .= " AND subcat = :subcat";
            $params[':subcat'] = $filters['subcat'];
        }

        if (!empty($filters['brand'])) {
            $sql .= " AND brand = :brand";
            $params[':brand'] = $filters['brand'];
        }

        if (!empty($filters['tag'])) {
            $sql .= " AND (tag1 = :tag OR tag2 = :tag)";
            $params[':tag'] = $filters['tag'];
        }

        if (!empty($filters['search'])) {
            $sql .= " AND (name LIKE :search OR description LIKE :search)";
            $params[':search'] = '%' . $filters['search'] . '%';
        }

        if (isset($filters['min_price']) && $filters['min_price'] !== '') {
            $sql .= " AND price >= :min_price";
            $params[':min_price'] = (int)$filters['min_price'];
        }

        if (isset($filters['max_price']) && $filters['max_price'] !== '') {
            $sql .= " AND price <= :max_price";
            $params[':max_price'] = (int)$filters['max_price'];
        }

        $sql .= " ORDER BY cat, subcat, brand, name";

        // Egyszerű lapozás
        $page = isset($filters['page']) ? max(1, (int)$filters['page']) : 1;
        $limit = isset($filters['limit']) ? max(1, min(100, (int)$filters['limit'])) : 50;
        $offset = ($page - 1) * $limit;
        $sql .= " LIMIT :limit OFFSET :offset";

        $stmt = $this->db->prepare($sql);

        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);

        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function countProducts(array $filters = []): int {
        $sql = "SELECT COUNT(*) AS total FROM product WHERE 1=1";
        $params = [];

        if (isset($filters['in_stock_only']) && $filters['in_stock_only']) {
            $sql .= " AND in_stock = 1";
        }

        if (!empty($filters['cat'])) {
            $sql .= " AND cat = :cat";
            $params[':cat'] = $filters['cat'];
        }

        if (!empty($filters['subcat'])) {
            $sql .= " AND subcat = :subcat";
            $params[':subcat'] = $filters['subcat'];
        }

        if (!empty($filters['brand'])) {
            $sql .= " AND brand = :brand";
            $params[':brand'] = $filters['brand'];
        }

        if (!empty($filters['tag'])) {
            $sql .= " AND (tag1 = :tag OR tag2 = :tag)";
            $params[':tag'] = $filters['tag'];
        }

        if (!empty($filters['search'])) {
            $sql .= " AND (name LIKE :search OR description LIKE :search)";
            $params[':search'] = '%' . $filters['search'] . '%';
        }

        if (isset($filters['min_price']) && $filters['min_price'] !== '') {
            $sql .= " AND price >= :min_price";
            $params[':min_price'] = (int)$filters['min_price'];
        }

        if (isset($filters['max_price']) && $filters['max_price'] !== '') {
            $sql .= " AND price <= :max_price";
            $params[':max_price'] = (int)$filters['max_price'];
        }

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch();

        return $row ? (int)$row['total'] : 0;
    }

    public function getProductById(int $id): ?array {
        $stmt = $this->db->prepare("SELECT id, name, brand, cat, subcat, tag1, tag2, price, quantity, in_stock, description, is_bundled FROM product WHERE id = :id");
        $stmt->execute([':id' => $id]);
        $product = $stmt->fetch();
        return $product ?: null;
    }

    public function createProduct(array $data): array {
        $required = ['name', 'brand', 'cat', 'subcat', 'tag1', 'tag2', 'price', 'quantity', 'description'];
        foreach ($required as $field) {
            if (!isset($data[$field]) || $data[$field] === '') {
                return ['success' => false, 'message' => "Field '{$field}' is required"];
            }
        }

        $sql = "INSERT INTO product (name, brand, cat, subcat, tag1, tag2, price, quantity, in_stock, description, is_bundled)
                VALUES (:name, :brand, :cat, :subcat, :tag1, :tag2, :price, :quantity, :in_stock, :description, :is_bundled)";

        $stmt = $this->db->prepare($sql);

        $inStock = isset($data['in_stock']) ? (int)(bool)$data['in_stock'] : 1;
        $isBundled = isset($data['is_bundled']) ? (int)(bool)$data['is_bundled'] : 0;

        $ok = $stmt->execute([
            ':name' => $data['name'],
            ':brand' => $data['brand'],
            ':cat' => $data['cat'],
            ':subcat' => $data['subcat'],
            ':tag1' => $data['tag1'],
            ':tag2' => $data['tag2'],
            ':price' => (int)$data['price'],
            ':quantity' => (int)$data['quantity'],
            ':in_stock' => $inStock,
            ':description' => $data['description'],
            ':is_bundled' => $isBundled,
        ]);

        if (!$ok) {
            return ['success' => false, 'message' => 'Failed to create product'];
        }

        $id = (int)$this->db->lastInsertId();
        $product = $this->getProductById($id);

        return [
            'success' => true,
            'message' => 'Product created successfully',
            'product' => $product
        ];
    }

    public function updateProduct(int $id, array $data): array {
        $existing = $this->getProductById($id);
        if (!$existing) {
            return ['success' => false, 'message' => 'Product not found'];
        }

        $fields = ['name', 'brand', 'cat', 'subcat', 'tag1', 'tag2', 'price', 'quantity', 'in_stock', 'description', 'is_bundled'];
        $setParts = [];
        $params = [':id' => $id];

        foreach ($fields as $field) {
            if (array_key_exists($field, $data)) {
                $paramKey = ':' . $field;
                $setParts[] = "{$field} = {$paramKey}";
                if ($field === 'price' || $field === 'quantity') {
                    $params[$paramKey] = (int)$data[$field];
                } elseif ($field === 'in_stock' || $field === 'is_bundled') {
                    $params[$paramKey] = (int)(bool)$data[$field];
                } else {
                    $params[$paramKey] = $data[$field];
                }
            }
        }

        if (empty($setParts)) {
            return ['success' => false, 'message' => 'No fields to update'];
        }

        $sql = "UPDATE product SET " . implode(', ', $setParts) . " WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $ok = $stmt->execute($params);

        if (!$ok) {
            return ['success' => false, 'message' => 'Failed to update product'];
        }

        $product = $this->getProductById($id);

        return [
            'success' => true,
            'message' => 'Product updated successfully',
            'product' => $product
        ];
    }

    public function deleteProduct(int $id): array {
        $existing = $this->getProductById($id);
        if (!$existing) {
            return ['success' => false, 'message' => 'Product not found'];
        }

        $stmt = $this->db->prepare("DELETE FROM product WHERE id = :id");
        $ok = $stmt->execute([':id' => $id]);

        if (!$ok) {
            return ['success' => false, 'message' => 'Failed to delete product'];
        }

        return ['success' => true, 'message' => 'Product deleted successfully'];
    }

    public function setInStock(int $id, bool $inStock): array {
        $existing = $this->getProductById($id);
        if (!$existing) {
            return ['success' => false, 'message' => 'Product not found'];
        }

        $stmt = $this->db->prepare("UPDATE product SET in_stock = :in_stock WHERE id = :id");
        $ok = $stmt->execute([
            ':in_stock' => $inStock ? 1 : 0,
            ':id' => $id
        ]);

        if (!$ok) {
            return ['success' => false, 'message' => 'Failed to update stock status'];
        }

        $product = $this->getProductById($id);
        return [
            'success' => true,
            'message' => 'Stock status updated successfully',
            'product' => $product
        ];
    }

    public function updateQuantity(int $id, int $quantity): array {
        $existing = $this->getProductById($id);
        if (!$existing) {
            return ['success' => false, 'message' => 'Product not found'];
        }

        if ($quantity < 0) {
            return ['success' => false, 'message' => 'Quantity cannot be negative'];
        }

        $stmt = $this->db->prepare("UPDATE product SET quantity = :quantity WHERE id = :id");
        $ok = $stmt->execute([
            ':quantity' => $quantity,
            ':id' => $id
        ]);

        if (!$ok) {
            return ['success' => false, 'message' => 'Failed to update quantity'];
        }

        $product = $this->getProductById($id);
        return [
            'success' => true,
            'message' => 'Quantity updated successfully',
            'product' => $product
        ];
    }

    public function getFacetData(): array {
        $sql = "SELECT 
                    DISTINCT cat,
                    subcat,
                    brand,
                    tag1,
                    tag2
                FROM product";
        $stmt = $this->db->query($sql);
        $rows = $stmt->fetchAll();

        $cats = [];
        $subcats = [];
        $brands = [];
        $tags = [];

        foreach ($rows as $row) {
            if (!empty($row['cat'])) {
                $cats[$row['cat']] = true;
            }
            if (!empty($row['subcat'])) {
                $subcats[$row['subcat']] = true;
            }
            if (!empty($row['brand'])) {
                $brands[$row['brand']] = true;
            }
            if (!empty($row['tag1'])) {
                $tags[$row['tag1']] = true;
            }
            if (!empty($row['tag2'])) {
                $tags[$row['tag2']] = true;
            }
        }

        return [
            'categories' => array_values(array_keys($cats)),
            'subcategories' => array_values(array_keys($subcats)),
            'brands' => array_values(array_keys($brands)),
            'tags' => array_values(array_keys($tags))
        ];
    }
}

