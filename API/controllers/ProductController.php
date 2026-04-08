<?php
require_once __DIR__ . '/../models/Product.php';

class ProductController {
    private $productModel;

    public function __construct() {
        $this->productModel = new Product();
    }

    // Publikus termék lista (szűrés + lapozás)
    public function list() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $filters = [
            'cat' => $_GET['cat'] ?? null,
            'subcat' => $_GET['subcat'] ?? null,
            'brand' => $_GET['brand'] ?? null,
            'tag' => $_GET['tag'] ?? null,
            'search' => $_GET['search'] ?? null,
            'min_price' => $_GET['min_price'] ?? null,
            'max_price' => $_GET['max_price'] ?? null,
            'page' => $_GET['page'] ?? 1,
            'limit' => $_GET['limit'] ?? 50,
        ];

        $products = $this->productModel->getProducts($filters);
        $total = $this->productModel->countProducts($filters);

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'items' => $products,
            'total' => $total,
            'page' => (int)$filters['page'],
            'limit' => (int)$filters['limit']
        ]);
    }

    // Egy termék lekérése ID alapján (publikus)
    public function getById($id) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $productId = (int)$id;
        $product = $this->productModel->getProductById($productId);

        if ($product) {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'product' => $product
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Product not found']);
        }
    }

    // Szűrési facet adatok (kategóriák, márkák, tagek)
    public function facets() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $facets = $this->productModel->getFacetData();

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'facets' => $facets
        ]);
    }

    // =========================
    // Product procedures endpoints
    // =========================

    // GET /products/all
    public function all() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $items = $this->productModel->getAllProductsProcedure();

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'items' => $items,
            'count' => count($items),
        ]);
    }

    public function cats() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $items = $this->productModel->getAllProductCatsProcedure();
        http_response_code(200);
        echo json_encode(['success' => true, 'items' => $items, 'count' => count($items)]);
    }

    public function subcats() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $items = $this->productModel->getAllProductSubcatsProcedure();
        http_response_code(200);
        echo json_encode(['success' => true, 'items' => $items, 'count' => count($items)]);
    }

    public function brands() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $items = $this->productModel->getAllProductBrandsProcedure();
        http_response_code(200);
        echo json_encode(['success' => true, 'items' => $items, 'count' => count($items)]);
    }

    public function tags() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $items = $this->productModel->getAllProductTagsProcedure();
        http_response_code(200);
        echo json_encode(['success' => true, 'items' => $items, 'count' => count($items)]);
    }

    public function names() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $items = $this->productModel->getAllProductNamesProcedure();
        http_response_code(200);
        echo json_encode(['success' => true, 'items' => $items, 'count' => count($items)]);
    }

    // GET /products/by-brand/{brandName}
    public function byBrandName($brandName) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $items = $this->productModel->getProductsByBrandNameProcedure((string)$brandName);

        http_response_code(200);
        echo json_encode(['success' => true, 'items' => $items, 'count' => count($items)]);
    }

    // GET /products/{id}/brand
    public function brandById($id) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $brand = $this->productModel->getProductBrandByIdProcedure((int)$id);
        if ($brand === null) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Product not found']);
            return;
        }

        http_response_code(200);
        echo json_encode(['success' => true, 'brand' => $brand]);
    }
}

