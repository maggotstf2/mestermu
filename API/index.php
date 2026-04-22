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
$router->addRoute('PUT', '/profile/username', ['AuthController', 'updateUsername']);
$router->addRoute('PUT', '/profile/password', ['AuthController', 'updatePassword']);

// Admin route-ok
$router->addRoute('GET', '/admin/users', ['AdminController', 'getAllUsers']);
$router->addRoute('GET', '/admin/users/{id}', ['AdminController', 'getUserById']);
$router->addRoute('PUT', '/admin/users/{id}/role', ['AdminController', 'updateUserRole']);
$router->addRoute('DELETE', '/admin/users/{id}', ['AdminController', 'deleteUser']);
$router->addRoute('GET', '/admin/dashboard', ['AdminController', 'dashboard']);
$router->addRoute('GET', '/admin/orders', ['AdminController', 'getAllOrders']);
$router->addRoute('GET', '/admin/orders/summary', ['AdminController', 'getAllOrdersSummary']);
$router->addRoute('GET', '/admin/orders/status-options', ['AdminController', 'getOrderStatusOptions']);
$router->addRoute('PATCH', '/admin/orders/{id}/status', ['AdminController', 'updateOrderStatus']);
$router->addRoute('PUT', '/admin/orders/{id}/status', ['AdminController', 'updateOrderStatus']);

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
$router->addRoute('POST', '/reservations/public', ['ReservationController', 'createPublic']);
$router->addRoute('GET', '/reservations', ['ReservationController', 'list']);
$router->addRoute('PATCH', '/reservations/{id}', ['ReservationController', 'update']);
$router->addRoute('PUT', '/reservations/{id}', ['ReservationController', 'update']);
$router->addRoute('DELETE', '/reservations/{id}', ['ReservationController', 'delete']);

// Admin foglalás route-ok
$router->addRoute('GET', '/admin/reservations', ['AdminReservationController', 'list']);
$router->addRoute('PATCH', '/admin/reservations/{id}/duration', ['AdminReservationController', 'updateDuration']);
$router->addRoute('PUT', '/admin/reservations/{id}/duration', ['AdminReservationController', 'updateDuration']);

// Admin termék route-ok
$router->addRoute('POST', '/admin/products', ['AdminController', 'createProduct']);
$router->addRoute('PUT', '/admin/products/{id}', ['AdminController', 'updateProduct']);
$router->addRoute('PATCH', '/admin/products/{id}', ['AdminController', 'updateProduct']);
$router->addRoute('DELETE', '/admin/products/{id}', ['AdminController', 'deleteProduct']);
$router->addRoute('PATCH', '/admin/products/{id}/quantity/add', ['AdminController', 'addProductQuantity']);

// Dokumentációs route-ok (Quartz static fájlok kiszolgálása API-n keresztül)
$documentationRoot = realpath(__DIR__ . '/../documentation/quartz/public');

$serveDocumentationFile = function ($relativePath, $contentType = 'text/plain; charset=UTF-8') use ($documentationRoot) {
    if (!$documentationRoot) {
        http_response_code(500);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Documentation root not found']);
        exit;
    }

    $fullPath = realpath($documentationRoot . '/' . $relativePath);
    if (!$fullPath || strpos($fullPath, $documentationRoot) !== 0 || !is_file($fullPath)) {
        http_response_code(404);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Documentation file not found']);
        exit;
    }

    header('Content-Type: ' . $contentType);
    readfile($fullPath);
    exit;
};

$serveDocumentationPage = function ($pageFile) use ($serveDocumentationFile, $documentationRoot) {
    $fullPath = realpath($documentationRoot . '/' . $pageFile);
    if (!$fullPath || !is_file($fullPath)) {
        http_response_code(404);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Documentation page not found']);
        exit;
    }

    $html = file_get_contents($fullPath);
    if ($html === false) {
        http_response_code(500);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Failed to load documentation page']);
        exit;
    }

    // Ensure relative Quartz assets resolve under /documentation/*
    $html = preg_replace('/<head>/i', '<head><base href="/documentation/">', $html, 1);
    header('Content-Type: text/html; charset=UTF-8');
    echo $html;
    exit;
};

