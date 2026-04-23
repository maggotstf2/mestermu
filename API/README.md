# PHP REST API - Authentication, Catalog, Orders, Reservations, and Admin

OPEN https://tormasecurity.hu FOR AN INSTANT EXPERIENCE 


This project is a PHP REST API for the Torma Security Solutions application.
It includes user authentication, role-based admin operations, product catalog endpoints, order management, reservation workflows, and documentation routing.

The API uses the `torma` MySQL database (see `API/database/torma.sql`).

## Features

- User signup and login
- JWT-based authentication
- Role-based authorization (user/admin)
- Product catalog browsing and filtering
- User order and reservation management
- Admin management for users, products, orders, and reservations
- Rate limiting for sensitive routes
- CORS support
- Quartz documentation endpoints under `/documentation`

## Project Structure

```text
API/
├── config/
│   └── config.php                # Environment and application config
├── controllers/
│   ├── AuthController.php        # Authentication and profile endpoints
│   ├── ProductController.php     # Public product endpoints
│   ├── OrderController.php       # User order endpoints
│   ├── ReservationController.php # User/public reservation endpoints
│   ├── AdminController.php       # Admin user/order/product endpoints
│   └── AdminReservationController.php # Admin reservation endpoints
├── database/
│   ├── Database.php              # Database connection wrapper
│   └── torma.sql                 # Schema, procedures, seed data
├── middleware/
│   └── AuthMiddleware.php        # Auth and admin guards
├── models/
│   ├── User.php
│   ├── Product.php
│   ├── Order.php
│   └── Reservation.php
├── utils/
│   ├── JWT.php
│   └── RateLimiter.php
├── .htaccess
├── index.php                     # Router and API entrypoint
└── README.md
```

## Requirements

- PHP 7.4+ (PHP 8.x recommended)
- MySQL 5.7+ or MariaDB 10.2+
- Apache with `mod_rewrite` (or equivalent rewrite config)
- PDO extension enabled
- JSON extension enabled

## Setup

### 1) Import the Database

```bash
mysql -u root -p < API/database/torma.sql
```

Or manually:

1. Create a database named `torma`
2. Import `API/database/torma.sql`

### 2) Configure the API

Edit `API/config/config.php` and set:

- `DB_HOST`
- `DB_NAME`
- `DB_USER`
- `DB_PASS`
- `JWT_SECRET` (use a strong random value in production)
- `JWT_EXPIRATION`
- `DEBUG_MODE`

### 3) Run the API

From the `API` directory:

```bash
php -S localhost:8000
```

Health check:

```text
GET http://localhost:8000/
```

## Authentication

Authenticated routes require:

```text
Authorization: Bearer <token>
```

## API Endpoints

### Public Authentication

- `POST /signup`
- `POST /login`

### Authenticated Profile

- `GET /profile`
- `PUT /profile/username`
- `PUT /profile/password`

### Public Product Catalog

- `GET /products`
- `GET /products/facets`
- `GET /products/all`
- `GET /products/cats`
- `GET /products/subcats`
- `GET /products/brands`
- `GET /products/tags`
- `GET /products/names`
- `GET /products/by-brand/{brandName}`
- `GET /products/{id}/brand`
- `GET /products/{id}`

`GET /products` supports optional query params:

- `cat`
- `subcat`
- `brand`
- `tag`
- `search`
- `min_price`
- `max_price`
- `page` (default: 1)
- `limit` (default: 50, max: 100)

### Orders (Authenticated)

- `POST /orders`
- `GET /orders`
- `GET /orders/{id}`
- `POST /orders/{id}/items`
- `PATCH /orders/{id}/items/{productId}`
- `PUT /orders/{id}/items/{productId}`
- `DELETE /orders/{id}`

### Reservations

Authenticated:

- `POST /reservations`
- `GET /reservations`
- `PATCH /reservations/{id}`
- `PUT /reservations/{id}`
- `DELETE /reservations/{id}`

Public:

- `POST /reservations/public`

### Admin (Admin Role Required)

Users:

- `GET /admin/users`
- `GET /admin/users/{id}`
- `PUT /admin/users/{id}/role`
- `DELETE /admin/users/{id}`

Dashboard:

