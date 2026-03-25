<?php
// CORS engedélyezése
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');
}

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD'])) {
        header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS");
    }
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'])) {
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    }
    exit(0);
}

// Konfiguráció betöltése
require_once __DIR__ . '/config/config.php';

// Hibajelentés
if (DEBUG_MODE) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}

// Globális hibakezelés: mindig JSON-t adjunk vissza,
// hogy a frontend ne "res.json()" hibával fusson el.
set_exception_handler(function ($e) {
    http_response_code(500);
    header('Content-Type: application/json');
    $msg = DEBUG_MODE ? ($e->getMessage() ?: 'Server error') : 'Server error';
    echo json_encode([
        'success' => false,
        'message' => $msg,
        'details' => DEBUG_MODE ? $e->getMessage() : null
    ]);
    exit;
});

set_error_handler(function ($severity, $message, $file, $line) {
    http_response_code(500);
    header('Content-Type: application/json');
    $msg = DEBUG_MODE ? ($message ?: 'Server error') : 'Server error';
    echo json_encode([
        'success' => false,
        'message' => $msg,
        'details' => DEBUG_MODE ? ($message . ' in ' . $file . ':' . $line) : null
    ]);
    exit;
});

// Router osztály
class Router {
    private $routes = [];

    public function addRoute($method, $path, $handler) {
        $this->routes[] = [
            'method' => $method,
            'path' => $path,
            'handler' => $handler
        ];
    }

    public function dispatch() {
        $method = $_SERVER['REQUEST_METHOD'];
        $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        $uri = str_replace('/api', '', $uri); // /api prefix eltávolítása ha létezik
        $uri = rtrim($uri, '/') ?: '/';

        foreach ($this->routes as $route) {
            $pattern = $this->convertPathToRegex($route['path']);
            
            if ($route['method'] === $method && preg_match($pattern, $uri, $matches)) {
                array_shift($matches); // Teljes egyezés eltávolítása
                
                if (is_array($route['handler']) && count($route['handler']) === 2) {
                    $controllerClass = $route['handler'][0];
                    $method = $route['handler'][1];
                    $controller = new $controllerClass();
                    call_user_func_array([$controller, $method], $matches);
                    return;
                } else if (is_callable($route['handler'])) {
                    call_user_func_array($route['handler'], $matches);
                    return;
                }
            }
        }

        // 404 Nem található
        http_response_code(404);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'Endpoint not found'
        ]);
    }

    private function convertPathToRegex($path) {
        $pattern = preg_replace('/\{([^}]+)\}/', '([^/]+)', $path);
        return '#^' . $pattern . '$#';
    }
}

// Router inicializálása
$router = new Router();

// Controller-ek betöltése
require_once __DIR__ . '/controllers/AuthController.php';
require_once __DIR__ . '/controllers/AdminController.php';
require_once __DIR__ . '/controllers/ProductController.php';
require_once __DIR__ . '/controllers/OrderController.php';
require_once __DIR__ . '/controllers/ReservationController.php';
require_once __DIR__ . '/controllers/AdminReservationController.php';

// Route-ok definiálása
// Autentikációs route-ok
$router->addRoute('POST', '/signup', ['AuthController', 'signup']);
$router->addRoute('POST', '/login', ['AuthController', 'login']);
$router->addRoute('GET', '/profile', ['AuthController', 'profile']);

// Admin route-ok
$router->addRoute('GET', '/admin/users', ['AdminController', 'getAllUsers']);
$router->addRoute('GET', '/admin/users/{id}', ['AdminController', 'getUserById']);
$router->addRoute('PUT', '/admin/users/{id}/role', ['AdminController', 'updateUserRole']);
$router->addRoute('DELETE', '/admin/users/{id}', ['AdminController', 'deleteUser']);
$router->addRoute('GET', '/admin/dashboard', ['AdminController', 'dashboard']);

