---
title: Setup
---

This guide explains how to run Torma Security Solutions Ltd. locally with the same defaults expected by the frontend and backend code.

## Requirements

- PHP 7.4+ (PHP 8.x recommended)
- MySQL 5.7+ or MariaDB 10.2+
- A static file server for `Web/` (Apache, Nginx, or a local dev server)

## 1) Configure the Database

Create the database and import the schema:

```shell
mysql -u root -p < API/database/torma.sql
```

> [!note]
> The import script creates tables, foreign keys, and stored procedures used by the API models. Do not skip it.

## 2) Configure API Secrets and Connection

Edit `API/config/config.php`:

- `DB_HOST`
- `DB_NAME`
- `DB_USER`
- `DB_PASS`
- `JWT_SECRET`
- `JWT_EXPIRATION`
- `DEBUG_MODE`

> [!warning]
> Change `JWT_SECRET` and disable debug mode before deploying to production.

## 3) Start the Backend API

From the `API/` directory:

```shell
php -S localhost:8000
```

The health endpoint is available at:

```text
GET http://localhost:8000/
```

## 4) Serve the Frontend

Serve files from `Web/` with any static server, then open `index.html`.

The frontend scripts use `http://localhost:8000` as the API base URL, so keep the API server running on that host/port unless you also update frontend API URLs.

## 5) Verify the Flow

Run this basic smoke test:

1. Register on `register.html`
2. Log in on `login.html`
3. Browse products on `products.html`
4. Add products to cart and place an order via `order.html`
5. Create a reservation on `contact.html`

For full test coverage, follow [[testing]].
