<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
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
            text-align: center;
        }
        h1 {
            margin-top: 0;
        }
        a {
            display: inline-block;
            margin: 0.5rem;
            padding: 0.75rem 1.5rem;
            border-radius: 4px;
            text-decoration: none;
            background: #0073e6;
            color: #fff;
        }
        a:hover {
            background: #005bb5;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Choose an action</h1>
        <p>Use the links below to log in or register.</p>
        <a href="login.php">Go to Login</a>
        <a href="reg.php">Go to Registration</a>
    </div>
</body>
</html>
