-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 30, 2026 at 04:34 PM
-- Server version: 12.1.2-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `torma`
--
CREATE DATABASE IF NOT EXISTS `torma` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci;
USE `torma`;

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `addOrderItem`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `addOrderItem` (IN `pOrderId` INTEGER UNSIGNED, IN `pProductId` INTEGER UNSIGNED, IN `pQuantity` SMALLINT UNSIGNED)   BEGIN
    DECLARE vPrice INT UNSIGNED;
    DECLARE vStock SMALLINT UNSIGNED;
    DECLARE vSubtotal INT UNSIGNED;
    DECLARE vOrderId INTEGER UNSIGNED;

    -- Ellenőrizzük, hogy a rendelés létezik-e (különben FK hiba lenne)
    SELECT id
      INTO vOrderId
    FROM orders
    WHERE id = pOrderId
    FOR UPDATE;

    IF vOrderId IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid order_id (order not found)';
    END IF;

    -- Zároljuk a termék sort, hogy az ár/készlet ne változzon közben
    SELECT price, quantity
      INTO vPrice, vStock
    FROM product
    WHERE id = pProductId
    FOR UPDATE;

    IF vPrice IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid product_id (price not found)';
    END IF;

    IF pQuantity = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be > 0';
    END IF;

    IF vStock < pQuantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;

    SET vSubtotal = vPrice * pQuantity;

    INSERT INTO order_items (orders_id, product_id, quantity, subtotal)
    VALUES (pOrderId, pProductId, pQuantity, vSubtotal);

    -- Készlet csökkentése
    UPDATE product
    SET quantity = quantity - pQuantity
    WHERE id = pProductId;

    -- Opcionális: rendelések összegének azonnali frissítése
    -- UPDATE orders SET sum = sum + vSubtotal WHERE id = pOrderId;
END$$

DROP PROCEDURE IF EXISTS `addToProductQuantity`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `addToProductQuantity` (IN `pId` INT(10) UNSIGNED, IN `pQuantity` SMALLINT(5) UNSIGNED)   UPDATE product
SET quantity = (quantity + pQuantity)
WHERE id=pId$$

DROP PROCEDURE IF EXISTS `authUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `authUser` (IN `pUsername` VARCHAR(32), IN `pPassword` VARCHAR(100))   BEGIN
SELECT u.id, u.username, u.email
FROM user u
JOIN user_secret c ON u.username = c.username
WHERE u.username = pUsername
AND c.password = SHA2(pPassword, 256);
END$$

DROP PROCEDURE IF EXISTS `createOrder`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `createOrder` (IN `pUsername` VARCHAR(32))   BEGIN
    DECLARE vUserId INTEGER UNSIGNED;

    SELECT id
      INTO vUserId
    FROM user
    WHERE username = pUsername;

    IF vUserId IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid username (user not found)';
    END IF;

    INSERT INTO orders (user_id, order_date, status, sum)
    VALUES (vUserId, NOW(), 'Feldolgozás alatt', 0);
    
    SELECT LAST_INSERT_ID() AS 'new_order_id';
END$$

DROP PROCEDURE IF EXISTS `createProduct`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `createProduct` (IN `pName` TEXT, IN `pBrand` VARCHAR(32), IN `pCat` VARCHAR(32), IN `pSubcat` VARCHAR(32), IN `pTag1` VARCHAR(64), IN `pTag2` VARCHAR(64), IN `pPrice` INT(10) UNSIGNED, IN `pQuantity` SMALLINT(5) UNSIGNED, IN `pInStock` BOOLEAN, IN `pDescription` VARCHAR(1024), IN `pIsBundled` BOOLEAN)   INSERT INTO product
	(
		name,
        brand,
        cat,
        subcat,
        tag1,
        tag2,
        price,
        quantity,
        in_stock,
        description,
        is_bundled
	)

VALUES
	(
        pName,
        pBrand,
        pCat,
        pSubcat,
        pTag1,
        pTag2,
        pPrice,
        pQuantity,
        pInStock,
        pDescription,
        pIsBundled
	)$$

DROP PROCEDURE IF EXISTS `createReservation`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `createReservation` (IN `pMessage` CHAR(255), IN `pReservationDate` DATETIME, IN `pLocation` VARCHAR(64), IN `pService` VARCHAR(64), IN `pUsername` VARCHAR(32))   BEGIN
    DECLARE vLocation VARCHAR(64);
    DECLARE vService VARCHAR(64);
    DECLARE vErrText VARCHAR(255);

    SET vLocation = TRIM(pLocation);
    SET vService = TRIM(pService);

    IF vLocation NOT IN ('Helyszíni kiszállás','Telefonos egyeztetés','Telephelyen') THEN
        SET vErrText = CONCAT('Invalid location: "', COALESCE(vLocation, 'NULL'), '"');
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = vErrText;
    END IF;

    IF vService NOT IN ('Riasztórdsz. konzultáció','Tűzjelző konzultáció','Kamerardsz. felmérés','Kaputelefon egyeztetés','Gyengeáramú kivitelezés','GPS nyomkövetés bemutató') THEN
        SET vErrText = CONCAT('Invalid service: "', COALESCE(vService, 'NULL'), '"');
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = vErrText;
    END IF;

    INSERT INTO reservations (
        message, 
        reservation_date, 
        location, 
        service, 
        duration,
        user_id
    )
    VALUES (
        pMessage, 
        pReservationDate, 
        vLocation, 
        vService, 
        '00:00:00',
        (SELECT id FROM user WHERE username = pUsername)
    );
END$$

DROP PROCEDURE IF EXISTS `createUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `createUser` (IN `pUsername` VARCHAR(32), IN `pPassword` VARCHAR(32), IN `pEmail` VARCHAR(100), IN `pFirstname` VARCHAR(50), IN `pLastname` VARCHAR(50))   BEGIN
INSERT INTO user(username, email, first_name, last_name)
VALUES(pUsername, pEmail, pFirstname, pLastname);
INSERT INTO user_secret(password, username)
VALUES(SHA2(pPassword,256),pUsername);
END$$

DROP PROCEDURE IF EXISTS `deleteOrder`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteOrder` (IN `pOrderId` INT UNSIGNED)   BEGIN
    DELETE FROM orders WHERE id = pOrderId;
END$$

DROP PROCEDURE IF EXISTS `deleteOrderItem`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteOrderItem` (IN `pOrdersId` INT(10) UNSIGNED, IN `pProductId` INT(10) UNSIGNED)   BEGIN
DELETE FROM order_items
	WHERE product_id=pProductId AND orders_id=pOrdersId;
END$$

DROP PROCEDURE IF EXISTS `deleteProduct`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteProduct` (IN `pId` INT(10) UNSIGNED)   BEGIN
DELETE FROM product WHERE id = pId;
END$$

DROP PROCEDURE IF EXISTS `deleteReservation`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteReservation` (IN `pId` INTEGER UNSIGNED)   BEGIN
DELETE FROM reservations WHERE id=pId;
END$$

DROP PROCEDURE IF EXISTS `deleteUser`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteUser` (IN `pUsername` VARCHAR(32))   BEGIN
DELETE FROM user WHERE username = pUsername;
END$$

DROP PROCEDURE IF EXISTS `getAllOrders`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllOrders` ()   SELECT * FROM orders ORDER BY id ASC$$

DROP PROCEDURE IF EXISTS `getAllProductBrands`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllProductBrands` ()   SELECT DISTINCT(brand) FROM product ORDER BY brand ASC$$

DROP PROCEDURE IF EXISTS `getAllProductCats`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllProductCats` ()   SELECT DISTINCT(cat) FROM product ORDER BY cat ASC$$

DROP PROCEDURE IF EXISTS `getAllProductNames`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllProductNames` ()   SELECT DISTINCT(name) FROM product ORDER BY name ASC$$

DROP PROCEDURE IF EXISTS `getAllProducts`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllProducts` ()   SELECT * FROM product ORDER BY id ASC$$

