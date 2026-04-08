<?php
require_once __DIR__ . '/../database/Database.php';

class Product {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // =========================
    // Stored procedure helpers
    // =========================

    private function fetchAllFromProcedure(string $callSql, array $params = []): array {
        $stmt = $this->db->prepare($callSql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $stmt->closeCursor();
        return $rows ?: [];
    }

    private function fetchSingleFromProcedure(string $callSql, array $params = []): ?array {
        $stmt = $this->db->prepare($callSql);
        $stmt->execute($params);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        $stmt->closeCursor();
        return $row ?: null;
    }

    public function getProducts(array $filters = []): array {
        $sql = "SELECT id, name, brand, cat, subcat, tag1, tag2, price, quantity, in_stock, description, is_bundled FROM product WHERE 1=1";
        $params = [];

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
        try {
            $row = $this->fetchSingleFromProcedure("CALL getProductById(:pId)", [':pId' => $id]);
            return $row ?: null;
        } catch (PDOException $e) {
            return null;
        }
    }

    public function getAllProductsProcedure(): array {
        // CALL getAllProducts() - SELECT * FROM product ORDER BY id ASC
        return $this->fetchAllFromProcedure("CALL getAllProducts()");
    }

    public function getAllProductCatsProcedure(): array {
        $rows = $this->fetchAllFromProcedure("CALL getAllProductCats()");
        $vals = [];
        foreach ($rows as $row) {
            $vals[] = $row['cat'] ?? reset($row);
        }
        return array_values(array_filter($vals, fn($v) => $v !== null && $v !== ''));
    }

    public function getAllProductSubcatsProcedure(): array {
        $rows = $this->fetchAllFromProcedure("CALL getAllProductSubcats()");
        $vals = [];
        foreach ($rows as $row) {
            $vals[] = $row['subcat'] ?? reset($row);
        }
        return array_values(array_filter($vals, fn($v) => $v !== null && $v !== ''));
    }

    public function getAllProductBrandsProcedure(): array {
        $rows = $this->fetchAllFromProcedure("CALL getAllProductBrands()");
        $vals = [];
        foreach ($rows as $row) {
            $vals[] = $row['brand'] ?? reset($row);
        }
        return array_values(array_filter($vals, fn($v) => $v !== null && $v !== ''));
    }

    public function getAllProductNamesProcedure(): array {
        // getAllProductNames() selects DISTINCT(name)
        $rows = $this->fetchAllFromProcedure("CALL getAllProductNames()");
        $vals = [];
        foreach ($rows as $row) {
            $vals[] = $row['name'] ?? reset($row);
        }
        return array_values(array_filter($vals, fn($v) => $v !== null && $v !== ''));
    }

    public function getAllProductTagsProcedure(): array {
        // getAllProductTags() selects DISTINCT(tag1) UNION DISTINCT(tag2)
        $rows = $this->fetchAllFromProcedure("CALL getAllProductTags()");
        $vals = [];
        foreach ($rows as $row) {
            $vals[] = $row['tag1'] ?? $row['tag2'] ?? reset($row);
        }
        return array_values(array_filter($vals, fn($v) => $v !== null && $v !== ''));
    }

    public function getProductBrandByIdProcedure(int $id): ?string {
        $row = $this->fetchSingleFromProcedure("CALL getProductBrandById(:id)", [':id' => $id]);
        if (!$row) return null;
        // Procedure returns `brand AS "Márka"` in SQL, so column name might be "Márka".
        foreach ($row as $v) {
            if ($v !== null && $v !== '') return (string)$v;
        }
        return null;
    }

    public function getProductsByBrandNameProcedure(string $brandName): array {
        // Procedure: SELECT * FROM product WHERE brand LIKE pName
        $pattern = '%' . $brandName . '%';
        return $this->fetchAllFromProcedure("CALL getProductsByBrandName(:pName)", [':pName' => $pattern]);
    }

    public function createProduct(array $data): array {
        $required = ['name', 'brand', 'cat', 'subcat', 'tag1', 'tag2', 'price', 'quantity', 'description'];
        foreach ($required as $field) {
            if (!isset($data[$field]) || $data[$field] === '') {
                return ['success' => false, 'message' => "Field '{$field}' is required"];
            }
        }

        try {
            // CALL createProduct(pName, pBrand, pCat, pSubcat, pTag1, pTag2, pPrice, pQuantity, pInStock, pDescription, pIsBundled)
            $inStock = isset($data['in_stock']) ? (bool)$data['in_stock'] : true;
            $isBundled = isset($data['is_bundled']) ? (bool)$data['is_bundled'] : false;

            $stmt = $this->db->prepare("
                CALL createProduct(
                    :pName, :pBrand, :pCat, :pSubcat, :pTag1, :pTag2,
                    :pPrice, :pQuantity, :pInStock, :pDescription, :pIsBundled
                )
            ");

            $stmt->execute([
                ':pName' => (string)$data['name'],
                ':pBrand' => (string)$data['brand'],
                ':pCat' => (string)$data['cat'],
                ':pSubcat' => (string)$data['subcat'],
                ':pTag1' => (string)$data['tag1'],
                ':pTag2' => (string)$data['tag2'],
                ':pPrice' => (int)$data['price'],
                ':pQuantity' => (int)$data['quantity'],
                ':pInStock' => $inStock ? 1 : 0,
                ':pDescription' => (string)$data['description'],
                ':pIsBundled' => $isBundled ? 1 : 0,
            ]);
            $stmt->closeCursor();

            // createProduct procedure doesn't return new id; best-effort fetch by unique-ish combination
            $product = $this->getProductByUniqueFields((string)$data['name'], (string)$data['brand'], (int)$data['price'], (int)$data['quantity']);
            if (!$product) {
                return ['success' => true, 'message' => 'Product created successfully (id lookup skipped)'];
            }

            return ['success' => true, 'message' => 'Product created successfully', 'product' => $product];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => 'Failed to create product: ' . $e->getMessage()];
        }
    }

    private function getProductByUniqueFields(string $name, string $brand, int $price, int $quantity): ?array {
        $stmt = $this->db->prepare(
            "SELECT id, name, brand, cat, subcat, tag1, tag2, price, quantity, in_stock, description, is_bundled
             FROM product
             WHERE name = :name AND brand = :brand AND price = :price AND quantity = :quantity
             ORDER BY id DESC
             LIMIT 1"
        );
        $stmt->execute([
            ':name' => $name,
            ':brand' => $brand,
            ':price' => $price,
            ':quantity' => $quantity
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ?: null;
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

        try {
            $stmt = $this->db->prepare("CALL deleteProduct(:pId)");
            $stmt->execute([':pId' => $id]);
            $stmt->closeCursor();
            return ['success' => true, 'message' => 'Product deleted successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => 'Failed to delete product: ' . $e->getMessage()];
        }
    }

    public function updateQuantity(int $id, int $quantity): array {
        $existing = $this->getProductById($id);
        if (!$existing) {
            return ['success' => false, 'message' => 'Product not found'];
        }

        if ($quantity < 0) {
            return ['success' => false, 'message' => 'Quantity cannot be negative'];
        }
        try {
            // CALL updateProductQuantity(pProductId, pNewQuantity)
            $stmt = $this->db->prepare("CALL updateProductQuantity(:pProductId, :pNewQuantity)");
            $stmt->execute([
                ':pProductId' => $id,
                ':pNewQuantity' => $quantity
            ]);
            $stmt->closeCursor();
        } catch (PDOException $e) {
            return ['success' => false, 'message' => 'Failed to update quantity: ' . $e->getMessage()];
        }

        $product = $this->getProductById($id);
        return [
            'success' => true,
            'message' => 'Quantity updated successfully',
            'product' => $product
        ];
    }

    public function addToQuantity(int $id, int $quantity): array {
        $existing = $this->getProductById($id);
        if (!$existing) {
            return ['success' => false, 'message' => 'Product not found'];
        }
        if ($quantity <= 0) {
            return ['success' => false, 'message' => 'Quantity must be > 0'];
        }

        try {
            $stmt = $this->db->prepare("CALL addToProductQuantity(:pId, :pQuantity)");
            $stmt->execute([
                ':pId' => $id,
                ':pQuantity' => $quantity
            ]);
            $stmt->closeCursor();

            // Ensure in_stock flag is correct after adding
            $stmt = $this->db->prepare("UPDATE product SET in_stock = 1 WHERE id = :id");
            $stmt->execute([':id' => $id]);
        } catch (PDOException $e) {
            return ['success' => false, 'message' => 'Failed to add quantity: ' . $e->getMessage()];
        }

        $product = $this->getProductById($id);
        return ['success' => true, 'message' => 'Quantity added successfully', 'product' => $product];
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

