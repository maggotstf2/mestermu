<?php
require_once __DIR__ . '/../utils/JWT.php';

class AuthMiddleware {
    // Autentikáció ellenőrzése
    public static function authenticate() {
        $token = JWT::getTokenFromHeader();
        
        if (!$token) {
            self::sendUnauthorized('Authentication token required');
            exit;
        }

        $payload = JWT::verifyToken($token);
        
        if (!$payload) {
            self::sendUnauthorized('Invalid or expired token');
            exit;
        }

        return $payload;
    }

    // Admin role ellenőrzése
    public static function requireAdmin() {
        $payload = self::authenticate();
        
        if ($payload['role'] !== 'admin') {
            self::sendForbidden('Admin access required');
            exit;
        }

        return $payload;
    }

    private static function sendUnauthorized($message) {
        http_response_code(401);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => $message]);
    }

    private static function sendForbidden($message) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => $message]);
    }
}