- `GET /admin/dashboard`

Orders:

- `GET /admin/orders`
- `GET /admin/orders/summary`
- `GET /admin/orders/status-options`
- `PATCH /admin/orders/{id}/status`
- `PUT /admin/orders/{id}/status`

Products:

- `POST /admin/products`
- `PUT /admin/products/{id}`
- `PATCH /admin/products/{id}`
- `DELETE /admin/products/{id}`
- `PATCH /admin/products/{id}/quantity/add`

Reservations:

- `GET /admin/reservations`
- `PATCH /admin/reservations/{id}/duration`
- `PUT /admin/reservations/{id}/duration`

### Documentation Endpoints

The API serves Quartz documentation under `/documentation`.

Main routes:

- `GET /documentation`
- `GET /documentation/architecture`
- `GET /documentation/backend-api`
- `GET /documentation/database`
- `GET /documentation/frontend`
- `GET /documentation/security`
- `GET /documentation/setup`
- `GET /documentation/testing`
- `GET /documentation/tags`

Supporting static assets are also served under `/documentation/...` (CSS, JS, JSON, XML, SVG).

## Example Requests

### Signup

```bash
curl -X POST http://localhost:8000/signup \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'
```

### Login

```bash
curl -X POST http://localhost:8000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
```

### Get Profile

```bash
curl -X GET http://localhost:8000/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### List Products

```bash
curl -X GET "http://localhost:8000/products?cat=CCTV&search=camera&limit=10"
```

### Get Admin Users

```bash
curl -X GET http://localhost:8000/admin/users \
  -H "Authorization: Bearer ADMIN_TOKEN_HERE"
```

## Default Admin Account

Based on the current `torma.sql` seed data:

- Username: `john_doe`
- Email: `john@example.com`
- Password: `password123`

For any non-local environment, change this password immediately.

## Security Notes

- JWT token auth is used for protected endpoints.
- Authorization is role-based for admin routes.
- SQL access uses PDO and parameterized/procedure-based calls.
- Rate limiting is applied to sensitive actions (for example login/signup/admin mutations).
- CORS headers are configured in `index.php`.

## Configuration Reference

Key values in `API/config/config.php`:

- `DB_HOST`: Database host
- `DB_NAME`: Database name
- `DB_USER`: Database username
- `DB_PASS`: Database password
- `JWT_SECRET`: JWT signing secret
- `JWT_EXPIRATION`: Token lifetime in seconds
- `DEBUG_MODE`: Enables/disables detailed error output
## PHP REST API - Signup/Login with Admin Panel

Egy komplett PHP REST API alkalmazás felhasználó-regisztrációval, bejelentkezéssel, JWT tokenekkel és admin felülettel. Ez az API a `torma` adatbázist használja (lásd `database/torma.sql` dump).

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
│   └── config.php          # Configuration settings (DB: torma)
├── controllers/
│   ├── AuthController.php     # Authentication endpoints
│   ├── AdminController.php    # Admin panel + product admin endpoints
│   └── ProductController.php  # Public product catalog endpoints
├── database/
│   ├── Database.php        # Database connection (Singleton)
│   └── torma.sql           # Database schema & dump
├── middleware/
│   └── AuthMiddleware.php  # Authentication & authorization middleware
├── models/
│   ├── User.php               # User model with business logic
│   └── Product.php            # Product catalog model
├── utils/
│   └── JWT.php             # JWT token generation and verification
├── .htaccess               # Apache rewrite rules
├── index.php               # Main router and entry point
└── README.md               # This file
```

## Installation

### 1. Database Setup

1. Importáld az adatbázis sémát és mintadatokat:
```bash
mysql -u root -p < API/database/torma.sql
```

Vagy manuálisan:
- Hozz létre egy adatbázist `torma` néven
- Importáld az `API/database/torma.sql` fájlt

### 2. Configuration

Edit `API/config/config.php` and update:
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

### Orders Endpoints (Require Authentication)

#### Create Order
```
POST /orders
Authorization: Bearer {token}
```

#### List My Orders
```
GET /orders
Authorization: Bearer {token}
```

#### Get Order Details (items)
```
GET /orders/{id}
Authorization: Bearer {token}
```

