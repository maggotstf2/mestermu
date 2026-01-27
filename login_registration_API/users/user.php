<?php

require_once __DIR__ . '/../database/db.php';
require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/../config/config.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class User {
    private $db;
    
    public function __construct() {
        $this->db = db::getInstance()->getConnection();
    }
    
    // uj felhasznalo letrehozasa
    public function createUser($username,$email,$password,$firstName,$lastName)
    {
        //bemeneti adatok validalasa
        if(empty($username) || empty($email) || empty($password) || empty($firstName) || empty($lastName))
        {
            return ['success' => false, 'message' => 'Az összes mezőt ki kell tölteni'];
        }
        
        if(!filter_var($email, FILTER_VALIDATE_EMAIL))
        {
           return ['success' => false, 'message' => 'Helytelen email']; 
        }
        
        if(strlen($password)<8)
        {
            return ['success' => false, 'message' => 'A jelszó legalabb 8 karakter hosszú kell legyen'];
        }
        
        $stmt = $this->db->prepare("SELECT id FROM user WHERE username = ?");
        $stmt->execute([$username]);
        if ($stmt->fetch())
        {
           return ['success' => false, 'message' => 'A felhasználónév már foglalt']; 
        }
        
        $stmt2 = $this->db->prepare("SELECT id FROM user WHERE email = ?");
        $stmt2->execute([$email]);
        if ($stmt2->fetch())
        {
           return ['success' => false, 'message' => 'Ezt az emailt már regisztrálták']; 
        }

        try{
            $this->db->beginTransaction();
            
            // Beszuras a user tablaba
            $stmt = $this->db->prepare("INSERT INTO user (username, email, first_name, last_name) VALUES (?, ?, ?, ?)");
            $stmt->execute([$username, $email, $firstName, $lastName]);
            $userId = $this->db->lastInsertId();
            
            // Jelszo hash-elese SHA2-vel (ahogy az adatbazisban hasznaljuk)
            $hashedPassword = hash('sha256', $password);

            // Beszuras a user_secret tablaba
            $stmt = $this->db->prepare("INSERT INTO user_secret (username, password) VALUES (?, ?)");
            $stmt->execute([$username, $hashedPassword]);

            $this->db->commit();

            return [
                'success' => true,
                'message' => 'User created successfully',
                'user_id' => $userId
            ];

        } catch (PDOException $e) {
            $this->db->rollBack();
            return ['success' => false, 'message' => 'Failed to create user: ' . $e->getMessage()];
        }
    }


    //------------------------------------------------------------------------------------------------
    
    // Bejelentkezes es JWT token generalasa
    public function login($username, $password)
    {
        // Bemeneti adatok validalasa
        if(empty($username) || empty($password))
        {
            return ['success' => false, 'message' => 'Felhasználónév és jelszó megadása kötelező'];
        }
        
        try {
            // Az auth_user stored procedure hasznalata
            $stmt = $this->db->prepare("CALL auth_user(?, ?)");
            $stmt->execute([$username, $password]);
            $user = $stmt->fetch();
            
            // Ha nincs talalat, a kovetkezo result set-et is le kell kezelni
            $stmt->nextRowset();
            
            if(!$user)
            {
                return ['success' => false, 'message' => 'Helytelen felhasználónév vagy jelszó'];
            }
            
            // JWT token payload
            $payload = [
                'iss' => 'login_registration_API', 
                'iat' => time(), 
                'exp' => time() + (60 * 45), // lejarati ido (jelenleg 45 p)
                'user_id' => $user['id'],
                'username' => $user['username'],
                'email' => $user['email']
            ];
            
            // JWT token generalasa
            $jwt = JWT::encode($payload, JWT_SECRET, 'HS256');
            
            return [
                'success' => true,
                'message' => 'Sikeres bejelentkezés',
                'token' => $jwt,
                'user' => [
                    'id' => $user['id'],
                    'username' => $user['username'],
                    'email' => $user['email']
                ]
            ];
            
        } catch (PDOException $e) {
            return ['success' => false, 'message' => 'Bejelentkezési hiba: ' . $e->getMessage()];
        } catch (Exception $e) {
            return ['success' => false, 'message' => 'Token generálási hiba: ' . $e->getMessage()];
        }
    }
    
    // JWT token validalasa es visszafejtese
    public static function validateToken($token)
    {
        try {
            if(empty($token))
            {
                return ['success' => false, 'message' => 'Token hiányzik'];
            }
            
            $decoded = JWT::decode($token, new Key(JWT_SECRET, 'HS256'));
            return [
                'success' => true,
                'data' => (array)$decoded
            ];
            
        } catch (\Firebase\JWT\ExpiredException $e) {
            return ['success' => false, 'message' => 'A token lejárt'];
        } catch (\Firebase\JWT\SignatureInvalidException $e) {
            return ['success' => false, 'message' => 'Érvénytelen token aláírás'];
        } catch (Exception $e) {
            return ['success' => false, 'message' => 'Érvénytelen token: ' . $e->getMessage()];
        }
    }


}