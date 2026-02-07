<?php
require_once __DIR__ . '/../database/Database.php';

class User {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // Új felhasználó létrehozása (regisztráció)
    public function createUser($username, $email, $password, $firstName = '', $lastName = '') {
        // Bemeneti adatok validálása
        if (empty($username) || empty($email) || empty($password)) {
            return ['success' => false, 'message' => 'All fields are required'];
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return ['success' => false, 'message' => 'Invalid email format'];
        }

        if (strlen($password) < 6) {
            return ['success' => false, 'message' => 'Password must be at least 6 characters'];
        }

        // Ellenőrzés, hogy a felhasználónév vagy email már létezik-e
        $stmt = $this->db->prepare("SELECT id FROM user WHERE username = ? OR email = ?");
        $stmt->execute([$username, $email]);
        if ($stmt->fetch()) {
            return ['success' => false, 'message' => 'Username or email already exists'];
        }

        // Felhasználó beszúrása stored procedure vagy közvetlen SQL-lel
        try {
            $this->db->beginTransaction();
            
            // Beszúrás a user táblába
            $stmt = $this->db->prepare("INSERT INTO user (username, email, first_name, last_name) VALUES (?, ?, ?, ?)");
            $stmt->execute([$username, $email, $firstName, $lastName]);
            $userId = $this->db->lastInsertId();
            
            // Jelszó hash-elése SHA2-vel (ahogy az adatbázisban használjuk)
            $hashedPassword = hash('sha256', $password);
            
            // Beszúrás a user_secret táblába
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

    // Felhasználó autentikálása (bejelentkezés)
    public function authenticate($username, $password) {
        if (empty($username) || empty($password)) {
            return ['success' => false, 'message' => 'Username and password are required'];
        }
        try {
            /**
             * Az új SQL-ben található auth_user stored procedure-rel autentikálunk.
             * A procedure SHA2-vel hash-eli a jelszót, így itt nyers jelszót adunk át.
             */
            $stmt = $this->db->prepare("CALL auth_user(:username, :password)");
            $stmt->execute([
                ':username' => $username,
                ':password' => $password
            ]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            // A PDO/MariaDB driver miatt érdemes a fölösleges result seteket lezárni
            // hogy későbbi lekérdezések ne akadjanak.
            $stmt->closeCursor();

            if (!$row) {
                return ['success' => false, 'message' => 'Invalid credentials'];
            }

            // Teljes felhasználói adatok lekérése az id alapján (role kiszámítása is itt történik)
            $user = $this->getUserById($row['id']);

            return [
                'success' => true,
                'message' => 'Login successful',
                'user' => $user
            ];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => 'Failed to authenticate user: ' . $e->getMessage()];
        }
    }

    // Ellenőrzés, hogy a felhasználó admin-e
    public function isAdmin($username) {
        $stmt = $this->db->prepare("SELECT id FROM admin WHERE username = ?");
        $stmt->execute([$username]);
        return $stmt->fetch() !== false;
    }

    // Felhasználó lekérése ID alapján
    public function getUserById($id) {
        $stmt = $this->db->prepare("
            SELECT u.id, u.username, u.email, u.first_name, u.last_name, u.created_at 
            FROM user u 
            WHERE u.id = ?
        ");
        $stmt->execute([$id]);
        $user = $stmt->fetch();
        
        if ($user) {
            $user['role'] = $this->isAdmin($user['username']) ? 'admin' : 'user';
        }
        
        return $user;
    }

    // Összes felhasználó lekérése (admin számára)
    public function getAllUsers() {
        $stmt = $this->db->query("
            SELECT u.id, u.username, u.email, u.first_name, u.last_name, u.created_at 
            FROM user u 
            ORDER BY u.created_at DESC
        ");
        $users = $stmt->fetchAll();
        
        // Role hozzáadása minden felhasználóhoz
        foreach ($users as &$user) {
            $user['role'] = $this->isAdmin($user['username']) ? 'admin' : 'user';
        }
        
        return $users;
    }

    // Felhasználó lekérése felhasználónév alapján
    public function getUserByUsername($username) {
        $stmt = $this->db->prepare("
            SELECT u.id, u.username, u.email, u.first_name, u.last_name, u.created_at 
            FROM user u 
            WHERE u.username = ?
        ");
        $stmt->execute([$username]);
        $user = $stmt->fetch();
        
        if ($user) {
            $user['role'] = $this->isAdmin($user['username']) ? 'admin' : 'user';
        }
        
        return $user;
    }

    // Felhasználó adminná tétele (csak admin) - hozzáadás az admin táblához
    public function makeAdmin($userId) {
        try {
            $user = $this->getUserById($userId);
            if (!$user) {
                return ['success' => false, 'message' => 'User not found'];
            }

            // Ellenőrzés, hogy már admin-e
            if ($this->isAdmin($user['username'])) {
                return ['success' => false, 'message' => 'User is already an admin'];
            }

            // Beszúrás az admin táblába
            $stmt = $this->db->prepare("INSERT INTO admin (username, first_name, last_name, email) VALUES (?, ?, ?, ?)");
            $stmt->execute([$user['username'], $user['first_name'], $user['last_name'], $user['email']]);
            
            return ['success' => true, 'message' => 'User promoted to admin successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => 'Failed to make user admin: ' . $e->getMessage()];
        }
    }

    // Admin jog eltávolítása (csak admin) - eltávolítás az admin táblából
    public function removeAdmin($userId) {
        try {
            $user = $this->getUserById($userId);
            if (!$user) {
                return ['success' => false, 'message' => 'User not found'];
            }

            // Ellenőrzés, hogy nem admin-e
            if (!$this->isAdmin($user['username'])) {
                return ['success' => false, 'message' => 'User is not an admin'];
            }

            // Törlés az admin táblából
            $stmt = $this->db->prepare("DELETE FROM admin WHERE username = ?");
            $stmt->execute([$user['username']]);
            
            return ['success' => true, 'message' => 'Admin role removed successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => 'Failed to remove admin role: ' . $e->getMessage()];
        }
    }

    // Felhasználó role frissítése (csak admin) - kompatibilitási metódus
    public function updateUserRole($userId, $role) {
        if ($role === 'admin') {
            return $this->makeAdmin($userId);
        } else if ($role === 'user') {
            return $this->removeAdmin($userId);
        } else {
            return ['success' => false, 'message' => 'Invalid role'];
        }
    }

    // Felhasználó törlése (csak admin)
    public function deleteUser($userId) {
        try {
            $user = $this->getUserById($userId);
            if (!$user) {
                return ['success' => false, 'message' => 'User not found'];
            }

            /**
             * Az új SQL-ben található delete_user stored procedure-t használjuk,
             * ami felhasználónév alapján töröl.
             */
            $stmt = $this->db->prepare("CALL delete_user(:username)");
            $success = $stmt->execute([':username' => $user['username']]);
            $stmt->closeCursor();

            if ($success) {
                return ['success' => true, 'message' => 'User deleted successfully'];
            }
            return ['success' => false, 'message' => 'Failed to delete user'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => 'Failed to delete user: ' . $e->getMessage()];
        }
    }

    // Jelszó frissítése
    public function updatePassword($username, $newPassword) {
        if (strlen($newPassword) < 6) {
            return ['success' => false, 'message' => 'Password must be at least 6 characters'];
        }

        try {
            /**
             * Az új SQL-ben található update_password stored procedure-rel frissítjük
             * a jelszót. A procedure maga végzi a SHA2 hash-elést.
             */
            $stmt = $this->db->prepare("CALL update_password(:username, :newPass)");
            $success = $stmt->execute([
                ':username' => $username,
                ':newPass' => $newPassword
            ]);
            $stmt->closeCursor();

            if ($success) {
                return ['success' => true, 'message' => 'Password updated successfully'];
            }
            return ['success' => false, 'message' => 'Failed to update password'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => 'Failed to update password: ' . $e->getMessage()];
        }
    }
}
