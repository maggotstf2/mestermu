---
title: Frontend
---

The frontend is a static multi-page application in `Web/` that consumes the REST API directly from browser-side JavaScript.

## Platform Coverage

The client is implemented as a web interface intended for both desktop and mobile usage, matching the project requirement that the user-facing component be available as a web solution across device classes.

## Core Scripts

- `Web/js/app.js`: shared navigation, cart interactions, booking/reservation flow
- `Web/js/auth.js`: session persistence (`token`, `user`, expiration) in local storage
- `Web/js/products.js`: product list rendering, filtering, sorting, category UI, cart actions
- `Web/js/product.js`: single product page data fetch and rendering
- `Web/js/dashboard.js`: profile management and user order history

## Public Pages

- `index.html`: landing page
- `about.html`: company and service information
- `references.html`: customer/reference content
- `products.html`: catalog browsing with filters
- `product.html`: details for one product
- `contact.html`: contact and booking form

## Authentication Pages

- `login.html`: calls `POST /login`, then stores token and user context
- `register.html`: calls `POST /signup` with form-level validation and consent checkbox

## User Pages

- `cart.html`: review and manage cart contents
- `order.html`: checkout form, order creation, and order item submission
- `dashboard.html`: profile info, username/password update, own order listing/details

## Admin Pages

- `admin.html`: dashboard-level admin overview
- `admin-products.html`: product CRUD and stock operations
- `admin-orders.html`: order list and status updates
- `admin-bookings.html`: reservation management view
- `admin-contacts.html`: contact view scaffold (currently static sample content)

## Session and Authorization Model

Client-side auth behavior:

1. Successful login stores `token` and user payload
2. Auth headers are generated as `Authorization: Bearer <token>`
3. Session expires client-side after configured TTL (default 1 hour)
4. Protected pages redirect when token/user context is missing or expired

Server-side enforcement is described in [[security]].
