## Adatbázismodell (torma)

Az API a `torma` adatbázist használja. Az alábbi egyszerű diagram a főbb táblák és kapcsolatok áttekintését adja.

```mermaid
erDiagram
    USER {
        int id
        varchar username
        varchar first_name
        varchar last_name
        varchar email
        datetime created_at
        varchar role
    }

    USER_SECRET {
        int id
        text password
        char address
        varchar username
    }

    RESERVATIONS {
        int id
        char about
        datetime reservation_date
        time duration
        datetime reservation_submitted
        int user_id
    }

    MESSAGES {
        int id
        varchar content
        int user_id
    }

    ORDERS {
        int id
        datetime order_date
        int user_id
    }

    ORDER_ITEMS {
        int id
        int orders_id
        int product_id
        smallint quantity
    }

    PRODUCT {
        int id
        text product
        smallint quantity
        tinyint in_stock
        tinyint is_bundled
    }

    USER ||--o{ USER_SECRET : "username"
    USER ||--o{ RESERVATIONS : "user_id"
    USER ||--o{ MESSAGES : "user_id"
    USER ||--o{ ORDERS : "user_id"

    ORDERS ||--o{ ORDER_ITEMS : "orders_id"
    PRODUCT ||--o{ ORDER_ITEMS : "product_id"
```

Részletes SQL definíciók a `database/torma.sql` fájlban találhatók.

