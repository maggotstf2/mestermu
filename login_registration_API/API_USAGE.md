# JWT API Usage Guide

## Configuration

The JWT secret is configured in `config/config.php`. **IMPORTANT:** Change the default secret before deploying to production!

```php
define('JWT_SECRET', 'your-secret-key-change-this-in-production');
```

## API Endpoints

All endpoints accept and return JSON.

### Base URL
```
http://localhost/login_registration_API/index.php
```

### 1. Register User

**POST** `/index.php`

```json
{
  "action": "register",
  "username": "testuser",
  "email": "test@example.com",
  "password": "password123",
  "first_name": "Test",
  "last_name": "User"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "User created successfully",
  "user_id": 1
}
```

### 2. Login

**POST** `/index.php`

```json
{
  "action": "login",
  "username": "testuser",
  "password": "password123"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Sikeres bejelentkezés",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com"
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Helytelen felhasználónév vagy jelszó"
}
```

### 3. Validate Token

**POST** `/index.php`

**Option 1: Token in request body**
```json
{
  "action": "validate",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Option 2: Token in Authorization header**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "iss": "login_registration_API",
    "iat": 1234567890,
    "exp": 1234654290,
    "user_id": 1,
    "username": "testuser",
    "email": "test@example.com"
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "A token lejárt"
}
```

### 4. API Info

**GET** `/index.php`

Returns information about available endpoints.

## Testing with cURL

### Register:
POST: rendesen regiszral, GET: kiir infokat (endpointok meg ezek)
```bash
curl -X POST http://localhost/login_registration_API/index.php \ 
  -H "Content-Type: application/json" \
  -d '{
    "action": "register",
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "first_name": "Test",
    "last_name": "User"
  }'
```

### Login:
```bash
curl -X POST http://localhost/login_registration_API/index.php \
  -H "Content-Type: application/json" \
  -d '{
    "action": "login",
    "username": "testuser",
    "password": "password123"
  }'
```

### Validate Token:
```bash
curl -X POST http://localhost/login_registration_API/index.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "action": "validate"
  }'
```

## Token Details

- **Algorithm:** HS256
- **Expiration:** 24 hours from issue time
- **Payload includes:** user_id, username, email, iss, iat, exp

## Security Notes

1. Always use HTTPS in production
2. Change the JWT_SECRET to a strong, random value
3. Store tokens securely on the client side
4. Tokens expire after 24 hours - implement refresh logic if needed