#### Add Order Item
```
POST /orders/{id}/items
Authorization: Bearer {token}
Content-Type: application/json

{
  "product_id": 13,
  "quantity": 2
}
```

#### Update Order Item Quantity
```
PATCH /orders/{id}/items/{productId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "quantity": 3
}
```

#### Delete My Order
```
DELETE /orders/{id}
Authorization: Bearer {token}
```

### Reservations Endpoints (Require Authentication)

#### Create Reservation
```
POST /reservations
Authorization: Bearer {token}
Content-Type: application/json

{
  "message": "Szeretnék egyeztetni",
  "reservation_date": "2026-03-10 10:30:00",
  "location": "Telephelyen",
  "service": "Riasztórdsz. konzultáció"
}
```

#### List My Reservations
```
GET /reservations
Authorization: Bearer {token}
```

#### Update Reservation
```
PATCH /reservations/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "message": "Módosított szöveg",
  "reservation_date": "2026-03-10 11:00:00",
  "location": "Telefonos egyeztetés",
  "service": "Kamerardsz. felmérés"
}
```

#### Delete Reservation
```
DELETE /reservations/{id}
Authorization: Bearer {token}
```

### Public Product Catalog Endpoints

#### List Products
```
GET /products

Query paraméterek (mind opcionális):
- cat: kategória (pl. "CCTV")
- subcat: alkategória (pl. "Kamerák")
- brand: márka (pl. "Hikvision")
- tag: tag1/tag2 alapján szűrés (pl. "Professzionális")
- search: szöveges keresés a névben/leírásban
- min_price, max_price: ár intervallum (int)
- page: lapozás (alap: 1)
- limit: elemszám / oldal (alap: 50, max: 100)
```

Példa:
```bash
curl -X GET "http://localhost:8000/products?cat=CCTV&search=kamera&limit=10"
```

#### Get Product by ID
```
GET /products/{id}
```

Példa:
```bash
curl -X GET http://localhost:8000/products/1
```

#### Get Product Facets (filters)
```
GET /products/facets
```

Válaszban:
- categories, subcategories, brands, tags

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

#### Create Product
```
POST /admin/products
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "name": "Demo termék",
  "brand": "Generic",
  "cat": "CCTV",
  "subcat": "Kamerák",
  "tag1": "Beltéri",
  "tag2": "Professzionális",
  "price": 12345,
  "quantity": 10,
  "description": "Demo termék leírása",
  "is_bundled": 0      // opcionális, default: 0
}
```

#### Update Product
```
PUT /admin/products/{id}
PATCH /admin/products/{id}
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "price": 15000,
  "quantity": 5
}
```

#### Delete Product
```
DELETE /admin/products/{id}
Authorization: Bearer {admin_token}
```

#### Update Product Quantity
```
PATCH /admin/products/{id}/quantity
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "quantity": 25
}
```

#### Update Reservation Duration (admin)
```
PATCH /admin/reservations/{id}/duration
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "duration": "01:30:00"
}
```

## Default Admin Account

Az aktuális `torma.sql` dump alapján az admin jogosultságú felhasználó:
- **Username:** `john_doe`
- **Email:** `john@example.com`
- **Password:** `password123` (SHA2-vel hashelve az adatbázisban)

⚠️ **FONTOS:** éles környezetben ezt a jelszót azonnal módosítsd!

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

1. **Password Hashing**: A jelszavak az adatbázisban definiált stored procedure-ök (pl. `createUser`, `authUser`, `updatePassword`) segítségével kerülnek SHA2-256 hash-elésre.
2. **JWT Tokens**: Secure token-based authentication
3. **SQL Injection Prevention**: Uses PDO prepared statements és tárolt eljárások
4. **Input Validation**: Validates email format, password length, etc.
5. **Role-Based Access Control**: Admin-only endpoints protected by middleware
6. **Rate Limiting**:
   - Login: max 5 próbálkozás / 5 perc / IP (429 után várakozás szükséges)
   - Signup: max 20 regisztráció / óra / IP
   - Admin műveletek: külön limitálva admin felhasználónként (pl. max 60–300 módosítás / óra)
7. **CORS Support**: Configurable CORS headers

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