DROP PROCEDURE IF EXISTS `getAllProductSubcats`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllProductSubcats` ()   SELECT DISTINCT(subcat) FROM product ORDER BY subcat ASC$$

DROP PROCEDURE IF EXISTS `getAllProductTags`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllProductTags` ()   SELECT DISTINCT(tag1) FROM product
UNION
SELECT DISTINCT(tag2) FROM product ORDER BY tag1 ASC$$

DROP PROCEDURE IF EXISTS `getAllUsers`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllUsers` ()   BEGIN
SELECT u.id, u.username, u.first_name, u.last_name, u.role, u.created_at
FROM user u
ORDER BY u.created_at DESC;
END$$

DROP PROCEDURE IF EXISTS `getOrderDetails`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrderDetails` (IN `pOrderId` INTEGER UNSIGNED)   BEGIN
    SELECT 
        p.name AS "Termék",
        p.brand AS "Márka",
        oi.quantity AS "Mennyiség",
        CASE WHEN oi.quantity > 0 THEN (oi.subtotal / oi.quantity) ELSE NULL END AS "Egységár",
        oi.subtotal AS "Részösszeg"
    FROM order_items oi
    JOIN product p ON oi.product_id = p.id
    WHERE oi.orders_id = pOrderId;
END$$

DROP PROCEDURE IF EXISTS `getProductBrandById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getProductBrandById` (IN `pId` INT(10) UNSIGNED)   SELECT brand AS "Márka" FROM product WHERE id=pId ORDER BY brand ASC$$

DROP PROCEDURE IF EXISTS `getProductById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getProductById` (IN `pId` INT(10) UNSIGNED)   SELECT * FROM product WHERE id=pId$$

DROP PROCEDURE IF EXISTS `getProductsByBrandName`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getProductsByBrandName` (IN `pName` VARCHAR(32))   SELECT * FROM product WHERE brand LIKE pName$$

DROP PROCEDURE IF EXISTS `getUserByFirstName`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserByFirstName` (IN `pFirstname` VARCHAR(32))   SELECT * FROM user WHERE first_name = pFirstname ORDER BY id ASC$$

DROP PROCEDURE IF EXISTS `getUserById`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserById` (IN `pId` INTEGER UNSIGNED)   BEGIN
SELECT u.id, u.username, u.first_name, u.last_name, u.role, u.created_at
FROM user u
WHERE u.id=pId;
END$$

DROP PROCEDURE IF EXISTS `getUserByLastName`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserByLastName` (IN `pLastname` VARCHAR(32))   SELECT * FROM user WHERE last_name = pLastname ORDER BY id ASC$$

DROP PROCEDURE IF EXISTS `getUserByUsername`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserByUsername` (IN `pUsername` VARCHAR(32))   BEGIN
SELECT u.id, u.username, u.first_name, u.last_name, u.role, u.created_at
FROM user u 
WHERE u.username = pUsername;
END$$

DROP PROCEDURE IF EXISTS `getUserOrders`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserOrders` (IN `pUsername` VARCHAR(32))   BEGIN
    SELECT 
        o.id AS "Rendelésszám",
        o.order_date AS "Dátum",
        us.address AS "Szállítási cím",
        o.status AS "Állapot"
    FROM orders o
    JOIN user u ON o.user_id = u.id
    LEFT JOIN user_secret us ON us.username = u.username
    WHERE u.username = pUsername
    ORDER BY o.order_date DESC;
END$$

DROP PROCEDURE IF EXISTS `getUserReservations`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserReservations` (IN `pUsername` VARCHAR(32))   BEGIN
    SELECT 
        r.id AS "Foglalás Azonosító", 
        r.message AS "Leírás", 
        r.reservation_date AS "Időpont", 
        r.location AS "Helyszín",
        r.service AS "Szolgáltatás",
        r.duration AS "Admin által szabott időtartam", 
        r.reservation_submitted AS "Rögzítve"
    FROM reservations r
    JOIN user u ON r.user_id = u.id
    WHERE u.username = pUsername
    ORDER BY r.reservation_date ASC;
END$$

DROP PROCEDURE IF EXISTS `setAdminStatus`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `setAdminStatus` (IN `pId` INTEGER UNSIGNED, IN `pStatus` TINYINT(1))   BEGIN
UPDATE user
SET role = IF(pStatus=1,'admin','user')
WHERE id=pId;
END$$

DROP PROCEDURE IF EXISTS `setProductInStock`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `setProductInStock` (IN `pId` INT(10) UNSIGNED)   UPDATE product
SET in_stock=(IF(in_stock=0,1,1))
WHERE id=pId$$

DROP PROCEDURE IF EXISTS `updateOrderItemQuantity`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrderItemQuantity` (IN `pOrderId` INTEGER UNSIGNED, IN `pProductId` INTEGER UNSIGNED, IN `pNewQuantity` SMALLINT UNSIGNED)   BEGIN
    DECLARE vPrice INT UNSIGNED;
    DECLARE vStock SMALLINT UNSIGNED;
    DECLARE vOldQuantity SMALLINT UNSIGNED;
    DECLARE vDelta SMALLINT;
    DECLARE vNewSubtotal INT UNSIGNED;

    IF pNewQuantity = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be > 0';
    END IF;

    -- Aktuális mennyiség lekérése a tételből (és zárolás a módosításhoz)
    SELECT quantity
      INTO vOldQuantity
    FROM order_items
    WHERE orders_id = pOrderId AND product_id = pProductId
    FOR UPDATE;

    IF vOldQuantity IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order item not found';
    END IF;

    -- Termék ár + készlet zárolása
    SELECT price, quantity
      INTO vPrice, vStock
    FROM product
    WHERE id = pProductId
    FOR UPDATE;

    IF vPrice IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid product_id (price not found)';
    END IF;

    SET vDelta = pNewQuantity - vOldQuantity;

    -- Ha növeljük a mennyiséget, legyen elég készlet
    IF vDelta > 0 AND vStock < vDelta THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;

    SET vNewSubtotal = vPrice * pNewQuantity;

    UPDATE order_items 
    SET quantity = pNewQuantity,
        subtotal = vNewSubtotal
    WHERE orders_id = pOrderId AND product_id = pProductId;

    -- Készlet korrigálása a különbözettel
    UPDATE product
    SET quantity = quantity - vDelta
    WHERE id = pProductId;
END$$

DROP PROCEDURE IF EXISTS `updatePassword`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updatePassword` (IN `pUsername` VARCHAR(32), IN `pNewPass` VARCHAR(100))   BEGIN
UPDATE user_secret
SET password = SHA2(pNewPass, 256)
WHERE username = pUsername;
END$$

DROP PROCEDURE IF EXISTS `updateProductQuantity`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateProductQuantity` (IN `pProductId` INTEGER UNSIGNED, IN `pNewQuantity` SMALLINT UNSIGNED)   BEGIN
    DECLARE vExistingId INTEGER UNSIGNED;

    -- Ellenőrizzük, hogy a termék létezik-e (különben félrevezető lenne a "0 rows affected")
    SELECT id
      INTO vExistingId
    FROM product
    WHERE id = pProductId
    FOR UPDATE;

    IF vExistingId IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid product_id (product not found)';
    END IF;

    UPDATE product
    SET
        quantity = pNewQuantity,
        in_stock = IF(pNewQuantity > 0, 1, 0)
    WHERE id = pProductId;
END$$

