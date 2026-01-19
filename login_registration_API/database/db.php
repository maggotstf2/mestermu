<?php

require_once __DIR__ . '/../config/config.php';

class db {
    private static $instance = null;
    private $connection;
    
    
    private function __construct() {
        try {
            $this->connection = new PDO(
                "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
                DB_USER,
                DB_PASS,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false
                ]
                    
            );
            
        } catch(PDOException $e){
            echo ('Database Connection Error:'  . $e->getMessage()); //ezt az eles verziora vedd ki!!!!
            die;
        }
    }
    
    public static function getInstance() {
        if (self::$instance === null){
            //létrehozzuk az objektumot
            self::$instance = new self();
        } 
        //ha mar letezik akkor visszaadjuk
        return self::$instance;
    }
    
    public function getConnection(){
        return $this->connection;
    }
    
    //adatbazis kapcsolat klonozasanak megakadalyozasa
    private function __clone() {}
  
    //letiltjuk hogy az adatbazis kapcsolat mentett szovegbol ujraletrehozhat legyen
    public function __wakeup(){
        throw new Exception("Cannot unserialize singleton");
    }
}
