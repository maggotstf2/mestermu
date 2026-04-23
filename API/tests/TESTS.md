## Tesztek és teszteredmények

Ez a mappa tartalmazza az API kézi teszteléséhez javasolt lépéseket. A vizsgához a futtatott tesztek eredményeit (pl. Postman collection export, képernyőképek, logok) ide lehet gyűjteni.

### 1. Alap funkcionális tesztek

1. **Regisztráció sikeres**
   - POST `http://localhost:8000/signup`
   - Törzs:
     ```json
     {
       "username": "test_user_1",
       "email": "test_user_1@example.com",
       "password": "password123",
       "first_name": "Test",
       "last_name": "User"
     }
     ```
   - Elvárt eredmény: `201 Created`, `success: true`.

2. **Bejelentkezés sikeres**
   - POST `http://localhost:8000/login`
   - Törzs:
     ```json
     {
       "username": "test_user_1",
       "password": "password123"
     }
     ```
   - Elvárt eredmény: `200 OK`, JWT token a válaszban.

3. **Bejelentkezés hibás jelszóval**
   - Ugyanaz, mint előbb, de rossz jelszóval.
   - Elvárt eredmény: `401 Unauthorized`, `success: false`.

4. **Rate limiting ellenőrzése**
   - 5-nél többször próbálj hibás jelszóval bejelentkezni rövid időn belül.
   - Elvárt eredmény: egy ponton `429 Too Many Requests` válasz.

5. **Profil lekérése**
   - GET `http://localhost:8000/profile` a sikeres login után kapott tokennel (`Authorization: Bearer {token}`).
   - Elvárt eredmény: felhasználói adatok.

6. **Admin végpontok**
   - Admin felhasználóval (`john_doe`) bejelentkezve hívd meg a:
     - GET `/admin/users`
     - GET `/admin/users/{id}`
     - PUT `/admin/users/{id}/role`
     - DELETE `/admin/users/{id}`
   - Ellenőrizd a válaszok helyességét és státuszkódjait.

### 2. Termék API tesztek

1. **Publikus terméklista (alap)**
   - GET `http://localhost:8000/products`
   - Elvárt eredmény: `200 OK`, `success: true`, `items` tömb (a `torma.sql` alapján több mint 100 termék).

2. **Publikus terméklista szűrőkkel**
   - GET `http://localhost:8000/products?cat=CCTV&search=kamera&limit=5`
   - Elvárt eredmény:
     - `200 OK`
     - `items` tömbben csak `cat = "CCTV"` termékek
     - maximum 5 elem, `total` mező a teljes találatszámot mutatja.

3. **Termék lekérése ID alapján**
   - GET `http://localhost:8000/products/1`
   - Elvárt eredmény:
     - `200 OK`
     - `success: true`
     - `product.id == 1`
   - Hibás ID esetén (pl. 9999): `404 Not Found`, `success: false`.

4. **Szűrési facetek lekérése**
   - GET `http://localhost:8000/products/facets`
   - Elvárt eredmény:
     - `200 OK`
     - `success: true`
     - `facets.categories`, `facets.subcategories`, `facets.brands`, `facets.tags` nem üres tömbök.

5. **Admin – új termék létrehozása**
   - POST `http://localhost:8000/admin/products`
   - Header: `Authorization: Bearer {admin_token}`, `Content-Type: application/json`
   - Törzs:
     ```json
     {
       "name": "Teszt termék",
       "brand": "Generic",
       "cat": "CCTV",
       "subcat": "Kamerák",
       "tag1": "Beltéri",
       "tag2": "Teszt",
       "price": 9999,
       "quantity": 3,
       "description": "Teszt termék a vizsgához"
     }
     ```
   - Elvárt eredmény: `201 Created`, `success: true`, a válaszban `product.id` új azonosítóval.

6. **Admin – termék frissítése**
   - PATCH `http://localhost:8000/admin/products/{id}`
   - Használd az előző pontban létrehozott termék ID-ját.
   - Törzs:
     ```json
     {
       "price": 12000,
       "quantity": 5
     }
     ```
   - Elvárt eredmény: `200 OK`, `product.price == 12000`, `product.quantity == 5`.

7. **Admin – készlet mennyiség módosítása**
   - PATCH `http://localhost:8000/admin/products/{id}/quantity`
   - Törzs:
     ```json
     {
       "quantity": 10
     }
     ```
   - Elvárt eredmény: `200 OK`, `product.quantity == 10`.

8. **Admin – termék törlése**
   - DELETE `http://localhost:8000/admin/products/{id}`
   - Elvárt eredmény: `200 OK`, `success: true`.
   - Utána GET ugyanarra az ID-ra: `404 Not Found`.

9. **Jogosultsági tesztek**
    - Normál (nem admin) tokennel próbáld hívni:
      - POST `/admin/products`
      - PATCH `/admin/products/{id}`
      - DELETE `/admin/products/{id}`
    - Elvárt eredmény: `403 Forbidden` (`Admin access required`).
    - Token nélkül ugyanezekre: `401 Unauthorized`.