DROP PROCEDURE IF EXISTS `updateReservation`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateReservation` (IN `pId` INTEGER UNSIGNED, IN `pMessage` CHAR(255), IN `pReservationDate` DATETIME, IN `pLocation` VARCHAR(64), IN `pService` VARCHAR(64))   BEGIN
    DECLARE vLocation VARCHAR(64);
    DECLARE vService VARCHAR(64);
    DECLARE vErrText VARCHAR(255);

    SET vLocation = TRIM(pLocation);
    SET vService = TRIM(pService);

    IF vLocation NOT IN ('Helyszíni kiszállás','Telefonos egyeztetés','Telephelyen') THEN
        SET vErrText = CONCAT('Invalid location: "', COALESCE(vLocation, 'NULL'), '"');
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = vErrText;
    END IF;

    IF vService NOT IN ('Riasztórdsz. konzultáció','Tűzjelző konzultáció','Kamerardsz. felmérés','Kaputelefon egyeztetés','Gyengeáramú kivitelezés','GPS nyomkövetés bemutató') THEN
        SET vErrText = CONCAT('Invalid service: "', COALESCE(vService, 'NULL'), '"');
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = vErrText;
    END IF;

    UPDATE reservations
    SET 
        message = pMessage,
        reservation_date = pReservationDate,
        location = vLocation,
        service = vService
    WHERE id = pId;
END$$

DROP PROCEDURE IF EXISTS `updateReservationDuration`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateReservationDuration` (IN `pId` INTEGER UNSIGNED, IN `pDuration` TIME)   BEGIN
    UPDATE reservations
    SET 
        duration = pDuration
    WHERE id = pId;
END$$

DROP PROCEDURE IF EXISTS `updateUsername`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUsername` (IN `pUsername` VARCHAR(32), IN `pId` INT UNSIGNED)   BEGIN
DECLARE vNewUsername VARCHAR(32);
    DECLARE vExistingId INTEGER UNSIGNED;

    SET vNewUsername = TRIM(pUsername);

    IF vNewUsername IS NULL OR vNewUsername = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username cannot be empty';
    END IF;

    -- Ne engedjünk ütközést másik user rekorddal
    SELECT id
      INTO vExistingId
    FROM user
    WHERE username = vNewUsername
      AND id <> pId
    LIMIT 1;

    IF vExistingId IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username already exists';
    END IF;

    UPDATE user u
    LEFT JOIN user_secret us ON us.username = u.username
    SET u.username = vNewUsername,
        us.username = vNewUsername
    WHERE u.id = pId;
END$$

DROP PROCEDURE IF EXISTS `updateUserRole`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUserRole` (IN `pId` INTEGER UNSIGNED, IN `pRole` ENUM('user','admin'))   BEGIN
UPDATE user SET role=pRole
WHERE id=pId;
END$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `isAdmin`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `isAdmin` (`pUsername` VARCHAR(32)) RETURNS TINYINT(1) DETERMINISTIC READS SQL DATA BEGIN
RETURN EXISTS
(
	SELECT 1 FROM user
	WHERE username=pUsername AND role='admin'
);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `id` int(10) UNSIGNED NOT NULL,
  `order_date` datetime NOT NULL DEFAULT current_timestamp(),
  `sum` int(11) NOT NULL,
  `status` varchar(64) NOT NULL DEFAULT 'Feldolgozás alatt',
  `user_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `order_date`, `sum`, `status`, `user_id`) VALUES
(3, '2026-03-30 14:36:23', 0, 'Feldolgozás alatt', 3),
(4, '2026-03-30 14:42:41', 0, 'Feldolgozás alatt', 3),
(5, '2026-03-30 16:20:03', 0, 'Feldolgozás alatt', 10);

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

DROP TABLE IF EXISTS `order_items`;
CREATE TABLE `order_items` (
  `id` int(10) UNSIGNED NOT NULL,
  `orders_id` int(10) UNSIGNED NOT NULL,
  `product_id` int(10) UNSIGNED NOT NULL,
  `quantity` smallint(6) UNSIGNED NOT NULL,
  `subtotal` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`id`, `orders_id`, `product_id`, `quantity`, `subtotal`) VALUES
(3, 4, 1, 2, 59040),
(4, 5, 68, 4, 2485480),
(5, 5, 7, 1, 73800);

-- --------------------------------------------------------

--
-- Table structure for table `product`
--

DROP TABLE IF EXISTS `product`;
CREATE TABLE `product` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` text NOT NULL,
  `brand` varchar(32) NOT NULL,
  `cat` varchar(32) NOT NULL,
  `subcat` varchar(32) NOT NULL,
  `tag1` varchar(64) NOT NULL,
  `tag2` varchar(64) NOT NULL,
  `price` int(10) UNSIGNED NOT NULL,
  `quantity` smallint(5) UNSIGNED NOT NULL,
  `in_stock` tinyint(1) NOT NULL DEFAULT 1,
  `description` varchar(1024) NOT NULL,
  `is_bundled` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `product`
--

