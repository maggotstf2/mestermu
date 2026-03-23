<?php
require_once __DIR__ . '/../database/Database.php';

class Reservation {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function createReservation(array $data, string $username): array {
        $required = ['message', 'reservation_date', 'location', 'service'];
        foreach ($required as $field) {
            if (!isset($data[$field]) || $data[$field] === '') {
                return ['success' => false, 'message' => "Field '{$field}' is required"];
            }
        }

        try {
            $stmt = $this->db->prepare("CALL createReservation(:message, :reservation_date, :location, :service, :username)");
            $stmt->execute([
                ':message' => $data['message'],
                ':reservation_date' => $data['reservation_date'],
                ':location' => $data['location'],
                ':service' => $data['service'],
                ':username' => $username
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

        $required = ['message', 'reservation_date', 'location', 'service'];
        foreach ($required as $field) {
            if (!isset($data[$field]) || $data[$field] === '') {
                return ['success' => false, 'message' => "Field '{$field}' is required"];
            }
        }

        try {
            $stmt = $this->db->prepare("CALL updateReservation(:id, :message, :reservation_date, :location, :service)");
            $stmt->execute([
                ':id' => $id,
                ':message' => $data['message'],
                ':reservation_date' => $data['reservation_date'],
                ':location' => $data['location'],
                ':service' => $data['service']
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

