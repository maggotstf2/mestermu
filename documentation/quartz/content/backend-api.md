---
title: Backend API
---

The backend is a PHP REST API rooted at `API/index.php` with route-to-controller dispatch and JSON responses.

## Request Lifecycle

1. CORS headers and preflight are handled in `index.php`
2. Route matching is performed by the local `Router` class
3. Controllers validate input and call models
4. Models call MySQL procedures/queries via PDO
5. Responses are returned as JSON with HTTP status codes

## Authentication and Profile Endpoints

- `POST /signup`
- `POST /login`
- `GET /profile`
- `PUT /profile/username`
- `PUT /profile/password`

Controller: `API/controllers/AuthController.php`  
Model: `API/models/User.php`

## Product Catalog Endpoints

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

Controller: `API/controllers/ProductController.php`  
Model: `API/models/Product.php`

## Order Endpoints (Authenticated)

- `POST /orders`
- `GET /orders`
- `GET /orders/{id}`
- `POST /orders/{id}/items`
- `PATCH|PUT /orders/{id}/items/{productId}`
- `DELETE /orders/{id}`

Controller: `API/controllers/OrderController.php`  
Model: `API/models/Order.php`

## Reservation Endpoints

Authenticated:

- `POST /reservations`
- `GET /reservations`
- `PATCH|PUT /reservations/{id}`
- `DELETE /reservations/{id}`

Public:

- `POST /reservations/public`

Controller: `API/controllers/ReservationController.php`  
Model: `API/models/Reservation.php`

## Admin Endpoints (Admin Role Required)

User and dashboard management:

- `GET /admin/users`
- `GET /admin/users/{id}`
- `PUT /admin/users/{id}/role`
- `DELETE /admin/users/{id}`
- `GET /admin/dashboard`

Order administration:

- `GET /admin/orders`
- `GET /admin/orders/summary`
- `GET /admin/orders/status-options`
- `PATCH|PUT /admin/orders/{id}/status`

Product administration:

- `POST /admin/products`
- `PATCH|PUT /admin/products/{id}`
- `DELETE /admin/products/{id}`
- `PATCH /admin/products/{id}/quantity/add`

Reservation administration:

- `GET /admin/reservations`
- `PATCH|PUT /admin/reservations/{id}/duration`

Controllers:

- `API/controllers/AdminController.php`
- `API/controllers/AdminReservationController.php`

## Error Handling

Global exception and error handlers in `index.php` always emit JSON so frontend `fetch(...).json()` flows stay consistent even during failures.