INSERT INTO `product` (`id`, `name`, `brand`, `cat`, `subcat`, `tag1`, `tag2`, `price`, `quantity`, `in_stock`, `description`, `is_bundled`) VALUES
(1, 'Paradox PIR mozgásérzékelő (beltéri)', 'Paradox', 'Behatolásjelzők', 'Érzékelők', 'Kültéri', 'Professzionális', 29520, 13, 1, 'Behatolásjelzők / Érzékelők ', 0),
(2, 'Paradox LED kezelő (kódpanel)', 'Paradox', 'Behatolásjelzők', 'Kezelők', 'Beltéri', 'Professzionális', 61360, 12, 1, 'Behatolásjelzők / Kezelők ', 0),
(3, 'Paradox riasztóközpont 8 zónás (bővíthető)', 'Paradox', 'Behatolásjelzők', 'Riasztóközpontok', 'Professzionális', 'Kültéri', 88100, 0, 1, 'Behatolásjelzők / Riasztóközpontok ', 0),
(4, 'Jablotron mikrohullámú sorompó (kültéri)', 'Jablotron', 'Behatolásjelzők', 'Infra- és mikro sorompók', 'Professzionális', 'Modul', 214450, 25, 1, 'Behatolásjelzők / Infra- és mikro sorompók ', 0),
(5, 'Paradox kültéri sziréna villogóval', 'Paradox', 'Behatolásjelzők', 'Kiegészítők', 'Modul', 'Professzionális', 29580, 12, 1, 'Behatolásjelzők / Kiegészítők ', 0),
(6, 'ZKTeco 2 ajtós beléptető vezérlő', 'ZKTeco', 'Beléptetők', 'Vezérlők', 'Beltéri', 'Professzionális', 140080, 10, 1, 'Beléptetők / Vezérlők ', 0),
(7, 'Akuvox önálló RFID olvasó + billentyűzet', 'Akuvox', 'Beléptetők', 'Önálló olvasók', 'Professzionális', 'Modul', 73800, 9, 1, 'Beléptetők / Önálló olvasók ', 0),
(8, 'HID segédolvasó, EM-Marine', 'HID', 'Beléptetők', 'Segédolvasók', 'Kiegészítő', 'Beltéri', 90260, 2, 1, 'Beléptetők / Segédolvasók ', 0),
(9, 'RFID kulcstartó TAG (EM-Marine)', 'Generic', 'Beléptetők', 'Kártyák, tag-ek', '125kHz', 'PVC', 2470, 8, 1, 'Beléptetők / Kártyák, tag-ek ', 0),
(10, 'Generic síkmágnes 280 kg tartóerő', 'Generic', 'Beléptetők', 'Síkmágnesek', 'Beltéri', 'Kültéri', 70700, 2, 1, 'Beléptetők / Síkmágnesek ', 0),
(11, 'Rosslare mágneszár készlet ajtóra', 'Rosslare', 'Beléptetők', 'Mágneszárak', 'Beltéri', 'Kiegészítő', 83050, 5, 1, 'Beléptetők / Mágneszárak ', 0),
(12, 'Rosslare vésznyitó gomb (break glass)', 'Rosslare', 'Beléptetők', 'Kiegészítők', 'Modul', 'Professzionális', 15930, 3, 1, 'Beléptetők / Kiegészítők ', 0),
(13, 'Hikvision turret kamera (4MP) PoE', 'Hikvision', 'CCTV', 'Kamerák', 'FullColor', '4MP', 126160, 0, 1, 'CCTV / Kamerák ', 0),
(14, 'Hikvision DVR 16 csatornás (1080p)', 'Hikvision', 'CCTV', 'Rögzítők', 'Professzionális', 'Kültéri', 154320, 7, 1, 'CCTV / Rögzítők ', 0),
(15, 'Uniview 4 kamerás PoE szett (NVR + kamerák)', 'Uniview', 'CCTV', 'Szettek', 'Modul', 'Kiegészítő', 155040, 0, 1, 'CCTV / Szettek ', 0),
(16, 'Kamera konzol (dome/turret)', 'Uniview', 'CCTV', 'Tartozékok', 'Kültéri', 'Kiegészítő', 19270, 10, 1, 'CCTV / Tartozékok ', 0),
(17, 'Axis mikroSD kártya 128GB', 'Axis', 'CCTV', 'Kiegészítők', 'Modul', 'Kültéri', 39570, 3, 1, 'CCTV / Kiegészítők ', 0),
(18, 'BFT szárnyaskapu motor (2 szárny)', 'BFT', 'Kaputechnika', 'Motorok', 'Fotocella', 'Távirányító', 334770, 12, 1, 'Kaputechnika / Motorok ', 0),
(19, 'Came tolókapu szett (motor + 2 táv + fotocella)', 'Came', 'Kaputechnika', 'Szettek', 'IP54', 'Fotocella', 240640, 25, 1, 'Kaputechnika / Szettek ', 0),
(20, 'Nice parkoló sorompó (3-4 m kar)', 'Nice', 'Kaputechnika', 'Sorompók', 'Távirányító', 'IP54', 1022390, 3, 1, 'Kaputechnika / Sorompók ', 0),
(21, 'Beninca parkolásgátló (kulcsos)', 'Beninca', 'Kaputechnika', 'Parkolásgátlók', 'Fotocella', '230V', 245250, 25, 1, 'Kaputechnika / Parkolásgátlók ', 0),
(22, 'Generic síkmágnes kapuhoz 280 kg', 'Generic', 'Kaputechnika', 'Síkmágnesek', 'Fotocella', '230V', 68710, 2, 1, 'Kaputechnika / Síkmágnesek ', 0),
(23, 'Came redőnymotor 40 Nm', 'Came', 'Kaputechnika', 'Redőnymozgatás', '24V', 'Távirányító', 136160, 12, 1, 'Kaputechnika / Redőnymozgatás ', 0),
(24, 'Kapu nyitó nyomógomb', 'Nice', 'Kaputechnika', 'Kiegészítők', 'Fotocella', 'IP54', 41990, 3, 1, 'Kaputechnika / Kiegészítők ', 0),
(25, 'Akuvox beltéri audio egység', 'Akuvox', 'Kaputelefon', 'Beltéri egységek', 'Kültéri', 'Modul', 196340, 5, 1, 'Kaputelefon / Beltéri egységek ', 0),
(26, 'Kaputelefon esővédő', 'Dahua', 'Kaputelefon', 'Kiegészítők', 'Professzionális', 'Modul', 32880, 0, 1, 'Kaputelefon / Kiegészítők ', 0),
(27, '2N kültéri kaputábla (1 lakás)', '2N', 'Kaputelefon', 'Kültéri egységek', 'Modul', 'Kültéri', 66640, 10, 1, 'Kaputelefon / Kültéri egységek ', 0),
(28, 'Hikvision kaputelefon szett (1 kültéri + 1 beltéri)', 'Hikvision', 'Kaputelefon', 'Szettek', 'Beltéri', 'Kiegészítő', 471810, 2, 1, 'Kaputelefon / Szettek ', 0),
(29, 'Zselés akkumulátor 12V 26Ah', 'Mean Well', 'Kiegészítők', 'Akkumulátorok', 'Kiegészítő', 'Kültéri', 24590, 3, 1, 'Kiegészítők / Akkumulátorok ', 0),
(30, 'Wi‑Fi router (dual band)', 'Seagate', 'Kiegészítők', 'Hálózati eszközök', 'Kültéri', 'Professzionális', 103370, 12, 1, 'Kiegészítők / Hálózati eszközök ', 0),
(31, 'Kültéri sziréna villogóval', 'Seagate', 'Kiegészítők', 'Hang- fényjelzők', 'Kiegészítő', 'Professzionális', 58010, 10, 1, 'Kiegészítők / Hang- fényjelzők ', 0),
(32, 'GSM kommunikátor (riasztó)', 'Mean Well', 'Kiegészítők', 'Kommunikátorok', 'Modul', 'Beltéri', 40800, 2, 1, 'Kiegészítők / Kommunikátorok ', 0),
(33, 'LED reflektor 100W (IP65)', 'Generic', 'Kiegészítők', 'LED reflektorok', 'Beltéri', 'Professzionális', 21840, 5, 1, 'Kiegészítők / LED reflektorok ', 0),
(34, 'Mean Well Surveillance HDD 1TB', 'Mean Well', 'Kiegészítők', 'Merevlemezek', 'Modul', 'Beltéri', 20510, 0, 1, 'Kiegészítők / Merevlemezek ', 0),
(35, 'Rack szekrény 9U falra szerelhető', 'Generic', 'Kiegészítők', 'Rack szekrények', 'Kültéri', 'Professzionális', 141240, 25, 1, 'Kiegészítők / Rack szekrények ', 0),
(36, 'Dübel + csavar (50 db)', 'Generic', 'Kiegészítők', 'Segédanyagok', 'Kiegészítő', 'Professzionális', 19850, 50, 1, 'Kiegészítők / Segédanyagok ', 0),
(37, 'Krimpelő fogó RJ45-hez', 'Western Digital', 'Kiegészítők', 'Szerszámok', 'Modul', 'Kiegészítő', 4460, 12, 1, 'Kiegészítők / Szerszámok ', 0),
(38, 'APC tápegység 12V 10A', 'APC', 'Kiegészítők', 'Tápegységek', 'Beltéri', 'Kiegészítő', 12860, 2, 1, 'Kiegészítők / Tápegységek ', 0),
(39, 'UTP Cat6 kábel (100 m)', 'Seagate', 'Kiegészítők', 'Vezetékek', 'Kültéri', 'Kiegészítő', 10670, 50, 1, 'Kiegészítők / Vezetékek ', 0),
(40, 'Bosch tűzjelző központ 2 hurok', 'Bosch', 'Tűzjelzők', 'Tűzközpontok', 'Beltéri', 'Címzett', 390490, 7, 1, 'Tűzjelzők / Tűzközpontok ', 0),
(41, 'Honeywell hőérzékelő', 'Honeywell', 'Tűzjelzők', 'Érzékelők', 'IP65', 'EN54', 15010, 0, 1, 'Tűzjelzők / Érzékelők ', 0),
(42, 'Honeywell kézi jelzésadó (törhető)', 'Honeywell', 'Tűzjelzők', 'Kézi jelzésadók', 'Beltéri', 'IP65', 9390, 12, 1, 'Tűzjelzők / Kézi jelzésadók ', 0),
(43, 'Bosch beltéri hangjelző', 'Bosch', 'Tűzjelzők', 'Hang- fényjelzők', 'Beltéri', 'EN54', 12790, 3, 1, 'Tűzjelzők / Hang- fényjelzők ', 0),
(44, 'Inim izolátor modul', 'Inim', 'Tűzjelzők', 'Kiegészítők', 'Beltéri', 'IP65', 38260, 7, 1, 'Tűzjelzők / Kiegészítők ', 0),
(45, 'Tűzálló kábel 2x1.5 (50 m)', 'Bosch', 'Tűzjelzők', 'Tűzkábelek', 'EN54', 'IP65', 25290, 5, 1, 'Tűzjelzők / Tűzkábelek ', 0),
(46, 'Tűzriadó terv tábla (A3)', 'Notifier', 'Tűzjelzők', 'Táblák, naplók', 'IP65', 'Címzett', 5090, 25, 1, 'Tűzjelzők / Táblák, naplók ', 0),
(47, 'Paradox proximity kezelő + kód', 'Paradox', 'Behatolásjelzők', 'Kezelők', 'Kültéri', 'Professzionális', 16160, 25, 1, 'Behatolásjelzők / Kezelők ', 0),
(48, 'Beninca síkmágnes kapuhoz 180 kg', 'Beninca', 'Kaputechnika', 'Síkmágnesek', '24V', 'IP54', 37990, 5, 1, 'Kaputechnika / Síkmágnesek ', 0),
(49, 'Tűzálló kábel (50 m)', 'Western Digital', 'Kiegészítők', 'Vezetékek', 'Beltéri', 'Modul', 13930, 100, 1, 'Kiegészítők / Vezetékek ', 0),
(50, 'Pyronix hibrid riasztóközpont (vezetékes + rádiós)', 'Pyronix', 'Behatolásjelzők', 'Riasztóközpontok', 'Professzionális', 'Modul', 133450, 12, 1, 'Behatolásjelzők / Riasztóközpontok ', 0),
(51, 'Paradox riasztóközpont 8 zónás (bővíthető)', 'Paradox', 'Behatolásjelzők', 'Riasztóközpontok', 'Kültéri', 'Modul', 193680, 7, 1, 'Behatolásjelzők / Riasztóközpontok ', 0),
(52, 'UTP Cat6 kábel (100 m)', 'Mean Well', 'Kiegészítők', 'Vezetékek', 'Modul', 'Professzionális', 24920, 150, 1, 'Kiegészítők / Vezetékek ', 0),
(53, 'Axis mikroSD kártya 128GB', 'Axis', 'CCTV', 'Kiegészítők', 'Kiegészítő', 'Kültéri', 43880, 2, 1, 'CCTV / Kiegészítők ', 0),
(54, 'Notifier sziréna villogóval (piros)', 'Notifier', 'Tűzjelzők', 'Hang- fényjelzők', 'EN54', 'Címzett', 66050, 12, 1, 'Tűzjelzők / Hang- fényjelzők ', 0),
(55, 'Akuvox beltéri monitor (10\")', 'Akuvox', 'Kaputelefon', 'Beltéri egységek', 'Professzionális', 'Modul', 52910, 10, 1, 'Kaputelefon / Beltéri egységek ', 0),
(56, 'Kaputelefon esővédő', 'Hikvision', 'Kaputelefon', 'Kiegészítők', 'Professzionális', 'Modul', 37850, 7, 1, 'Kaputelefon / Kiegészítők ', 0),
(57, 'Texecom érintős kezelőpanel', 'Texecom', 'Behatolásjelzők', 'Kezelők', 'Professzionális', 'Kültéri', 45950, 7, 1, 'Behatolásjelzők / Kezelők ', 0),
(58, 'DSC mikrohullámú sorompó (kültéri)', 'DSC', 'Behatolásjelzők', 'Infra- és mikro sorompók', 'Professzionális', 'Modul', 318460, 3, 1, 'Behatolásjelzők / Infra- és mikro sorompók ', 0),
(59, 'Wi‑Fi router (dual band)', 'APC', 'Kiegészítők', 'Hálózati eszközök', 'Modul', 'Kültéri', 4050, 7, 1, 'Kiegészítők / Hálózati eszközök ', 0),
(60, '2N beltéri audio egység', '2N', 'Kaputelefon', 'Beltéri egységek', 'Kiegészítő', 'Professzionális', 135580, 25, 1, 'Kaputelefon / Beltéri egységek ', 0),
(61, 'Hikvision FullColor kamera (4MP)', 'Hikvision', 'CCTV', 'Kamerák', 'IP67', 'WDR', 97510, 3, 1, 'CCTV / Kamerák ', 0),
(62, 'HID mágneszár készlet ajtóra', 'HID', 'Beléptetők', 'Mágneszárak', 'Kültéri', 'Professzionális', 68100, 7, 1, 'Beléptetők / Mágneszárak ', 0),
(63, 'Gigabit switch (8 port)', 'Western Digital', 'Kiegészítők', 'Hálózati eszközök', 'Kiegészítő', 'Beltéri', 11560, 5, 1, 'Kiegészítők / Hálózati eszközök ', 0),
(64, 'Axis PTZ kamera (4MP) 25x zoom', 'Axis', 'CCTV', 'Kamerák', 'Turret', 'Bullet', 123170, 5, 1, 'CCTV / Kamerák ', 0),
(65, 'ZKTeco mágneszár készlet ajtóra', 'ZKTeco', 'Beléptetők', 'Mágneszárak', 'Beltéri', 'Kiegészítő', 66730, 0, 1, 'Beléptetők / Mágneszárak ', 0),
(66, 'DSC kültéri sziréna villogóval', 'DSC', 'Behatolásjelzők', 'Kiegészítők', 'Beltéri', 'Kültéri', 29490, 25, 1, 'Behatolásjelzők / Kiegészítők ', 0),
(67, 'Zselés akkumulátor 12V 17Ah', 'Mean Well', 'Kiegészítők', 'Akkumulátorok', 'Professzionális', 'Modul', 25830, 25, 1, 'Kiegészítők / Akkumulátorok ', 0),
(68, 'Beninca garázskapu szett (motor + sín)', 'Beninca', 'Kaputechnika', 'Szettek', 'Fotocella', 'Távirányító', 621370, 8, 1, 'Kaputechnika / Szettek ', 0),
(69, 'Bosch kültéri fényjelző', 'Bosch', 'Tűzjelzők', 'Hang- fényjelzők', 'Konvencionális', 'Címzett', 46870, 25, 1, 'Tűzjelzők / Hang- fényjelzők ', 0),
(70, 'Notifier kültéri fényjelző', 'Notifier', 'Tűzjelzők', 'Hang- fényjelzők', 'Konvencionális', 'Beltéri', 47680, 5, 1, 'Tűzjelzők / Hang- fényjelzők ', 0),
(71, 'Paradox kültéri dual technológiás érzékelő', 'Paradox', 'Behatolásjelzők', 'Érzékelők', 'Modul', 'Professzionális', 26190, 7, 1, 'Behatolásjelzők / Érzékelők ', 0),
(72, 'Generic kaputelefon szett (1 kültéri + 1 beltéri)', 'Generic', 'Kaputelefon', 'Szettek', 'Kültéri', 'Kiegészítő', 190670, 3, 1, 'Kaputelefon / Szettek ', 0),
(73, 'Dahua beltéri audio egység', 'Dahua', 'Kaputelefon', 'Beltéri egységek', 'Kiegészítő', 'Professzionális', 100090, 2, 1, 'Kaputelefon / Beltéri egységek ', 0),
(74, 'Pyronix négy nyalábos infra sorompó (kültéri)', 'Pyronix', 'Behatolásjelzők', 'Infra- és mikro sorompók', 'Beltéri', 'Kültéri', 375330, 12, 1, 'Behatolásjelzők / Infra- és mikro sorompók ', 0),
(75, 'Kapu vevő + távirányító', 'Beninca', 'Kaputechnika', 'Kiegészítők', 'Fotocella', 'Távirányító', 48830, 0, 1, 'Kaputechnika / Kiegészítők ', 0),
(76, 'Beninca síkmágnes kapuhoz 280 kg', 'Beninca', 'Kaputechnika', 'Síkmágnesek', 'Távirányító', 'Fotocella', 41800, 7, 1, 'Kaputechnika / Síkmágnesek ', 0),
(77, 'Jablotron kültéri sziréna villogóval', 'Jablotron', 'Behatolásjelzők', 'Kiegészítők', 'Modul', 'Kiegészítő', 20980, 5, 1, 'Behatolásjelzők / Kiegészítők ', 0),
(78, 'Axis NVR 8 csatornás (4K)', 'Axis', 'CCTV', 'Rögzítők', 'Kiegészítő', 'Kültéri', 157410, 10, 1, 'CCTV / Rögzítők ', 0),
(79, 'Texecom riasztóközpont 8 zónás (bővíthető)', 'Texecom', 'Behatolásjelzők', 'Riasztóközpontok', 'Kiegészítő', 'Beltéri', 151940, 0, 1, 'Behatolásjelzők / Riasztóközpontok ', 0),
(80, 'HID síkmágnes külső ajtóra', 'HID', 'Beléptetők', 'Síkmágnesek', 'Kiegészítő', 'Kültéri', 48100, 3, 1, 'Beléptetők / Síkmágnesek ', 0),
(81, 'HID vésznyitó gomb (break glass)', 'HID', 'Beléptetők', 'Kiegészítők', 'Kültéri', 'Kiegészítő', 16510, 10, 1, 'Beléptetők / Kiegészítők ', 0),
(82, 'Uniview UPS (kisegítő táp)', 'Uniview', 'CCTV', 'Kiegészítők', 'Kiegészítő', 'Modul', 33040, 7, 1, 'CCTV / Kiegészítők ', 0),
(83, 'Kapu vevő + távirányító', 'Nice', 'Kaputechnika', 'Kiegészítők', '230V', '24V', 2570, 0, 1, 'Kaputechnika / Kiegészítők ', 0),
(84, 'HID kilépés érzékelő (IR)', 'HID', 'Beléptetők', 'Kiegészítők', 'Kültéri', 'Professzionális', 2630, 0, 1, 'Beléptetők / Kiegészítők ', 0),
(85, 'Tűzálló kábel 2x1.5 (50 m)', 'Honeywell', 'Tűzjelzők', 'Tűzkábelek', 'Beltéri', 'EN54', 20530, 3, 1, 'Tűzjelzők / Tűzkábelek ', 0),
(86, 'Krimpelő fogó RJ45-hez', 'Generic', 'Kiegészítők', 'Szerszámok', 'Modul', 'Kültéri', 19530, 7, 1, 'Kiegészítők / Szerszámok ', 0),
(87, 'Generic redőnymotor vezérlő (RF)', 'Generic', 'Kaputechnika', 'Redőnymozgatás', '230V', 'IP54', 77520, 3, 1, 'Kaputechnika / Redőnymozgatás ', 0),
(88, 'Gigabit switch (8 port)', 'Generic', 'Kiegészítők', 'Hálózati eszközök', 'Kiegészítő', 'Kültéri', 55100, 12, 1, 'Kiegészítők / Hálózati eszközök ', 0),
(89, 'Kapu villogó lámpa', 'Nice', 'Kaputechnika', 'Kiegészítők', 'Fotocella', 'IP54', 9330, 7, 1, 'Kaputechnika / Kiegészítők ', 0),
(90, 'Generic sziréna villogóval (piros)', 'Generic', 'Tűzjelzők', 'Hang- fényjelzők', 'Konvencionális', 'EN54', 36430, 12, 1, 'Tűzjelzők / Hang- fényjelzők ', 0),
(91, 'Jablotron rádiós vevőmodul', 'Jablotron', 'Behatolásjelzők', 'Kiegészítők', 'Kiegészítő', 'Beltéri', 1500, 12, 1, 'Behatolásjelzők / Kiegészítők ', 0),
(92, 'Inim tűzjelző központ 2 hurok', 'Inim', 'Tűzjelzők', 'Tűzközpontok', 'Címzett', 'Beltéri', 983060, 25, 1, 'Tűzjelzők / Tűzközpontok ', 0),
(93, 'ZKTeco elektromos zárfogadó (fail-secure)', 'ZKTeco', 'Beléptetők', 'Mágneszárak', 'Professzionális', 'Kiegészítő', 55730, 7, 1, 'Beléptetők / Mágneszárak ', 0),
(94, 'Inim hőérzékelő', 'Inim', 'Tűzjelzők', 'Érzékelők', 'Címzett', 'EN54', 28970, 10, 1, 'Tűzjelzők / Érzékelők ', 0),
(95, 'Seagate Surveillance HDD 2TB', 'Seagate', 'Kiegészítők', 'Merevlemezek', 'Professzionális', 'Kiegészítő', 34960, 25, 1, 'Kiegészítők / Merevlemezek ', 0),
(96, 'Rosslare 2 ajtós beléptető vezérlő', 'Rosslare', 'Beléptetők', 'Vezérlők', 'Kültéri', 'Kiegészítő', 95970, 10, 1, 'Beléptetők / Vezérlők ', 0),
(97, 'ZKTeco vésznyitó gomb (break glass)', 'ZKTeco', 'Beléptetők', 'Kiegészítők', 'Modul', 'Professzionális', 11570, 10, 1, 'Beléptetők / Kiegészítők ', 0),
(98, 'EM-Marine RFID kártya (125 kHz)', 'Generic', 'Beléptetők', 'Kártyák, tag-ek', 'EM-Marine', 'MIFARE', 1670, 50, 1, 'Beléptetők / Kártyák, tag-ek ', 0),
(99, 'Axis DVR 16 csatornás (1080p)', 'Axis', 'CCTV', 'Rögzítők', 'Kiegészítő', 'Professzionális', 211910, 5, 1, 'CCTV / Rögzítők ', 0),
(100, 'Beltéri sziréna 12V', 'APC', 'Kiegészítők', 'Hang- fényjelzők', 'Kültéri', 'Kiegészítő', 10610, 7, 1, 'Kiegészítők / Hang- fényjelzők ', 0),
(101, 'Tűzálló kábel (50 m)', 'Western Digital', 'Kiegészítők', 'Vezetékek', 'Modul', 'Kiegészítő', 27680, 200, 1, 'Kiegészítők / Vezetékek ', 0),
(102, 'Generic síkmágnes kapuhoz 180 kg', 'Generic', 'Kaputechnika', 'Síkmágnesek', '230V', 'Távirányító', 47840, 10, 1, 'Kaputechnika / Síkmágnesek ', 0),
(103, 'Rosslare elektromos zárfogadó (fail-safe)', 'Rosslare', 'Beléptetők', 'Mágneszárak', 'Beltéri', 'Kültéri', 33580, 5, 1, 'Beléptetők / Mágneszárak ', 0),
(104, 'Notifier optikai füstérzékelő', 'Notifier', 'Tűzjelzők', 'Érzékelők', 'Címzett', 'Beltéri', 22150, 5, 1, 'Tűzjelzők / Érzékelők ', 0),
(105, 'Pyronix érintős kezelőpanel', 'Pyronix', 'Behatolásjelzők', 'Kezelők', 'Modul', 'Kültéri', 21220, 5, 1, 'Behatolásjelzők / Kezelők ', 0),
(106, 'Zselés akkumulátor 12V 7Ah', 'Seagate', 'Kiegészítők', 'Akkumulátorok', 'Professzionális', 'Kültéri', 53510, 0, 1, 'Kiegészítők / Akkumulátorok ', 0),
(107, 'Seagate tápegység 12V 5A', 'Seagate', 'Kiegészítők', 'Tápegységek', 'Kültéri', 'Kiegészítő', 12920, 7, 1, 'Kiegészítők / Tápegységek ', 0),
(108, 'Paradox LED kezelő (kódpanel)', 'Paradox', 'Behatolásjelzők', 'Kezelők', 'Kiegészítő', 'Professzionális', 60010, 7, 1, 'Behatolásjelzők / Kezelők ', 0),
(109, 'Axis turret kamera (4MP) PoE', 'Axis', 'CCTV', 'Kamerák', 'WDR', 'Bullet', 50190, 0, 1, 'CCTV / Kamerák ', 0),
(110, 'Paradox távfelügyeleti kommunikátor (IP/GSM)', 'Paradox', 'Behatolásjelzők', 'Kiegészítők', 'Professzionális', 'Beltéri', 21130, 2, 1, 'Behatolásjelzők / Kiegészítők ', 0),
(111, 'Tűzálló kábel 2x1.5 (50 m)', 'Bosch', 'Tűzjelzők', 'Tűzkábelek', 'EN54', 'Címzett', 47090, 7, 1, 'Tűzjelzők / Tűzkábelek ', 0),
(112, 'HID MIFARE olvasó, falon kívüli', 'HID', 'Beléptetők', 'Önálló olvasók', 'Professzionális', 'Kültéri', 140230, 12, 1, 'Beléptetők / Önálló olvasók ', 0),
(113, 'Generic garázskapu motor (beltéri)', 'Generic', 'Kaputechnika', 'Motorok', '230V', 'Távirányító', 237610, 25, 1, 'Kaputechnika / Motorok ', 0),
(114, 'LTE kommunikátor (riasztó)', 'Seagate', 'Kiegészítők', 'Kommunikátorok', 'Professzionális', 'Beltéri', 105730, 0, 1, 'Kiegészítők / Kommunikátorok ', 0),
(115, 'Dahua beltéri audio egység', 'Dahua', 'Kaputelefon', 'Beltéri egységek', 'Beltéri', 'Kültéri', 99130, 7, 1, 'Kaputelefon / Beltéri egységek ', 0),
(116, 'DSC kültéri sziréna villogóval', 'DSC', 'Behatolásjelzők', 'Kiegészítők', 'Kültéri', 'Beltéri', 23590, 2, 1, 'Behatolásjelzők / Kiegészítők ', 0),
(117, 'Inim izolátor modul', 'Inim', 'Tűzjelzők', 'Kiegészítők', 'Konvencionális', 'EN54', 49630, 25, 1, 'Tűzjelzők / Kiegészítők ', 0),
(118, 'Kültéri sziréna villogóval', 'Western Digital', 'Kiegészítők', 'Hang- fényjelzők', 'Beltéri', 'Kültéri', 26150, 25, 1, 'Kiegészítők / Hang- fényjelzők ', 0),
(119, 'Rosslare vezérlőpanel (PoE)', 'Rosslare', 'Beléptetők', 'Vezérlők', 'Kiegészítő', 'Beltéri', 111620, 5, 1, 'Beléptetők / Vezérlők ', 0),
(120, 'Jablotron LCD kezelő (magyar menü)', 'Jablotron', 'Behatolásjelzők', 'Kezelők', 'Modul', 'Kültéri', 66040, 3, 1, 'Behatolásjelzők / Kezelők ', 0),
(121, 'Dahua 4 kamerás PoE szett (NVR + kamerák)', 'Dahua', 'CCTV', 'Szettek', 'Professzionális', 'Modul', 134350, 7, 1, 'CCTV / Szettek ', 0),
(122, 'Fotocella pár (kapuhoz)', 'Beninca', 'Kaputechnika', 'Kiegészítők', 'Távirányító', '230V', 39380, 7, 1, 'Kaputechnika / Kiegészítők ', 0),
(123, 'Generic mikroSD kártya 128GB', 'Generic', 'CCTV', 'Kiegészítők', 'Beltéri', 'Professzionális', 42440, 25, 1, 'CCTV / Kiegészítők ', 0),
(124, 'Texecom érintős kezelőpanel', 'Texecom', 'Behatolásjelzők', 'Kezelők', 'Beltéri', 'Professzionális', 62440, 7, 1, 'Behatolásjelzők / Kezelők ', 0),
(125, 'Hikvision 4 kamerás analóg szett (DVR + kamerák)', 'Hikvision', 'CCTV', 'Szettek', 'Modul', 'Beltéri', 353910, 0, 1, 'CCTV / Szettek ', 0),
(126, 'Bosch beltéri hangjelző', 'Bosch', 'Tűzjelzők', 'Hang- fényjelzők', 'Konvencionális', 'Címzett', 50500, 25, 1, 'Tűzjelzők / Hang- fényjelzők ', 0),
(127, 'Tűzálló kábel 2x2.5 (50 m)', 'Generic', 'Tűzjelzők', 'Tűzkábelek', 'Beltéri', 'Konvencionális', 41270, 1, 1, 'Tűzjelzők / Tűzkábelek ', 0),
(128, 'Texecom érintős kezelőpanel', 'Texecom', 'Behatolásjelzők', 'Kezelők', 'Kültéri', 'Modul', 39290, 2, 1, 'Behatolásjelzők / Kezelők ', 0),
(129, 'Axis DVR 16 csatornás (1080p)', 'Axis', 'CCTV', 'Rögzítők', 'Professzionális', 'Beltéri', 124430, 12, 1, 'CCTV / Rögzítők ', 0),
(130, 'Beltéri sziréna 12V', 'APC', 'Kiegészítők', 'Hang- fényjelzők', 'Modul', 'Beltéri', 28750, 7, 1, 'Kiegészítők / Hang- fényjelzők ', 0),
(131, 'Wi‑Fi router (dual band)', 'APC', 'Kiegészítők', 'Hálózati eszközök', 'Kiegészítő', 'Beltéri', 4170, 25, 1, 'Kiegészítők / Hálózati eszközök ', 0),
(132, 'Hikvision DVR 8 csatornás (1080p)', 'Hikvision', 'CCTV', 'Rögzítők', 'Kiegészítő', 'Beltéri', 234010, 25, 1, 'CCTV / Rögzítők ', 0),
(133, 'Dahua beltéri monitor (10\")', 'Dahua', 'Kaputelefon', 'Beltéri egységek', 'Kiegészítő', 'Professzionális', 72920, 7, 1, 'Kaputelefon / Beltéri egységek ', 0),
(134, 'Honeywell tűzjelző központ 1 hurok', 'Honeywell', 'Tűzjelzők', 'Tűzközpontok', 'Címzett', 'Konvencionális', 975770, 5, 1, 'Tűzjelzők / Tűzközpontok ', 0),
(135, 'Tűzálló kábel 2x1.5 (50 m)', 'Generic', 'Tűzjelzők', 'Tűzkábelek', 'EN54', 'Címzett', 46230, 12, 1, 'Tűzjelzők / Tűzkábelek ', 0),
(136, 'Mean Well Surveillance HDD 2TB', 'Mean Well', 'Kiegészítők', 'Merevlemezek', 'Kiegészítő', 'Modul', 24610, 3, 1, 'Kiegészítők / Merevlemezek ', 0),
(137, 'Generic kézi jelzésadó (resetelhető)', 'Generic', 'Tűzjelzők', 'Kézi jelzésadók', 'Beltéri', 'Címzett', 14490, 25, 1, 'Tűzjelzők / Kézi jelzésadók ', 0),
(138, 'Akuvox síkmágnes külső ajtóra', 'Akuvox', 'Beléptetők', 'Síkmágnesek', 'Kültéri', 'Professzionális', 24830, 12, 1, 'Beléptetők / Síkmágnesek ', 0),
(139, 'HID önálló RFID olvasó (IP65)', 'HID', 'Beléptetők', 'Önálló olvasók', 'Modul', 'Professzionális', 141580, 12, 1, 'Beléptetők / Önálló olvasók ', 0),
(140, 'Kábelkötegelő (100 db)', 'Mean Well', 'Kiegészítők', 'Segédanyagok', 'Professzionális', 'Kiegészítő', 12710, 200, 1, 'Kiegészítők / Segédanyagok ', 0),
(141, 'ZKTeco önálló RFID olvasó (IP65)', 'ZKTeco', 'Beléptetők', 'Önálló olvasók', 'Modul', 'Professzionális', 103230, 25, 1, 'Beléptetők / Önálló olvasók ', 0),
(142, 'Generic mikroSD kártya 128GB', 'Generic', 'CCTV', 'Kiegészítők', 'Modul', 'Kültéri', 32890, 25, 1, 'CCTV / Kiegészítők ', 0),
(143, 'ZKTeco MIFARE olvasó, falon kívüli', 'ZKTeco', 'Beléptetők', 'Önálló olvasók', 'Kiegészítő', 'Beltéri', 77730, 5, 1, 'Beléptetők / Önálló olvasók ', 0),
(144, 'Notifier kézi jelzésadó (resetelhető)', 'Notifier', 'Tűzjelzők', 'Kézi jelzésadók', 'Beltéri', 'Címzett', 20430, 12, 1, 'Tűzjelzők / Kézi jelzésadók ', 0),
(145, 'Rack szekrény 9U falra szerelhető', 'APC', 'Kiegészítők', 'Rack szekrények', 'Beltéri', 'Kiegészítő', 91350, 10, 1, 'Kiegészítők / Rack szekrények ', 0),
(146, 'Dahua mikroSD kártya 128GB', 'Dahua', 'CCTV', 'Kiegészítők', 'Kültéri', 'Kiegészítő', 39420, 0, 1, 'CCTV / Kiegészítők ', 0),
(147, 'Gigabit switch (8 port)', 'Western Digital', 'Kiegészítők', 'Hálózati eszközök', 'Modul', 'Kiegészítő', 80910, 7, 1, 'Kiegészítők / Hálózati eszközök ', 0),
(148, 'LED reflektor 50W (IP65)', 'Mean Well', 'Kiegészítők', 'LED reflektorok', 'Modul', 'Kiegészítő', 58230, 12, 1, 'Kiegészítők / LED reflektorok ', 0),
(149, 'Generic mágneszár készlet ajtóra', 'Generic', 'Beléptetők', 'Mágneszárak', 'Kültéri', 'Modul', 63570, 2, 1, 'Beléptetők / Mágneszárak ', 0);

