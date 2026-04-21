---
title: Architecture
---

Torma Security Solutions Ltd. follows a two-part architecture: a static browser client and a PHP API backend connected through JSON over HTTP.

## Requirement Alignment

The implementation follows a REST-oriented client-server split, where browser pages consume JSON endpoints exposed by the PHP backend. This satisfies the requirement for both client-side and server-side components in a RESTful architecture.

## Top-Level Structure

```text
mestermu/
├── Web/               # Static frontend (HTML, CSS, JS)
├── API/               # PHP REST API
└── documentation/     # Diagrams and supplementary artifacts
```

## Frontend Layer

The frontend is plain HTML + JavaScript with no build step:

- `Web/*.html` define pages for public users, logged-in users, and admins
- `Web/js/app.js` contains shared UI behavior, cart logic, and booking flow
- `Web/js/auth.js` manages client session storage and auth headers
- `Web/js/products.js` and `Web/js/product.js` power catalog listing and details
- `Web/js/dashboard.js` handles profile and user order history

See [[frontend]] for page-by-page behavior.

## Backend Layer

`API/index.php` is the entry point. It:

1. Applies CORS and preflight handling
2. Registers global JSON error handlers
3. Dispatches HTTP routes through a simple router
4. Delegates work to controllers

Backend internals are split into:

- `controllers/` request validation and HTTP response shaping
- `models/` domain logic and database access
- `middleware/` auth/admin guards
- `utils/` JWT and rate-limiting helpers
- `database/` SQL schema and stored procedures

See [[backend-api]] for endpoint-level details.

## Data Layer

The project relies heavily on stored procedures in `API/database/torma.sql`.

- Business rules (stock updates, order totals, reservation constraints) live in SQL procedures
- PHP models call procedures using prepared statements
- Foreign keys enforce consistency between users, orders, products, and reservations

See [[database]] for the data model and procedure inventory.
