---
title: Testing
---

Testing is currently driven by manual API and UI validation using the checklist in `API/tests/TESTS.md`.

## Test Scope

The existing test flow covers:

- signup and login behavior
- JWT-protected endpoint access
- product catalog and filtering endpoints
- order create/list/details/item operations
- reservation create/list/update/delete flows
- admin authorization and management operations
- rate-limit responses and lockout behavior

## Recommended Test Order

1. [[setup|Set up API and database]]
2. Validate `GET /` health endpoint
3. Execute auth tests (signup, login, profile)
4. Execute product and cart/order tests
5. Execute reservation tests
6. Execute admin route and role tests
7. Validate rate limits and error responses

## Manual UI Regression Pass

After API checks, run a browser pass through:

- `register.html` and `login.html`
- `products.html`, `product.html`, `cart.html`, `order.html`
- `contact.html` reservation creation and listing
- `dashboard.html` profile and order history
- all `admin-*.html` pages with an admin account

## Known Gaps

- no automated backend unit/integration suite
- no end-to-end browser automation in repository
- no CI pipeline for regression enforcement

## Delivery Artifacts Coverage

The repository includes the core artifacts expected by project requirements:

- source code (`Web/`, `API/`)
- database export (`API/database/torma.sql`)
- database model diagram (see [[database]])
- technical and usage documentation (this Quartz content set)
- manual test checklist and test documentation (`API/tests/TESTS.md`)

> [!tip]
> If you add new endpoints or page workflows, update `API/tests/TESTS.md` and this documentation page together to keep behavior and test coverage aligned.
