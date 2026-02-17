# PHP REST API - Signup/Login with Admin Panel

A complete PHP REST API application with user authentication, password hashing, JWT tokens, and an admin panel.

## Features

- ✅ User signup with validation
- ✅ User login with JWT authentication
- ✅ Password hashing using PHP's `password_hash()` (bcrypt)
- ✅ JWT token-based authentication
- ✅ Admin panel with user management
- ✅ RESTful API endpoints
- ✅ CORS support
- ✅ Secure password storage

## Project Structure

```
api/
├── config/
│   └── config.php          # Configuration settings
├── controllers/
│   ├── AuthController.php  # Authentication endpoints
│   └── AdminController.php # Admin panel endpoints
├── database/
│   ├── Database.php        # Database connection (Singleton)
│   └── schema.sql          # Database schema
├── middleware/
│   └── AuthMiddleware.php  # Authentication & authorization middleware
├── models/
│   └── User.php            # User model with business logic
├── utils/
│   └── JWT.php             # JWT token generation and verification
├── .htaccess               # Apache rewrite rules
├── index.php               # Main router and entry point
└── README.md               # This file
```

## Installation

### 1. Database Setup

1. Import the database schema:
```bash
mysql -u root -p < api/database/schema.sql
```

Or manually:
- Create a database named `auth_api_db`
- Import `api/database/schema.sql`

### 2. Configuration

Edit `api/config/config.php` and update:
- Database credentials (DB_HOST, DB_NAME, DB_USER, DB_PASS)
- JWT_SECRET (change this to a secure random string in production!)

### 3. Web Server Setup

#### Apache
Ensure mod_rewrite is enabled. The `.htaccess` file is already configured.

#### PHP Built-in Server (for development)
```bash
cd api
php -S localhost:8000
```

## API Endpoints

### Public Endpoints

#### Signup
```
POST /signup
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "password123"
}
```

#### Login
```
POST /login
Content-Type: application/json

{
  "username": "john_doe",
  "password": "password123"
}

Response:
{
  "success": true,
  "message": "Login successful",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "role": "user"
  }
}
```

### Protected Endpoints (Require Authentication)

#### Get Current User Profile
```
GET /profile
Authorization: Bearer {token}
```

### Admin Endpoints (Require Admin Role)

#### Get All Users
```
GET /admin/users
Authorization: Bearer {admin_token}
```

#### Get User by ID
```
GET /admin/users/{id}
Authorization: Bearer {admin_token}
```

#### Update User Role
```
PUT /admin/users/{id}/role
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "role": "admin"
}
```

#### Delete User
```
DELETE /admin/users/{id}
Authorization: Bearer {admin_token}
```

#### Admin Dashboard
```
GET /admin/dashboard
Authorization: Bearer {admin_token}
```

## Default Admin Account

After importing the schema, a default admin account is created:
- **Username:** `admin`
- **Email:** `admin@example.com`
- **Password:** `admin123`

⚠️ **IMPORTANT:** Change this password immediately after first login!

## Example Usage

### Using cURL

#### Signup
```bash
curl -X POST http://localhost:8000/signup \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'
```

#### Login
```bash
curl -X POST http://localhost:8000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
```

#### Get Profile (with token)
```bash
curl -X GET http://localhost:8000/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Admin - Get All Users
```bash
curl -X GET http://localhost:8000/admin/users \
  -H "Authorization: Bearer ADMIN_TOKEN_HERE"
```

### Using JavaScript (Fetch API)

```javascript
// Login
fetch('http://localhost:8000/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    username: 'testuser',
    password: 'password123'
  })
})
.then(response => response.json())
.then(data => {
  console.log('Token:', data.token);
  localStorage.setItem('token', data.token);
});

// Get Profile
const token = localStorage.getItem('token');
fetch('http://localhost:8000/profile', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
})
.then(response => response.json())
.then(data => console.log(data));
```

## Security Features

1. **Password Hashing**: Uses PHP's `password_hash()` with bcrypt algorithm
2. **JWT Tokens**: Secure token-based authentication
3. **SQL Injection Prevention**: Uses PDO prepared statements
4. **Input Validation**: Validates email format, password length, etc.
5. **Role-Based Access Control**: Admin-only endpoints protected by middleware
6. **CORS Support**: Configurable CORS headers

## Requirements

- PHP 7.4+ (recommended: PHP 8.0+)
- MySQL 5.7+ or MariaDB 10.2+
- Apache with mod_rewrite (or Nginx with rewrite rules)
- PDO extension enabled
- JSON extension enabled

## Configuration Options

Edit `api/config/config.php`:

- `DB_HOST`: Database host (default: localhost)
- `DB_NAME`: Database name (default: auth_api_db)
- `DB_USER`: Database username
- `DB_PASS`: Database password
- `JWT_SECRET`: Secret key for JWT signing (change in production!)
- `JWT_EXPIRATION`: Token expiration time in seconds (default: 3600 = 1 hour)
- `DEBUG_MODE`: Enable/disable error reporting

## License

This project is open source and available for educational purposes.

## Notes

- This is a basic implementation suitable for learning and small projects
- For production use, consider:
  - Adding rate limiting
  - Implementing refresh tokens
  - Adding email verification
  - Using HTTPS only
  - Implementing proper logging
  - Adding input sanitization beyond what's included
  - Database connection pooling for high traffic
