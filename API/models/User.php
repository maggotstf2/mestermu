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

        // Felhasználó létrehozása az adatbázisban definiált createUser stored procedure-rel
        try {
            /**
             * A torma.sql-ben definiált createUser procedure a következőt végzi:
             *  - beszúrja a user rekordot (username, email, first_name, last_name)
             *  - beszúrja a user_secret rekordot SHA2-vel hash-elt jelszóval
             *
             * Paraméterek sorrendje:
             *  (pUsername, pPassword, pEmail, pFirstname, pLastname)
             */
            $stmt = $this->db->prepare("CALL createUser(:username, :password, :email, :first_name, :last_name)");
            $stmt->execute([
                ':username'   => $username,
                ':password'   => $password,   // a procedure végzi a hash-elést
                ':email'      => $email,
                ':first_name' => $firstName,
                ':last_name'  => $lastName,
            ]);

            // Fölösleges result set-ek lezárása
            $stmt->closeCursor();

            // A procedure több INSERT-et végez, ezért a lastInsertId nem megbízható a user táblára.
            // Biztonságosabb újra lekérdezni a létrehozott felhasználót felhasználónév alapján.
            $user = $this->getUserByUsername($username);
            $userId = $user ? $user['id'] : null;

            return [
                'success' => true,
                'message' => 'User created successfully',
                'user_id' => $userId
            ];
        } catch (PDOException $e) {
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
            $stmt = $this->db->prepare("CALL authUser(:username, :password)");
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
        /**
         * Az adatbázisban definiált isAdmin() függvényt használjuk, amely a user.role
         * mező alapján dönti el, hogy admin-e az adott felhasználó.
         */
        $stmt = $this->db->prepare("SELECT isAdmin(:username) AS is_admin");
        $stmt->execute([':username' => $username]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row && (int)$row['is_admin'] === 1;
    }

    // Felhasználó lekérése ID alapján
    public function getUserById($id) {
        try {
            /**
             * A torma.sql-ben definiált getUserById stored procedure a következő
             * mezőket adja vissza: id, username, first_name, last_name, role, created_at.
             * Az email mezőt külön lekérdezzük, hogy a meglévő visszatérési struktúrát
             * megtartsuk.
             */
            $stmt = $this->db->prepare("CALL getUserById(:id)");
            $stmt->execute([':id' => $id]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();

            if ($user) {
                $emailStmt = $this->db->prepare("SELECT email FROM user WHERE id = :id");
                $emailStmt->execute([':id' => $id]);
                $emailRow = $emailStmt->fetch(PDO::FETCH_ASSOC);
                $user['email'] = $emailRow ? $emailRow['email'] : null;
            }

            return $user;
        } catch (PDOException $e) {
            return null;
        }
    }

    // Összes felhasználó lekérése (admin számára)
    public function getAllUsers() {
        try {
            /**
             * A getAllUsers stored procedure az alábbi mezőket adja vissza:
             *  id, username, first_name, last_name, role, created_at
             * Az email címeket külön kérdezzük le, hogy kompatibilisek maradjunk
             * a korábbi visszatérési struktúrával.
             */
            $stmt = $this->db->prepare("CALL getAllUsers()");
            $stmt->execute();
            $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $stmt->closeCursor();

            if (!$users) {
                return [];
            }

            $ids = array_column($users, 'id');
            if (!empty($ids)) {
                $placeholders = implode(',', array_fill(0, count($ids), '?'));
                $emailStmt = $this->db->prepare("SELECT id, email FROM user WHERE id IN ($placeholders)");
                $emailStmt->execute($ids);
                $emails = [];
                while ($row = $emailStmt->fetch(PDO::FETCH_ASSOC)) {
                    $emails[$row['id']] = $row['email'];
                }

                foreach ($users as &$user) {
                    $user['email'] = $emails[$user['id']] ?? null;
                }
            }

            return $users;
        } catch (PDOException $e) {
            return [];
        }
    }

    // Felhasználó lekérése felhasználónév alapján
    public function getUserByUsername($username) {
        try {
            /**
             * A getUserByUsername stored procedure az alábbi mezőket adja vissza:
             *  id, username, first_name, last_name, role, created_at
             * Az email mezőt külön lekérdezzük.
             */
            $stmt = $this->db->prepare("CALL getUserByUsername(:username)");
            $stmt->execute([':username' => $username]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            $stmt->closeCursor();

            if ($user) {
                $emailStmt = $this->db->prepare("SELECT email FROM user WHERE username = :username");
                $emailStmt->execute([':username' => $username]);
                $emailRow = $emailStmt->fetch(PDO::FETCH_ASSOC);
                $user['email'] = $emailRow ? $emailRow['email'] : null;
            }

            return $user;
        } catch (PDOException $e) {
            return null;
        }
    }

    // Felhasználó adminná tétele (csak admin) - hozzáadás az admin táblához
    public function makeAdmin($userId) {
        try {
            $user = $this->getUserById($userId);
            if (!$user) {
                return ['success' => false, 'message' => 'User not found'];
            }

            // Ellenőrzés, hogy már admin-e (adatbázis függvénnyel)
            if ($this->isAdmin($user['username'])) {
                return ['success' => false, 'message' => 'User is already an admin'];
            }

            /**
             * A setAdminStatus stored procedure az id és egy logikai flag alapján
             * frissíti a user.role mezőt (admin / user).
             *  - pId: felhasználó ID
             *  - pStatus: 1 => admin, 0 => user
             */
            $stmt = $this->db->prepare("CALL setAdminStatus(:id, :status)");
            $stmt->execute([
                ':id'     => $userId,
                ':status' => 1,
            ]);
            $stmt->closeCursor();
            
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

            // Ellenőrzés, hogy jelenleg admin-e
            if (!$this->isAdmin($user['username'])) {
                return ['success' => false, 'message' => 'User is not an admin'];
            }

            // setAdminStatus procedure segítségével visszaállítjuk "user" szerepkörre
            $stmt = $this->db->prepare("CALL setAdminStatus(:id, :status)");
            $stmt->execute([
                ':id'     => $userId,
                ':status' => 0,
            ]);
            $stmt->closeCursor();
            
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
            $stmt = $this->db->prepare("CALL deleteUser(:username)");
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
            $stmt = $this->db->prepare("CALL updatePassword(:username, :newPass)");
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

    // Felhasználónév frissítése (user + user_secret)
    public function updateUsername(int $userId, string $currentUsername, string $newUsername): array {
        $newUsername = trim($newUsername);

        if ($newUsername === '') {
            return ['success' => false, 'message' => 'Username cannot be empty'];
        }

        if ($newUsername === $currentUsername) {
            return ['success' => true, 'message' => 'Username is unchanged'];
        }

        if (strlen($newUsername) > 32) {
            return ['success' => false, 'message' => 'Username is too long'];
        }

        // Ellenőrizzük, hogy a cél username már foglalt-e.
        $stmt = $this->db->prepare("SELECT id FROM user WHERE username = :username LIMIT 1");
        $stmt->execute([':username' => $newUsername]);
        $exists = $stmt->fetch(PDO::FETCH_ASSOC);
        $stmt->closeCursor();

        if ($exists) {
            return ['success' => false, 'message' => 'Username already exists'];
        }

        try {
            /**
             * Egyetlen UPDATE-ben frissítjük a user.username és user_secret.username értékeket,
             * hogy a foreign key constraint ne sérüljön átmenetileg.
             */
            $stmt = $this->db->prepare("
                UPDATE user u
                JOIN user_secret us ON us.username = u.username
                SET u.username = :newUsername,
                    us.username = :newUsername
                WHERE u.id = :userId AND u.username = :currentUsername
            ");

            $ok = $stmt->execute([
                ':newUsername' => $newUsername,
                ':userId' => $userId,
                ':currentUsername' => $currentUsername
            ]);

            $stmt->closeCursor();

            if (!$ok) {
                return ['success' => false, 'message' => 'Failed to update username'];
            }

            $user = $this->getUserById($userId);
            if (!$user) {
                return ['success' => false, 'message' => 'User not found after update'];
            }

            return [
                'success' => true,
                'message' => 'Username updated successfully',
                'user' => $user
            ];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => 'Failed to update username: ' . $e->getMessage()];
        }
    }
}
