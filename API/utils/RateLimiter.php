<?php
require_once __DIR__ . '/../database/Database.php';

class RateLimiter {
    private const TABLE_NAME = 'rate_limits';

    public static function getClientIp(): string {
        if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $parts = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
            return trim($parts[0]);
        }
        if (!empty($_SERVER['REMOTE_ADDR'])) {
            return $_SERVER['REMOTE_ADDR'];
        }
        return 'unknown';
    }

    public static function throttleOrFail(string $scope, string $identifier, int $maxAttempts, int $windowSeconds): void {
        $allowed = self::check($scope, $identifier, $maxAttempts, $windowSeconds);

        if (!$allowed) {
            http_response_code(429);
            header('Content-Type: application/json');
            header('Retry-After: ' . $windowSeconds);
            echo json_encode([
                'success' => false,
                'message' => 'Too many requests. Please try again later.'
            ]);
            exit;
        }
    }

    private static function check(string $scope, string $identifier, int $maxAttempts, int $windowSeconds): bool {
        $db = Database::getInstance()->getConnection();
        $key = $scope . ':' . $identifier;
        $now = time();
        $windowStart = $now - $windowSeconds;

        self::ensureTableExists($db);

        $db->beginTransaction();

        try {
            $stmt = $db->prepare("SELECT id, hits, last_hit FROM " . self::TABLE_NAME . " WHERE rate_key = :rate_key FOR UPDATE");
            $stmt->execute([':rate_key' => $key]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($row) {
                $hits = (int)$row['hits'];
                $lastHit = (int)$row['last_hit'];

                if ($lastHit < $windowStart) {
                    $hits = 0;
                }

                if ($hits >= $maxAttempts) {
                    $db->commit();
                    return false;
                }

                $hits++;
                $update = $db->prepare("UPDATE " . self::TABLE_NAME . " SET hits = :hits, last_hit = :last_hit WHERE id = :id");
                $update->execute([
                    ':hits' => $hits,
                    ':last_hit' => $now,
                    ':id' => $row['id']
                ]);
            } else {
                $insert = $db->prepare("INSERT INTO " . self::TABLE_NAME . " (rate_key, hits, last_hit) VALUES (:rate_key, :hits, :last_hit)");
                $insert->execute([
                    ':rate_key' => $key,
                    ':hits' => 1,
                    ':last_hit' => $now
                ]);
            }

            $db->commit();
            return true;
        } catch (PDOException $e) {
            $db->rollBack();
            return true;
        }
    }

    private static function ensureTableExists(PDO $db): void {
        static $initialized = false;
        if ($initialized) {
            return;
        }

        $sql = "
            CREATE TABLE IF NOT EXISTS " . self::TABLE_NAME . " (
                id INT(12) NOT NULL AUTO_INCREMENT,
                rate_key VARCHAR(255) NOT NULL,
                hits INT(11) NOT NULL,
                last_hit INT(11) NOT NULL,
                PRIMARY KEY (id),
                UNIQUE KEY uniq_rate_key (rate_key)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
        ";

        $db->exec($sql);
        $initialized = true;
    }
}

