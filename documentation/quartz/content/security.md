---
title: Security
---

Security in Torma Security Solutions Ltd. is implemented across JWT authentication, role-based authorization, SQL-backed rate limiting, and database-level data handling.

## Authentication

- Login issues JWT tokens signed with `HS256`
- Tokens include expiration based on `JWT_EXPIRATION`
- API token parsing expects `Authorization: Bearer <token>`
- Missing or invalid tokens return `401`

Implementation:

- `API/utils/JWT.php`
- `API/controllers/AuthController.php`
- `API/middleware/AuthMiddleware.php`

## Authorization

Role checks are enforced in middleware and controller flows:

- User endpoints require a valid token
- Admin endpoints require user role `admin`
- Non-admin access to admin routes returns `403`

Implementation:

- `API/middleware/AuthMiddleware.php`
- `API/controllers/AdminController.php`
- `API/controllers/AdminReservationController.php`

## Rate Limiting

Rate limits are persisted in the `rate_limits` table and enforced by `API/utils/RateLimiter.php`.

Current code-level limits include:

- login: `5 / 5 minutes / IP`
- signup: `5 / hour / IP`
- admin mutations: action-specific hourly limits (for example role, user, order, and product operations)

When limits are exceeded, the API returns `429` and includes `Retry-After`.

## Password and Credential Handling

Credential-related operations use SQL procedures defined in `torma.sql` for hashing/validation behavior (`createUser`, `authUser`, `updatePassword`).

> [!warning]
> The development dump may include default credentials. Rotate passwords and secrets before production use.

## Operational Hardening Checklist

Before production deployment:

1. Set a unique high-entropy `JWT_SECRET`
2. Set `DEBUG_MODE` to `false`
3. Restrict CORS to trusted origins
4. Rotate seeded/default credentials
5. Enforce HTTPS at reverse proxy or server layer