-- --------------------------------------------------------

--
-- Table structure for table `rate_limits`
--

DROP TABLE IF EXISTS `rate_limits`;
CREATE TABLE `rate_limits` (
  `id` int(12) NOT NULL,
  `rate_key` varchar(255) NOT NULL,
  `hits` int(11) NOT NULL,
  `last_hit` int(11) NOT NULL,
  `expires_at` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `rate_limits`
--

INSERT INTO `rate_limits` (`id`, `rate_key`, `hits`, `last_hit`, `expires_at`) VALUES
(1, 'login:::1', 2, 1774451614, 0),
(2, 'admin-product-delete:5', 1, 1774450422, 0),
(3, 'admin-product-stock:5', 4, 1774450577, 0),
(5, 'signup:::1', 1, 1774451571, 0);

--
-- Triggers `rate_limits`
--
DROP TRIGGER IF EXISTS `trg_rate_limits_cleanup_ins`;
DELIMITER $$
CREATE TRIGGER `trg_rate_limits_cleanup_ins` AFTER INSERT ON `rate_limits` FOR EACH ROW BEGIN
                    DELETE FROM rate_limits
                    WHERE expires_at > 0 AND expires_at <= UNIX_TIMESTAMP();
                END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `trg_rate_limits_cleanup_upd`;
DELIMITER $$
CREATE TRIGGER `trg_rate_limits_cleanup_upd` AFTER UPDATE ON `rate_limits` FOR EACH ROW BEGIN
                    DELETE FROM rate_limits
                    WHERE expires_at > 0 AND expires_at <= UNIX_TIMESTAMP();
                END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reservations`
--

DROP TABLE IF EXISTS `reservations`;
CREATE TABLE `reservations` (
  `id` int(10) UNSIGNED NOT NULL,
  `message` char(255) NOT NULL,
  `reservation_date` datetime NOT NULL DEFAULT current_timestamp(),
  `location` enum('Helyszíni kiszállás','Telefonos egyeztetés','Telephelyen') NOT NULL DEFAULT 'Telephelyen',
  `service` enum('Riasztórdsz. konzultáció','Tűzjelző konzultáció','Kamerardsz. felmérés','Kaputelefon egyeztetés','Gyengeáramú kivitelezés','GPS nyomkövetés bemutató') NOT NULL DEFAULT 'Riasztórdsz. konzultáció',
  `duration` time NOT NULL,
  `reservation_submitted` datetime NOT NULL DEFAULT current_timestamp(),
  `user_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(10) UNSIGNED NOT NULL,
  `username` varchar(32) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `role` enum('user','admin') NOT NULL DEFAULT 'user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`id`, `username`, `first_name`, `last_name`, `email`, `created_at`, `role`) VALUES
(1, 'mintapeti123', 'Péter', 'Minta', 'mintapeter@citromail.hu', '2026-01-06 11:02:48', 'user'),
(2, 'jackgypsum', 'Jakab', 'Gipsz', 'gipszj@freemail.hu', '2026-01-06 11:06:03', 'user'),
(3, 'testuser', 'Test', 'User', 'test@example.com', '2026-01-26 12:47:12', 'user'),
(4, 'testuser2', 'Test', 'User', 'test2@example.com', '2026-01-27 10:16:47', 'user'),
(5, 'john_doe', 'John', 'Doe', 'john@example.com', '2026-02-09 12:27:01', 'admin'),
(6, 'john_doe2', '', '', 'john2@example.com', '2026-02-10 11:30:32', 'user'),
(7, 'frontendform_1', 'Front', 'End', 'frontend1@example.com', '2026-03-25 16:07:43', 'user'),
(8, 'rakoskaa', 'Akos', 'Gonda', 'mikemorley0110@gmail.com', '2026-03-25 16:12:51', 'user'),
(9, 'czehszabi', 'Szabolcs', 'Czéh', 'czehszabi@gmail.com', '2026-03-30 15:50:08', 'user'),
(10, 'jani01', 'Ömböli', 'János', 'jnia@jfdksla.fda', '2026-03-30 16:15:33', 'user');

-- --------------------------------------------------------

--
-- Table structure for table `user_secret`
--

DROP TABLE IF EXISTS `user_secret`;
CREATE TABLE `user_secret` (
  `id` int(10) UNSIGNED NOT NULL,
  `password` varchar(255) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `username` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `user_secret`
--

INSERT INTO `user_secret` (`id`, `password`, `address`, `username`) VALUES
(1, '123445678', '7630 Pécs, Diósi út 42.', 'mintapeti123'),
(2, '123445678', '7630 Pécs, Diósi út 42.', 'jackgypsum'),
(3, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, 'testuser'),
(4, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, 'testuser2'),
(5, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, 'john_doe'),
(6, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, 'john_doe2'),
(7, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, 'frontendform_1'),
(8, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, 'rakoskaa'),
(9, 'd77c63d2083b13c20b3c708a6e9a3d2480e7bfe2c68e0860f9c0832d4f2aa308', NULL, 'czehszabi'),
(10, '6cb35d4af024a5a6e602d4c54af0887afedd7b00897933bb1d07612ad0a31501', NULL, 'jani01');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_orders_user_id` (`user_id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `orders_id` (`orders_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `rate_limits`
--
ALTER TABLE `rate_limits`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_rate_key` (`rate_key`);

--
-- Indexes for table `reservations`
--
ALTER TABLE `reservations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `reservation_date` (`reservation_date`),
  ADD KEY `fk_res_user_id` (`user_id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username_unique` (`username`),
  ADD UNIQUE KEY `email_unique` (`email`);

--
-- Indexes for table `user_secret`
--
ALTER TABLE `user_secret`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_sec_username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `product`
--
ALTER TABLE `product`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=152;

--
-- AUTO_INCREMENT for table `rate_limits`
--
ALTER TABLE `rate_limits`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `reservations`
--
ALTER TABLE `reservations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `user_secret`
--
ALTER TABLE `user_secret`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_orders_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_order_items_orders_id` FOREIGN KEY (`orders_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_order_items_product_id` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `reservations`
--
ALTER TABLE `reservations`
  ADD CONSTRAINT `fk_res_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `user_secret`
--
ALTER TABLE `user_secret`
  ADD CONSTRAINT `fk_sec_username` FOREIGN KEY (`username`) REFERENCES `user` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
