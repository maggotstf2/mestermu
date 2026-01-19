<?php

require_once __DIR__ . '/../database/db.php';

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
        
        if(strlen($password)<6)
        {
            return ['success' => false, 'message' => 'A jelszó legalabb 6 karakter hosszú kell legyen'];
        }
        
        $stmt = $this->db->prepare("SELECT id FROM user WHERE username = ?");
        $stmt->execute([$username]);
        if ($stmt->fetch())
        {
           return ['success' => false, 'message' => 'A felhasználónév már foglalt']; 
        }
        
        $stmt = $this->db->prepare("SELECT id FROM user WHERE email = ?");
        $stmt->execute([$email]);
        if ($stmt->fetch())
        {
           return ['success' => false, 'message' => 'Ezt az emailt már regisztrálták']; 
        }
    }
    
}