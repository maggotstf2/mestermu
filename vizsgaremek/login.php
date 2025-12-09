<?php
session_start();

$dbHost = 'localhost';
$dbName = 'your_database';
$dbUser = 'your_username';
$dbPass = 'your_password';

$response = [
    'authenticated' => false,
    'message' => '',
    'user' => null,
];

$pdo = null;
try {
    $dsn = "mysql:host={$dbHost};dbname={$dbName};charset=utf8mb4";
    $pdo = new PDO($dsn, $dbUser, $dbPass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException $e) {
    $response['message'] = 'Database connection failed.';
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['logout'])) {
        session_destroy();
        $response['message'] = 'Logged out successfully.';
    } else {
        $username = trim($_POST['username'] ?? '');
        $password = trim($_POST['password'] ?? '');

        if (!$username || !$password) {
            $response['message'] = 'Both username and password are required.';
        } elseif (!$pdo) {
            $response['message'] = 'Cannot verify credentials right now.';
        } else {
            $stmt = $pdo->prepare('SELECT id, username, password_hash FROM users WHERE username = ?');
            $stmt->execute([$username]);
            $userRow = $stmt->fetch();

            if (!$userRow || !password_verify($password, $userRow['password_hash'])) {
                $response['message'] = 'Invalid username or password.';
            } else {
                $_SESSION['user'] = $userRow['username'];
                $response['authenticated'] = true;
                $response['message'] = 'Login successful.';
                $response['user'] = $userRow['username'];
            }
        }
    }
} elseif (isset($_SESSION['user'])) {
    $response['authenticated'] = true;
    $response['message'] = 'Already logged in.';
    $response['user'] = $_SESSION['user'];
} else {
    $response['message'] = 'Submit username and password via POST.';
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' || isset($_GET['json'])) {
    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Tester</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #eef2f7;
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .panel {
            background: #fff;
            padding: 2rem;
            border-radius: 8px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.08);
            width: 100%;
            max-width: 360px;
        }
        h1 {
            margin-top: 0;
            text-align: center;
            font-size: 1.4rem;
        }
        label {
            display: block;
            margin-bottom: 0.25rem;
            font-weight: bold;
            font-size: 0.9rem;
        }
        input {
            width: 100%;
            padding: 0.55rem;
            margin-bottom: 0.9rem;
            border-radius: 4px;
            border: 1px solid #cdd5e0;
            font-size: 0.95rem;
        }
        button {
            width: 100%;
            padding: 0.65rem;
            border: none;
            border-radius: 4px;
            background: #0073e6;
            color: #fff;
            font-size: 1rem;
            cursor: pointer;
        }
        button:hover {
            background: #005bb5;
        }
        pre {
            background: #0f172a;
            color: #e2e8f0;
            padding: 0.75rem;
            border-radius: 6px;
            font-size: 0.85rem;
            overflow-x: auto;
        }
        .hint {
            font-size: 0.8rem;
            color: #64748b;
            text-align: center;
            margin-bottom: 1rem;
        }
    </style>
</head>
<body>
    <div class="panel">
        <h1>Login Tester</h1>
        <p class="hint">Use credentials stored in the placeholder users table.</p>
        <form id="loginForm">
            <label for="username">Username</label>
            <input type="text" id="username" name="username" required>

            <label for="password">Password</label>
            <input type="password" id="password" name="password" required>

            <button type="submit">Send Login Request</button>
        </form>
        <pre id="output"><?php echo htmlspecialchars(json_encode($response, JSON_PRETTY_PRINT)); ?></pre>
    </div>

    <script>
        const form = document.getElementById('loginForm');
        const output = document.getElementById('output');

        form.addEventListener('submit', async (event) => {
            event.preventDefault();
            const formData = new FormData(form);

            const res = await fetch('login.php', {
                method: 'POST',
                body: formData
            });
            const data = await res.json();
            output.textContent = JSON.stringify(data, null, 2);
        });
    </script>
</body>
</html>