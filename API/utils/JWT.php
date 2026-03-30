<?php
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../vendor/autoload.php';

use Firebase\JWT\JWT as FirebaseJWT;
use Firebase\JWT\Key;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\SignatureInvalidException;
use Firebase\JWT\BeforeValidException;
//use UnexpectedValueException;

class JWT {
    /**
     * JWT token generálása Firebase PHP-JWT használatával
     */
    public static function generateToken($userId, $username, $role) {
        $payload = [
            'user_id' => $userId,
            'username' => $username,
            'role' => $role,
            'iat' => time(),
            'exp' => time() + JWT_EXPIRATION
        ];

        return FirebaseJWT::encode($payload, JWT_SECRET, JWT_ALGORITHM);
    }

    /**
     * JWT token ellenőrzése és dekódolása Firebase PHP-JWT használatával
     *
     * @param string $token
     * @return array|null
     */
    public static function verifyToken($token) {
        try {
            $decoded = FirebaseJWT::decode($token, new Key(JWT_SECRET, JWT_ALGORITHM));

            // Firebase JWT stdClass-t ad vissza, alakítsuk tömbbé a meglévő kódhoz
            return json_decode(json_encode($decoded), true);
        } catch (ExpiredException $e) {
            return null;
        } catch (SignatureInvalidException $e) {
            return null;
        } catch (BeforeValidException $e) {
            return null;
        } //catch (UnexpectedValueException $e) {
        //     return null;
        // }
    }

    /**
     * Token lekérése a kérés Authorization header-éből (Bearer <token>)
     *
     * @return string|null
     */
    public static function getTokenFromHeader() {
        // Néhány szerveren a getallheaders nem elérhető, kezeljük le biztonságosan
        if (function_exists('getallheaders')) {
            $headers = getallheaders();
        } else {
            $headers = [];
            foreach ($_SERVER as $name => $value) {
                if (str_starts_with($name, 'HTTP_')) {
                    $headerName = str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))));
                    $headers[$headerName] = $value;
                }
            }
        }

        if (isset($headers['Authorization'])) {
            $authHeader = $headers['Authorization'];
            if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
                return $matches[1];
            }
        }

        return null;
    }
}


