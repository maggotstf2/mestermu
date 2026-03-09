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
            'in_stock_only' => isset($_GET['in_stock_only']) ? (bool)$_GET['in_stock_only'] : true,
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
}

