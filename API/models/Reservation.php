<?php
require_once __DIR__ . '/../database/Database.php';

class Reservation {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function createReservation(array $data, ?string $username): array {
        $required = ['service', 'reservation_date', 'reservation_time', 'location', 'name', 'phone', 'email'];
        foreach ($required as $field) {
            if (!isset($data[$field]) || $data[$field] === '') {
                return ['success' => false, 'message' => "Field '{$field}' is required"];
            }
        }

        try {
            $stmt = $this->db->prepare("
                CALL createReservation(
                    :service,
                    :reservation_date,
                    :reservation_time,
                    :location,
                    :name,
                    :phone,
                    :email,
                    :note,
                    :username
                )
            ");
            $stmt->execute([
                ':service' => $data['service'],
                ':reservation_date' => $data['reservation_date'],
                ':reservation_time' => $data['reservation_time'],
                ':location' => $data['location'],
                ':name' => $data['name'],
                ':phone' => $data['phone'],
                ':email' => $data['email'],
                ':note' => $data['note'] ?? null,
                ':username' => $username
            ]);
            $stmt->closeCursor();

            return ['success' => true, 'message' => 'Reservation created successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function createReservationPublic(array $data): array {
        $required = ['service', 'reservation_date', 'reservation_time', 'location', 'name', 'phone', 'email'];
        foreach ($required as $field) {
            if (!isset($data[$field]) || $data[$field] === '') {
                return ['success' => false, 'message' => "Field '{$field}' is required"];
            }
        }

        try {
            $stmt = $this->db->prepare("
                CALL createReservationPublic(
                    :service,
                    :reservation_date,
                    :reservation_time,
                    :location,
                    :name,
                    :phone,
                    :email,
                    :note
                )
            ");
            $stmt->execute([
                ':service' => $data['service'],
                ':reservation_date' => $data['reservation_date'],
                ':reservation_time' => $data['reservation_time'],
                ':location' => $data['location'],
                ':name' => $data['name'],
                ':phone' => $data['phone'],
                ':email' => $data['email'],
                ':note' => $data['note'] ?? null,
            ]);
            $stmt->closeCursor();

            return ['success' => true, 'message' => 'Reservation created successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function getUserReservations(string $username): array {
        try {
            $stmt = $this->db->prepare("CALL getUserReservations(:username)");
            $stmt->execute([':username' => $username]);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $stmt->closeCursor();

            return $rows ?: [];
        } catch (PDOException $e) {
            return [];
        }
    }

    public function updateReservation(int $id, array $data, string $username): array {
        if (!$this->userOwnsReservation($id, $username)) {
            return ['success' => false, 'message' => 'Reservation not found'];
        }

        $required = ['service', 'reservation_date', 'reservation_time', 'location', 'name', 'phone', 'email'];
        foreach ($required as $field) {
            if (!isset($data[$field]) || $data[$field] === '') {
                return ['success' => false, 'message' => "Field '{$field}' is required"];
            }
        }

        try {
            $stmt = $this->db->prepare("
                CALL updateReservation(
                    :id,
                    :service,
                    :reservation_date,
                    :reservation_time,
                    :location,
                    :name,
                    :phone,
                    :email,
                    :note
                )
            ");
            $stmt->execute([
                ':id' => $id,
                ':service' => $data['service'],
                ':reservation_date' => $data['reservation_date'],
                ':reservation_time' => $data['reservation_time'],
                ':location' => $data['location'],
                ':name' => $data['name'],
                ':phone' => $data['phone'],
                ':email' => $data['email'],
                ':note' => $data['note'] ?? null
            ]);
            $stmt->closeCursor();

            return ['success' => true, 'message' => 'Reservation updated successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function deleteReservation(int $id, string $username): array {
        if (!$this->userOwnsReservation($id, $username)) {
            return ['success' => false, 'message' => 'Reservation not found'];
        }

        try {
            $stmt = $this->db->prepare("CALL deleteReservation(:id)");
            $stmt->execute([':id' => $id]);
            $stmt->closeCursor();

            return ['success' => true, 'message' => 'Reservation deleted successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function updateReservationDurationAdmin(int $id, string $duration): array {
        try {
            $stmt = $this->db->prepare("CALL updateReservationDuration(:id, :duration)");
            $stmt->execute([
                ':id' => $id,
                ':duration' => $duration
            ]);
            $stmt->closeCursor();

            return ['success' => true, 'message' => 'Reservation duration updated successfully'];
        } catch (PDOException $e) {
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    private function userOwnsReservation(int $reservationId, string $username): bool {
        $stmt = $this->db->prepare(
            "SELECT 1
             FROM reservations r
             JOIN user u ON r.user_id = u.id
             WHERE r.id = :res_id AND u.username = :username
             LIMIT 1"
        );
        $stmt->execute([
            ':res_id' => $reservationId,
            ':username' => $username
        ]);
        return (bool)$stmt->fetchColumn();
    }
}

