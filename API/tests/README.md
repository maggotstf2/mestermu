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

### 2. Teszteredmények dokumentálása

- A ténylegesen lefuttatott tesztek eredményeit (pl. Postman export, képernyőképek, terminál logok) ebben a mappában tárold.
- A vizsga dokumentációhoz hivatkozhatsz erre a mappára mint a tesztek és teszteredmények gyűjtőhelyére.

