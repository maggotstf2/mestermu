---
title: Backend API
---

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