$router->addRoute('GET', '/documentation', function () use ($serveDocumentationPage) {
    $serveDocumentationPage('index.html');
});
$router->addRoute('GET', '/documentation/architecture', function () use ($serveDocumentationPage) {
    $serveDocumentationPage('architecture.html');
});
$router->addRoute('GET', '/documentation/backend-api', function () use ($serveDocumentationPage) {
    $serveDocumentationPage('backend-api.html');
});
$router->addRoute('GET', '/documentation/database', function () use ($serveDocumentationPage) {
    $serveDocumentationPage('database.html');
});
$router->addRoute('GET', '/documentation/frontend', function () use ($serveDocumentationPage) {
    $serveDocumentationPage('frontend.html');
});
$router->addRoute('GET', '/documentation/security', function () use ($serveDocumentationPage) {
    $serveDocumentationPage('security.html');
});
$router->addRoute('GET', '/documentation/setup', function () use ($serveDocumentationPage) {
    $serveDocumentationPage('setup.html');
});
$router->addRoute('GET', '/documentation/testing', function () use ($serveDocumentationPage) {
    $serveDocumentationPage('testing.html');
});
$router->addRoute('GET', '/documentation/tags', function () use ($serveDocumentationPage) {
    $serveDocumentationPage('tags/index.html');
});

// Documentation static assets used by Quartz pages
$router->addRoute('GET', '/documentation/index.css', function () use ($serveDocumentationFile) {
    $serveDocumentationFile('index.css', 'text/css; charset=UTF-8');
});
$router->addRoute('GET', '/documentation/prescript.js', function () use ($serveDocumentationFile) {
    $serveDocumentationFile('prescript.js', 'application/javascript; charset=UTF-8');
});
$router->addRoute('GET', '/documentation/postscript.js', function () use ($serveDocumentationFile) {
    $serveDocumentationFile('postscript.js', 'application/javascript; charset=UTF-8');
});
$router->addRoute('GET', '/documentation/index.xml', function () use ($serveDocumentationFile) {
    $serveDocumentationFile('index.xml', 'application/xml; charset=UTF-8');
});
$router->addRoute('GET', '/documentation/sitemap.xml', function () use ($serveDocumentationFile) {
    $serveDocumentationFile('sitemap.xml', 'application/xml; charset=UTF-8');
});
$router->addRoute('GET', '/documentation/torma_database_diagram.drawio.svg', function () use ($serveDocumentationFile) {
    $serveDocumentationFile('torma_database_diagram.drawio.svg', 'image/svg+xml');
});
$router->addRoute('GET', '/documentation/static/contentIndex.json', function () use ($serveDocumentationFile) {
    $serveDocumentationFile('static/contentIndex.json', 'application/json; charset=UTF-8');
});
$router->addRoute('GET', '/documentation/static/giscus/light.css', function () use ($serveDocumentationFile) {
    $serveDocumentationFile('static/giscus/light.css', 'text/css; charset=UTF-8');
});
$router->addRoute('GET', '/documentation/static/giscus/dark.css', function () use ($serveDocumentationFile) {
    $serveDocumentationFile('static/giscus/dark.css', 'text/css; charset=UTF-8');
});

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
            'GET /admin/orders' => 'Get all orders (admin only)',
            'GET /products' => 'List products with filters',
            'GET /products/{id}' => 'Get product by ID',
            'GET /products/facets' => 'Get product filter facets',
            'POST /admin/products' => 'Create product (admin only)',
            'PUT/PATCH /admin/products/{id}' => 'Update product (admin only)',
            'DELETE /admin/products/{id}' => 'Delete product (admin only)',
            'PATCH /admin/products/{id}/quantity' => 'Update product quantity (admin only)',
            'GET /documentation' => 'Serve Quartz documentation home',
            'GET /documentation/{section}' => 'Serve documentation subsection page'
        ]
    ]);
});

// Kérés feldolgozása
$router->dispatch();