// Publikus termék route-ok
$router->addRoute('GET', '/products', ['ProductController', 'list']);
$router->addRoute('GET', '/products/facets', ['ProductController', 'facets']);
$router->addRoute('GET', '/products/all', ['ProductController', 'all']);
$router->addRoute('GET', '/products/cats', ['ProductController', 'cats']);
$router->addRoute('GET', '/products/subcats', ['ProductController', 'subcats']);
$router->addRoute('GET', '/products/brands', ['ProductController', 'brands']);
$router->addRoute('GET', '/products/tags', ['ProductController', 'tags']);
$router->addRoute('GET', '/products/names', ['ProductController', 'names']);
$router->addRoute('GET', '/products/by-brand/{brandName}', ['ProductController', 'byBrandName']);
$router->addRoute('GET', '/products/{id}/brand', ['ProductController', 'brandById']);
$router->addRoute('GET', '/products/{id}', ['ProductController', 'getById']);

// Rendelés route-ok (auth)
$router->addRoute('POST', '/orders', ['OrderController', 'create']);
$router->addRoute('GET', '/orders', ['OrderController', 'list']);
$router->addRoute('GET', '/orders/{id}', ['OrderController', 'details']);
$router->addRoute('POST', '/orders/{id}/items', ['OrderController', 'addItem']);
$router->addRoute('PATCH', '/orders/{id}/items/{productId}', ['OrderController', 'updateItemQuantity']);
$router->addRoute('PUT', '/orders/{id}/items/{productId}', ['OrderController', 'updateItemQuantity']);
$router->addRoute('DELETE', '/orders/{id}', ['OrderController', 'delete']);

// Foglalás route-ok (auth)
$router->addRoute('POST', '/reservations', ['ReservationController', 'create']);
$router->addRoute('GET', '/reservations', ['ReservationController', 'list']);
$router->addRoute('PATCH', '/reservations/{id}', ['ReservationController', 'update']);
$router->addRoute('PUT', '/reservations/{id}', ['ReservationController', 'update']);
$router->addRoute('DELETE', '/reservations/{id}', ['ReservationController', 'delete']);

// Admin foglalás route-ok
$router->addRoute('PATCH', '/admin/reservations/{id}/duration', ['AdminReservationController', 'updateDuration']);
$router->addRoute('PUT', '/admin/reservations/{id}/duration', ['AdminReservationController', 'updateDuration']);

// Admin termék route-ok
$router->addRoute('POST', '/admin/products', ['AdminController', 'createProduct']);
$router->addRoute('PUT', '/admin/products/{id}', ['AdminController', 'updateProduct']);
$router->addRoute('PATCH', '/admin/products/{id}', ['AdminController', 'updateProduct']);
$router->addRoute('DELETE', '/admin/products/{id}', ['AdminController', 'deleteProduct']);
$router->addRoute('PATCH', '/admin/products/{id}/quantity/add', ['AdminController', 'addProductQuantity']);
$router->addRoute('PATCH', '/admin/products/{id}/stock/out', ['AdminController', 'setProductOutOfStock']);
$router->addRoute('PATCH', '/admin/products/{id}/stock/in', ['AdminController', 'setProductInStock']);
$router->addRoute('PATCH', '/admin/products/{id}/quantity', ['AdminController', 'updateProductQuantity']);

// Health check endpoint
$router->addRoute('GET', '/', function() {
    header('Content-Type: application/json');
    echo json_encode([
        'success' => true,
        'message' => 'PHP REST API is running',
        'version' => '1.0.0',
        'endpoints' => [
            'POST /signup' => 'User registration',
            'POST /login' => 'User authentication',
            'GET /profile' => 'Get current user profile (requires auth)',
            'GET /admin/users' => 'Get all users (admin only)',
            'GET /admin/users/{id}' => 'Get user by ID (admin only)',
            'PUT /admin/users/{id}/role' => 'Update user role (admin only)',
            'DELETE /admin/users/{id}' => 'Delete user (admin only)',
            'GET /admin/dashboard' => 'Get admin dashboard stats (admin only)',
            'GET /products' => 'List products with filters',
            'GET /products/{id}' => 'Get product by ID',
            'GET /products/facets' => 'Get product filter facets',
            'POST /admin/products' => 'Create product (admin only)',
            'PUT/PATCH /admin/products/{id}' => 'Update product (admin only)',
            'DELETE /admin/products/{id}' => 'Delete product (admin only)',
            'PATCH /admin/products/{id}/stock/out' => 'Set product out of stock (admin only)',
            'PATCH /admin/products/{id}/stock/in' => 'Set product back in stock (admin only)',
            'PATCH /admin/products/{id}/quantity' => 'Update product quantity (admin only)'
        ]
    ]);
});

// Kérés feldolgozása
$router->dispatch();
