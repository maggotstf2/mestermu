<?php
require_once __DIR__ . '/../models/Reservation.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';

class ReservationController {
    private $reservationModel;

    public function __construct() {
        $this->reservationModel = new Reservation();
    }

    // Foglalás létrehozása (auth)
    public function create() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        $result = $this->reservationModel->createReservation($data, $payload['username']);

        if ($result['success']) {
            http_response_code(201);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Saját foglalások listája (auth)
    public function list() {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();
        $reservations = $this->reservationModel->getUserReservations($payload['username']);

        http_response_code(200);
        echo json_encode([
            'success' => true,
            'reservations' => $reservations,
            'count' => count($reservations)
        ]);
    }

    // Foglalás módosítása (auth, csak saját)
    public function update($reservationId) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'PATCH') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            $data = $_POST;
        }

        $result = $this->reservationModel->updateReservation((int)$reservationId, $data, $payload['username']);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }

    // Foglalás törlése (auth, csak saját)
    public function delete($reservationId) {
        header('Content-Type: application/json');

        if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            return;
        }

        $payload = AuthMiddleware::authenticate();
        $result = $this->reservationModel->deleteReservation((int)$reservationId, $payload['username']);

        if ($result['success']) {
            http_response_code(200);
            echo json_encode($result);
        } else {
            http_response_code(400);
            echo json_encode($result);
        }
    }
}

