# JWT TOKENELÉS

## konfiguráció

a rejtett token a config.php-ban helyezkedik el az adatbázis bejelentkezés melett, ez nincs felcommittelve a gitre.

## API végpontok

az összes végpont JSON-t küld és fogad.

### URL
```
http://localhost/login_registration_API/index.php
```

### 1. felhasználó felvétele

**POST** `/index.php`

```json
{
  "action": "register",
  "username": "testuser",
  "email": "test@example.com",
  "password": "password123",
  "first_name": "Test",
  "last_name": "User"
}
```

**amennyiben sikerrel jar a POST (201-es valasz):**
```json
{
  "success": true,
  "message": "User created successfully",
  "user_id": 1
}
```

### 2. bejelentkezés

**POST** `/index.php`

```json
{
  "action": "login",
  "username": "testuser",
  "password": "password123"
}
```

**amennyiben jo a bejelentkezes (200-as valasz):**
```json
{
  "success": true,
  "message": "Sikeres bejelentkezés",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com"
  }
}
```

**amennyiben nem jo valamelyik parameter (401-es valasz):**
```json
{
  "success": false,
  "message": "Helytelen felhasználónév vagy jelszó"
}
```

### 3. token hitelesítés

**POST** `/index.php`

**elso lehetoseg: token lekerese a bodyban**
```json
{
  "action": "validate",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**masodik lehetoseg: token az auth headerben**
```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**ha sikerul lekerni (200-as valasz):**
```json
{
  "success": true,
  "data": {
    "iss": "login_registration_API",
    "iat": 1234567890,
    "exp": 1234654290,
    "user_id": 1,
    "username": "testuser",
    "email": "test@example.com"
  }
}
```

**ha nem sikerul (401-es valasz):**
```json
{
  "success": false,
  "message": "A token lejárt"
}
```

### 4. API Info

**GET** `/index.php`

visszaadja az összes elérhető információt a végpontokról.