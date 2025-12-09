<?php
session_start();

$dbHost = 'localhost';
$dbName = 'your_database';
$dbUser = 'your_username';
$dbPass = 'your_password';

$tableSchema = <<<SQL
-- Required table for registrations
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQL;

$errors = [];
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    $confirmPassword = $_POST['confirm_password'] ?? '';

    if (!$username || !$email || !$password || !$confirmPassword) {
        $errors[] = 'All fields are required.';
    }

    if ($password !== $confirmPassword) {
        $errors[] = 'Passwords do not match.';
    }

    if (!$errors) {
        try {
            $dsn = "mysql:host={$dbHost};dbname={$dbName};charset=utf8mb4";
            $pdo = new PDO($dsn, $dbUser, $dbPass, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]);

            $stmt = $pdo->prepare('INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)');
            $stmt->execute([
                $username,
                $email,
                password_hash($password, PASSWORD_DEFAULT),
            ]);

            $success = 'Registration successful! You can now log in.';
        } catch (PDOException $e) {
            if ($e->getCode() === '23000') {
                $errors[] = 'Username or email already exists.';
            } else {
                $errors[] = 'Database error: ' . $e->getMessage();
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f4f4f4;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
        }
        .container {
            background: #fff;
            padding: 2rem;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
            width: 100%;
            max-width: 360px;
        }
        h1 {
            margin-top: 0;
            text-align: center;
        }
        .message {
            margin-bottom: 1rem;
            padding: 0.75rem;
            border-radius: 4px;
            font-size: 0.95rem;
        }
        .error {
            background: #ffe4e4;
            color: #a10000;
        }
        .success {
            background: #e5ffe4;
            color: #047a00;
        }
        label {
            display: block;
            margin-bottom: 0.25rem;
            font-weight: bold;
        }
        input {
            width: 100%;
            padding: 0.5rem;
            margin-bottom: 1rem;
            border: 1px solid #ccc;
            border-radius: 4px;
        }
        button {
            width: 100%;
            padding: 0.6rem;
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
        textarea {
            width: 100%;
            height: 140px;
            margin-top: 1rem;
            padding: 0.75rem;
            border-radius: 4px;
            border: 1px solid #ccc;
            font-family: monospace;
            font-size: 0.85rem;
            resize: vertical;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Create Account</h1>

        <?php foreach ($errors as $error): ?>
            <div class="message error"><?php echo htmlspecialchars($error); ?></div>
        <?php endforeach; ?>

        <?php if ($success): ?>
            <div class="message success"><?php echo htmlspecialchars($success); ?></div>
        <?php endif; ?>

        <form method="POST" action="reg.php">
            <label for="username">Username</label>
            <input type="text" id="username" name="username" placeholder="Choose a username" required>

            <label for="email">Email</label>
            <input type="email" id="email" name="email" placeholder="Your email address" required>

            <label for="password">Password</label>
            <input type="password" id="password" name="password" placeholder="Create a password" required>

            <label for="confirm_password">Confirm Password</label>
            <input type="password" id="confirm_password" name="confirm_password" placeholder="Repeat the password" required>

            <button type="submit">Register</button>
        </form>

        <label for="schema">SQL table placeholder</label>
        <textarea id="schema" readonly><?php echo htmlspecialchars($tableSchema); ?></textarea>
    </div>
</body>
</html>
