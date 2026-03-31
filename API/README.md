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
- in_stock_only: 1 vagy 0 (alapértelmezés: 1 = csak készleten lévő)
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
  "in_stock": 1,       // opcionális, default: 1
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
  "quantity": 5,
  "in_stock": 1
}
```

#### Delete Product
```
DELETE /admin/products/{id}
Authorization: Bearer {admin_token}
```

#### Set Product Out of Stock
```
PATCH /admin/products/{id}/stock/out
Authorization: Bearer {admin_token}
```

#### Set Product Back In Stock
```
PATCH /admin/products/{id}/stock/in
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

## License

This project is open source and available for educational purposes.

## Notes

- This is a basic implementation suitable for learning and small projects
- For production use, consider:
  - Fine-tuning rate limiting rules per endpoint
  - Implementing refresh tokens
  - Adding email verification
  - Using HTTPS only
  - Implementing proper logging
  - Adding input sanitization beyond what's included
  - Database connection pooling for high traffic
