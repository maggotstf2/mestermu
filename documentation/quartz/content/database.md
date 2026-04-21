---
title: Database
---

The database schema and business logic live in `API/database/torma.sql`.

## Source of Truth

Use `torma.sql` as the canonical source for:

- table structure
- foreign key relationships
- stored procedures
- default seed data

> [!note]
> Additional notes in `API/docs/db-model.md` are useful context, but implementation details may differ from the active SQL dump.

## Database Diagram

The database model diagram is included in the project documentation assets:

![Database model diagram](./torma_database_diagram.drawio.svg)

## Core Tables

- `user`: account-level data and profile fields
- `user_secret`: credential material associated with usernames
- `product`: catalog items and stock quantities
- `orders`: order header and shipping/billing fields
- `order_items`: product lines belonging to orders
- `reservations`: booking requests and schedule details
- `rate_limits`: counters used by API rate limiter

## Relationships

- `orders.user_id -> user.id`
- `order_items.orders_id -> orders.id`
- `order_items.product_id -> product.id`
- `reservations.user_id -> user.id`
- `user_secret.username -> user.username`

These constraints enforce ownership and consistency across checkout and booking flows.

## Stored Procedure Usage

Most write-heavy workflows are procedure-driven:

- user signup/login/profile credential updates
- order creation and order item changes
- reservation creation/update/deletion
- product and admin management operations

## Business Rules in SQL

Important behavior is enforced at the database level:

- stock-aware order item operations
- subtotal and quantity consistency
- required-field checks in order creation
- reservation domain constraints (location/service/date rules)
- username collision handling during account creation

For application-level implications of these rules, see [[backend-api]] and [[security]].
