<?php
require_once __DIR__ . '/../models/Reservation.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';

class AdminReservationController {
    private $reservationModel;

    public function __construct() {
        $this->reservationModel = new Reservation();
    }

    // Admin: időtartam megadása foglaláshoz
    public function list() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        AuthMiddleware::requireAdmin();
        $reservations = $this->reservationModel->getAllReservationsAdmin();

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'reservations' => $reservations,
            'count' => count($reservations)
        ]);
    }

    // Admin: reservation duration update
    public function updateDuration($reservationId) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'PATCH' && $_SERVER['REQUEST_METHOD'] !== 'PUT') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        AuthMiddleware::requireAdmin();

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        if (!isset($data['duration'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'duration is required (HH:MM:SS)']);
            return;
        }

        $result = $this->reservationModel->updateReservationDurationAdmin((int)$reservationId, (string)$data['duration']);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }
}

