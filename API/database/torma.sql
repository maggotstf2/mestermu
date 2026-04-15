-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Apr 08, 2026 at 12:02 PM
-- Server version: 9.6.0
-- PHP Version: 8.5.4

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
CREATE DATABASE IF NOT EXISTS `torma` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
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

    -- Rendelés összegének frissítése
    UPDATE orders
    SET sum = sum + vSubtotal
    WHERE id = pOrderId;
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `createOrder` (IN `pUsername` VARCHAR(32), IN `pShipName` VARCHAR(128), IN `pShipPhone` VARCHAR(32), IN `pShipEmail` VARCHAR(128), IN `pShipZip` VARCHAR(16), IN `pShipCity` VARCHAR(64), IN `pShipAddressLine` VARCHAR(255), IN `pShipNote` VARCHAR(255))   BEGIN
    DECLARE vUserId INTEGER UNSIGNED;
    DECLARE vShipName VARCHAR(128);
    DECLARE vShipPhone VARCHAR(32);
    DECLARE vShipEmail VARCHAR(128);
    DECLARE vShipZip VARCHAR(16);
    DECLARE vShipCity VARCHAR(64);
    DECLARE vShipAddressLine VARCHAR(255);
    DECLARE vShipNote VARCHAR(255);

    SELECT id
      INTO vUserId
    FROM user
    WHERE username = pUsername;

    IF vUserId IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid username (user not found)';
    END IF;

    SET vShipName = NULLIF(TRIM(pShipName), '');
    SET vShipPhone = NULLIF(TRIM(pShipPhone), '');
    SET vShipEmail = NULLIF(TRIM(pShipEmail), '');
    SET vShipZip = NULLIF(TRIM(pShipZip), '');
    SET vShipCity = NULLIF(TRIM(pShipCity), '');
    SET vShipAddressLine = NULLIF(TRIM(pShipAddressLine), '');
    SET vShipNote = NULLIF(TRIM(pShipNote), '');

    IF vShipName IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Shipping name is required';
    END IF;
    IF vShipPhone IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Shipping phone is required';
    END IF;
    IF vShipEmail IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Shipping email is required';
    END IF;
    IF vShipZip IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Shipping ZIP is required';
    END IF;
    IF vShipCity IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Shipping city is required';
    END IF;
    IF vShipAddressLine IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Shipping address is required';
    END IF;

    INSERT INTO orders (
        user_id,
        order_date,
        status,
        sum,
        ship_full_name,
        ship_phone,
        ship_email,
        ship_zip,
        ship_city,
        ship_address_line,
        ship_note
    )
    VALUES (
        vUserId,
        NOW(),
        'Processing',
        0,
        vShipName,
        vShipPhone,
        vShipEmail,
        vShipZip,
        vShipCity,
        vShipAddressLine,
        vShipNote
    );
    
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `createReservation` (IN `pService` VARCHAR(64), IN `pReservationDate` DATE, IN `pReservationTime` TIME, IN `pLocation` VARCHAR(64), IN `pName` VARCHAR(128), IN `pPhone` VARCHAR(32), IN `pEmail` VARCHAR(128), IN `pNote` VARCHAR(255), IN `pUsername` VARCHAR(32))   BEGIN
    DECLARE vLocation VARCHAR(64);
    DECLARE vService VARCHAR(64);
    DECLARE vName VARCHAR(128);
    DECLARE vPhone VARCHAR(32);
    DECLARE vEmail VARCHAR(128);
    DECLARE vNote VARCHAR(255);
    DECLARE vUserId INT(10) UNSIGNED;
    DECLARE vErrText VARCHAR(255);

    SET vLocation = TRIM(pLocation);
    SET vService = TRIM(pService);
    SET vName = TRIM(pName);
    SET vPhone = TRIM(pPhone);
    SET vEmail = TRIM(pEmail);
    SET vNote = TRIM(pNote);

    IF vLocation NOT IN ('Phone consultation','At our office') THEN
        SET vErrText = CONCAT('Invalid location: "', COALESCE(vLocation, 'NULL'), '"');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = vErrText;
    END IF;

    IF vService NOT IN (
        'Alarm system consultation',
        'Fire alarm consultation',
        'Camera system survey',
        'Access control / intercom consultation',
        'Low-voltage installation',
        'GPS tracking demo'
    ) THEN
        SET vErrText = CONCAT('Invalid service: "', COALESCE(vService, 'NULL'), '"');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = vErrText;
    END IF;

    IF vName IS NULL OR vName = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Name is required';
    END IF;

    IF vPhone IS NULL OR vPhone = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phone is required';
    END IF;

    IF vEmail IS NULL OR vEmail = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email is required';
    END IF;

    -- user_id opcionális: ha van username, linkeljük, ha nincs, NULL.
    IF pUsername IS NOT NULL AND TRIM(pUsername) <> '' THEN
        SELECT id INTO vUserId FROM user WHERE username = pUsername LIMIT 1;
    ELSE
        SET vUserId = NULL;
    END IF;

    INSERT INTO reservations (
        service,
        reservation_date,
        reservation_time,
        location,
        customer_name,
        customer_phone,
        customer_email,
        note,
        duration,
        user_id
    )
    VALUES (
        vService,
        pReservationDate,
        pReservationTime,
        vLocation,
        vName,
        vPhone,
        vEmail,
        NULLIF(vNote, ''),
        '00:00:00',
        vUserId
    );
END$$

DROP PROCEDURE IF EXISTS `createReservationPublic`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `createReservationPublic` (IN `pService` VARCHAR(64), IN `pReservationDate` DATE, IN `pReservationTime` TIME, IN `pLocation` VARCHAR(64), IN `pName` VARCHAR(128), IN `pPhone` VARCHAR(32), IN `pEmail` VARCHAR(128), IN `pNote` VARCHAR(255))   BEGIN
    CALL createReservation(pService, pReservationDate, pReservationTime, pLocation, pName, pPhone, pEmail, pNote, NULL);
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
    DECLARE vOldSubtotal INT UNSIGNED;

    SELECT subtotal
      INTO vOldSubtotal
    FROM order_items
    WHERE product_id=pProductId AND orders_id=pOrdersId
    LIMIT 1;

    DELETE FROM order_items
    WHERE product_id=pProductId AND orders_id=pOrdersId;

    IF vOldSubtotal IS NOT NULL THEN
        UPDATE orders
        SET sum = GREATEST(sum - vOldSubtotal, 0)
        WHERE id = pOrdersId;
    END IF;
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

DROP PROCEDURE IF EXISTS `getAllReservations`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllReservations` ()   BEGIN
    SELECT 
        r.id AS "Foglalás Azonosító", 
        r.customer_name AS "Név",
        r.customer_phone AS "Telefon",
        r.customer_email AS "Email",
        r.service AS "Szolgáltatás",
        r.reservation_date AS "Dátum",
        r.reservation_time AS "Időpont",
        r.location AS "Helyszín",
        r.note AS "Megjegyzés",
        r.duration AS "Admin által szabott időtartam", 
        r.reservation_submitted AS "Rögzítve"
    FROM reservations r
    JOIN user u ON r.user_id = u.id
    ORDER BY r.reservation_date ASC;
END$$

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
        CONCAT(o.ship_zip, ' ', o.ship_city, ', ', o.ship_address_line) AS "Szállítási cím",
        o.status AS "Állapot"
    FROM orders o
    JOIN user u ON o.user_id = u.id
    WHERE u.username = pUsername
    ORDER BY o.order_date DESC;
END$$

DROP PROCEDURE IF EXISTS `getUserReservations`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserReservations` (IN `pUsername` VARCHAR(32))   BEGIN
    SELECT 
        r.id AS "Foglalás Azonosító", 
        r.customer_name AS "Név",
        r.customer_phone AS "Telefon",
        r.customer_email AS "Email",
        r.service AS "Szolgáltatás",
        r.reservation_date AS "Dátum",
        r.reservation_time AS "Időpont",
        r.location AS "Helyszín",
        r.note AS "Megjegyzés",
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
    DECLARE vOldSubtotal INT UNSIGNED;

    IF pNewQuantity = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be > 0';
    END IF;

    -- Aktuális mennyiség lekérése a tételből (és zárolás a módosításhoz)
    SELECT quantity
      INTO vOldQuantity
    FROM order_items
    WHERE orders_id = pOrderId AND product_id = pProductId
    FOR UPDATE;
    SELECT subtotal
      INTO vOldSubtotal
    FROM order_items
    WHERE orders_id = pOrderId AND product_id = pProductId
    FOR UPDATE;

    IF vOldSubtotal IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order item not found';
    END IF;


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

    UPDATE product
    SET quantity = quantity - vDelta
    WHERE id = pProductId;

    UPDATE orders
    SET sum = GREATEST(sum + (vNewSubtotal - vOldSubtotal), 0)
    WHERE id = pOrderId;
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateReservation` (IN `pId` INTEGER UNSIGNED, IN `pService` VARCHAR(64), IN `pReservationDate` DATE, IN `pReservationTime` TIME, IN `pLocation` VARCHAR(64), IN `pName` VARCHAR(128), IN `pPhone` VARCHAR(32), IN `pEmail` VARCHAR(128), IN `pNote` VARCHAR(255))   BEGIN
    DECLARE vLocation VARCHAR(64);
    DECLARE vService VARCHAR(64);
    DECLARE vName VARCHAR(128);
    DECLARE vPhone VARCHAR(32);
    DECLARE vEmail VARCHAR(128);
    DECLARE vNote VARCHAR(255);
    DECLARE vErrText VARCHAR(255);

    SET vLocation = TRIM(pLocation);
    SET vService = TRIM(pService);
    SET vName = TRIM(pName);
    SET vPhone = TRIM(pPhone);
    SET vEmail = TRIM(pEmail);
    SET vNote = TRIM(pNote);

    IF vLocation NOT IN ('Phone consultation','At our office') THEN
        SET vErrText = CONCAT('Invalid location: "', COALESCE(vLocation, 'NULL'), '"');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = vErrText;
    END IF;

    IF vService NOT IN (
        'Alarm system consultation',
        'Fire alarm consultation',
        'Camera system survey',
        'Access control / intercom consultation',
        'Low-voltage installation',
        'GPS tracking demo'
    ) THEN
        SET vErrText = CONCAT('Invalid service: "', COALESCE(vService, 'NULL'), '"');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = vErrText;
    END IF;

    UPDATE reservations
    SET 
        service = vService,
        reservation_date = pReservationDate,
        reservation_time = pReservationTime,
        location = vLocation,
        customer_name = vName,
        customer_phone = vPhone,
        customer_email = vEmail,
        note = NULLIF(vNote, '')
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
CREATE TABLE IF NOT EXISTS `orders` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `sum` int NOT NULL DEFAULT '0',
  `status` varchar(64) NOT NULL DEFAULT 'Processing',
  `user_id` int UNSIGNED NOT NULL,
  `ship_full_name` varchar(128) NOT NULL,
  `ship_phone` varchar(32) NOT NULL,
  `ship_email` varchar(128) NOT NULL,
  `ship_zip` varchar(16) NOT NULL,
  `ship_city` varchar(64) NOT NULL,
  `ship_address_line` varchar(255) NOT NULL,
  `ship_note` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_orders_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

DROP TABLE IF EXISTS `order_items`;
CREATE TABLE IF NOT EXISTS `order_items` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `orders_id` int UNSIGNED NOT NULL,
  `product_id` int UNSIGNED NOT NULL,
  `quantity` smallint UNSIGNED NOT NULL,
  `subtotal` int UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  KEY `orders_id` (`orders_id`),
  KEY `product_id` (`product_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product`
--

DROP TABLE IF EXISTS `product`;
CREATE TABLE IF NOT EXISTS `product` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  `brand` varchar(32) NOT NULL,
  `cat` varchar(32) NOT NULL,
  `subcat` varchar(32) NOT NULL,
  `tag1` varchar(64) NOT NULL,
  `tag2` varchar(64) NOT NULL,
  `price` int UNSIGNED NOT NULL,
  `quantity` smallint UNSIGNED NOT NULL,
  `in_stock` tinyint(1) NOT NULL DEFAULT '1',
  `description` varchar(1024) NOT NULL,
  `is_bundled` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=152 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `product`
--

INSERT INTO `product` (`id`, `name`, `brand`, `cat`, `subcat`, `tag1`, `tag2`, `price`, `quantity`, `in_stock`, `description`, `is_bundled`) VALUES
(1, 'Paradox PIR motion detector (indoor)', 'Paradox', 'Intrusion systems', 'Sensors', 'Outdoor', 'Professional', 29520, 13, 1, 'Intrusion systems / Sensors ', 0),
(2, 'Paradox LED keypad (keypad)', 'Paradox', 'Intrusion systems', 'Keypads', 'Indoor', 'Professional', 61360, 12, 1, 'Intrusion systems / Keypads ', 0),
(3, 'Paradox control panel 8 zone (expandable)', 'Paradox', 'Intrusion systems', 'Control panels', 'Professional', 'Outdoor', 88100, 0, 1, 'Intrusion systems / Control panels ', 0),
(4, 'Jablotron microwave barrier gate (outdoor)', 'Jablotron', 'Intrusion systems', 'Infrared & microwave barriers', 'Professional', 'Module', 214450, 25, 1, 'Intrusion systems / Infrared & microwave barriers ', 0),
(5, 'Paradox outdoor siren strobeval', 'Paradox', 'Intrusion systems', 'Accessories', 'Module', 'Professional', 29580, 12, 1, 'Intrusion systems / Accessories ', 0),
(6, 'ZKTeco 2 door access control controller', 'ZKTeco', 'Access control', 'Controllers', 'Indoor', 'Professional', 140080, 10, 1, 'Access control / Controllers ', 0),
(7, 'Akuvox standalone RFID reader + keypad', 'Akuvox', 'Access control', 'Standalone readers', 'Professional', 'Module', 73800, 9, 1, 'Access control / Standalone readers ', 0),
(8, 'HID auxreader, EM-Marine', 'HID', 'Access control', 'Auxiliary readers', 'Accessory', 'Indoor', 90260, 2, 1, 'Access control / Auxiliary readers ', 0),
(9, 'RFID key fob TAG (EM-Marine)', 'Generic', 'Access control', 'Cards & tags', '125kHz', 'PVC', 2470, 8, 1, 'Access control / Cards & tags ', 0),
(10, 'Generic maglock 280 kg holding force', 'Generic', 'Access control', 'Maglocks', 'Indoor', 'Outdoor', 70700, 2, 1, 'Access control / Maglocks ', 0),
(11, 'Rosslare maglock kit for door', 'Rosslare', 'Access control', 'Electromagnetic locks', 'Indoor', 'Accessory', 83050, 5, 1, 'Access control / Electromagnetic locks ', 0),
(12, 'Rosslare emergency release button (break glass)', 'Rosslare', 'Access control', 'Accessories', 'Module', 'Professional', 15930, 3, 1, 'Access control / Accessories ', 0),
(13, 'Hikvision turret camera (4MP) PoE', 'Hikvision', 'CCTV', 'Cameras', 'FullColor', '4MP', 126160, 0, 1, 'CCTV / Cameras ', 0),
(14, 'Hikvision DVR 16 channel (1080p)', 'Hikvision', 'CCTV', 'Recorders', 'Professional', 'Outdoor', 154320, 7, 1, 'CCTV / Recorders ', 0),
(15, 'Uniview 4 camera PoE kit (NVR + cameras)', 'Uniview', 'CCTV', 'Kits', 'Module', 'Accessory', 155040, 0, 1, 'CCTV / Kits ', 0),
(16, 'Camera mount (dome/turret)', 'Uniview', 'CCTV', 'Mounting & accessories', 'Outdoor', 'Accessory', 19270, 10, 1, 'CCTV / Mounting & accessories ', 0),
(17, 'Axis mikroSD card 128GB', 'Axis', 'CCTV', 'Accessories', 'Module', 'Outdoor', 39570, 3, 1, 'CCTV / Accessories ', 0),
(18, 'BFT swing gate motor (2 leaf)', 'BFT', 'Gate automation', 'Motorok', 'Fotocella', 'Remote', 334770, 12, 1, 'Gate automation / Motorok ', 0),
(19, 'Came sliding gate kit (motor + 2 remote + photocell)', 'Came', 'Gate automation', 'Kits', 'IP54', 'Fotocella', 240640, 25, 1, 'Gate automation / Kits ', 0),
(20, 'Nice parking barrier gate (3-4 m kar)', 'Nice', 'Gate automation', 'Barriers', 'Remote', 'IP54', 1022390, 3, 1, 'Gate automation / Barriers ', 0),
(21, 'Beninca parking barrier (keyed)', 'Beninca', 'Gate automation', 'Parking barriers', 'Fotocella', '230V', 245250, 25, 1, 'Gate automation / Parking barriers ', 0),
(22, 'Generic maglock for gate 280 kg', 'Generic', 'Gate automation', 'Maglocks', 'Fotocella', '230V', 68710, 2, 1, 'Gate automation / Maglocks ', 0),
(23, 'Came shutter motor 40 Nm', 'Came', 'Gate automation', 'Shutter automation', '24V', 'Remote', 136160, 12, 1, 'Gate automation / Shutter automation ', 0),
(24, 'Gate opening push button', 'Nice', 'Gate automation', 'Accessories', 'Fotocella', 'IP54', 41990, 3, 1, 'Gate automation / Accessories ', 0),
(25, 'Akuvox indoor audio unit', 'Akuvox', 'Intercom', 'Indoor units', 'Outdoor', 'Module', 196340, 5, 1, 'Intercom / Indoor units ', 0),
(26, 'Intercom rain shield', 'Dahua', 'Intercom', 'Accessories', 'Professional', 'Module', 32880, 0, 1, 'Intercom / Accessories ', 0),
(27, '2N outdoor door station (1 apartment)', '2N', 'Intercom', 'Outdoor units', 'Module', 'Outdoor', 66640, 10, 1, 'Intercom / Outdoor units ', 0),
(28, 'Hikvision intercom kit (1 outdoor + 1 indoor)', 'Hikvision', 'Intercom', 'Kits', 'Indoor', 'Accessory', 471810, 2, 1, 'Intercom / Kits ', 0),
(29, 'Gel battery 12V 26Ah', 'Mean Well', 'Accessories', 'Batteries', 'Accessory', 'Outdoor', 24590, 3, 1, 'Accessories / Batteries ', 0),
(30, 'Wi‑Fi router (dual band)', 'Seagate', 'Accessories', 'Network equipment', 'Outdoor', 'Professional', 103370, 12, 1, 'Accessories / Network equipment ', 0),
(31, 'Outdoor siren strobeval', 'Seagate', 'Accessories', 'Sounders & beacons', 'Accessory', 'Professional', 58010, 10, 1, 'Accessories / Sounders & beacons ', 0),
(32, 'GSM communicator (alarm)', 'Mean Well', 'Accessories', 'Communicators', 'Module', 'Indoor', 40800, 2, 1, 'Accessories / Communicators ', 0),
(33, 'LED reflektor 100W (IP65)', 'Generic', 'Accessories', 'LED floodlights', 'Indoor', 'Professional', 21840, 5, 1, 'Accessories / LED floodlights ', 0),
(34, 'Mean Well Surveillance HDD 1TB', 'Mean Well', 'Accessories', 'Hard drives', 'Module', 'Indoor', 20510, 0, 1, 'Accessories / Hard drives ', 0),
(35, 'Rack cabinet 9U wall-mount', 'Generic', 'Accessories', 'Rack cabinets', 'Outdoor', 'Professional', 141240, 25, 1, 'Accessories / Rack cabinets ', 0),
(36, 'Wall plug + screw (50 db)', 'Generic', 'Accessories', 'Consumables', 'Accessory', 'Professional', 19850, 50, 1, 'Accessories / Consumables ', 0),
(37, 'Crimping pliers RJ45-hez', 'Western Digital', 'Accessories', 'Tools', 'Module', 'Accessory', 4460, 12, 1, 'Accessories / Tools ', 0),
(38, 'APC power supply 12V 10A', 'APC', 'Accessories', 'Power supplies', 'Indoor', 'Accessory', 12860, 2, 1, 'Accessories / Power supplies ', 0),
(39, 'UTP Cat6 cable (100 m)', 'Seagate', 'Accessories', 'Cables', 'Outdoor', 'Accessory', 10670, 50, 1, 'Accessories / Cables ', 0),
(40, 'Bosch fire alarm panel 2 loop', 'Bosch', 'Fire alarms', 'Fire control panels', 'Indoor', 'Addressable', 390490, 7, 1, 'Fire alarms / Tűzközpontok ', 0),
(41, 'Honeywell heat detector', 'Honeywell', 'Fire alarms', 'Sensors', 'IP65', 'EN54', 15010, 0, 1, 'Fire alarms / Sensors ', 0),
(42, 'Honeywell manual call point (breakable)', 'Honeywell', 'Fire alarms', 'Manual call points', 'Indoor', 'IP65', 9390, 12, 1, 'Fire alarms / Kézi jelzésadók ', 0),
(43, 'Bosch indoor sounder', 'Bosch', 'Fire alarms', 'Sounders & beacons', 'Indoor', 'EN54', 12790, 3, 1, 'Fire alarms / Sounders & beacons ', 0),
(44, 'Inim isolator modul', 'Inim', 'Fire alarms', 'Accessories', 'Indoor', 'IP65', 38260, 7, 1, 'Fire alarms / Accessories ', 0),
(45, 'Fire-resistant cable 2x1.5 (50 m)', 'Bosch', 'Fire alarms', 'Fire cables', 'EN54', 'IP65', 25290, 5, 1, 'Fire alarms / Tűzkábelek ', 0),
(46, 'Fire evacuation plan board (A3)', 'Notifier', 'Fire alarms', 'Signage & logs', 'IP65', 'Addressable', 5090, 25, 1, 'Fire alarms / Táblák, naplók ', 0),
(47, 'Paradox proximity keypad + code', 'Paradox', 'Intrusion systems', 'Keypads', 'Outdoor', 'Professional', 16160, 25, 1, 'Intrusion systems / Keypads ', 0),
(48, 'Beninca maglock for gate 180 kg', 'Beninca', 'Gate automation', 'Maglocks', '24V', 'IP54', 37990, 5, 1, 'Gate automation / Maglocks ', 0),
(49, 'Fire-resistant cable (50 m)', 'Western Digital', 'Accessories', 'Cables', 'Indoor', 'Module', 13930, 100, 1, 'Accessories / Cables ', 0),
(50, 'Pyronix hibrid control panel (wired + wireless)', 'Pyronix', 'Intrusion systems', 'Control panels', 'Professional', 'Module', 133450, 12, 1, 'Intrusion systems / Control panels ', 0),
(51, 'Paradox control panel 8 zone (expandable)', 'Paradox', 'Intrusion systems', 'Control panels', 'Outdoor', 'Module', 193680, 7, 1, 'Intrusion systems / Control panels ', 0),
(52, 'UTP Cat6 cable (100 m)', 'Mean Well', 'Accessories', 'Cables', 'Module', 'Professional', 24920, 150, 1, 'Accessories / Cables ', 0),
(53, 'Axis mikroSD card 128GB', 'Axis', 'CCTV', 'Accessories', 'Accessory', 'Outdoor', 43880, 2, 1, 'CCTV / Accessories ', 0),
(54, 'Notifier siren strobeval (piros)', 'Notifier', 'Fire alarms', 'Sounders & beacons', 'EN54', 'Addressable', 66050, 12, 1, 'Fire alarms / Sounders & beacons ', 0),
(55, 'Akuvox indoor monitor (10\")', 'Akuvox', 'Intercom', 'Indoor units', 'Professional', 'Module', 52910, 10, 1, 'Intercom / Indoor units ', 0),
(56, 'Intercom rain shield', 'Hikvision', 'Intercom', 'Accessories', 'Professional', 'Module', 37850, 7, 1, 'Intercom / Accessories ', 0),
(57, 'Texecom touch keypadpanel', 'Texecom', 'Intrusion systems', 'Keypads', 'Professional', 'Outdoor', 45950, 7, 1, 'Intrusion systems / Keypads ', 0),
(58, 'DSC microwave barrier gate (outdoor)', 'DSC', 'Intrusion systems', 'Infrared & microwave barriers', 'Professional', 'Module', 318460, 3, 1, 'Intrusion systems / Infrared & microwave barriers ', 0),
(59, 'Wi‑Fi router (dual band)', 'APC', 'Accessories', 'Network equipment', 'Module', 'Outdoor', 4050, 7, 1, 'Accessories / Network equipment ', 0),
(60, '2N indoor audio unit', '2N', 'Intercom', 'Indoor units', 'Accessory', 'Professional', 135580, 25, 1, 'Intercom / Indoor units ', 0),
(61, 'Hikvision FullColor camera (4MP)', 'Hikvision', 'CCTV', 'Cameras', 'IP67', 'WDR', 97510, 3, 1, 'CCTV / Cameras ', 0),
(62, 'HID maglock kit for door', 'HID', 'Access control', 'Electromagnetic locks', 'Outdoor', 'Professional', 68100, 7, 1, 'Access control / Electromagnetic locks ', 0),
(63, 'Gigabit switch (8 port)', 'Western Digital', 'Accessories', 'Network equipment', 'Accessory', 'Indoor', 11560, 5, 1, 'Accessories / Network equipment ', 0),
(64, 'Axis PTZ camera (4MP) 25x zoom', 'Axis', 'CCTV', 'Cameras', 'Turret', 'Bullet', 123170, 5, 1, 'CCTV / Cameras ', 0),
(65, 'ZKTeco maglock kit for door', 'ZKTeco', 'Access control', 'Electromagnetic locks', 'Indoor', 'Accessory', 66730, 0, 1, 'Access control / Electromagnetic locks ', 0),
(66, 'DSC outdoor siren strobeval', 'DSC', 'Intrusion systems', 'Accessories', 'Indoor', 'Outdoor', 29490, 25, 1, 'Intrusion systems / Accessories ', 0),
(67, 'Gel battery 12V 17Ah', 'Mean Well', 'Accessories', 'Batteries', 'Professional', 'Module', 25830, 25, 1, 'Accessories / Batteries ', 0),
(68, 'Beninca garage door kit (motor + rail)', 'Beninca', 'Gate automation', 'Kits', 'Fotocella', 'Remote', 621370, 8, 1, 'Gate automation / Kits ', 0),
(69, 'Bosch outdoor beacon', 'Bosch', 'Fire alarms', 'Sounders & beacons', 'Conventional', 'Addressable', 46870, 25, 1, 'Fire alarms / Sounders & beacons ', 0),
(70, 'Notifier outdoor beacon', 'Notifier', 'Fire alarms', 'Sounders & beacons', 'Conventional', 'Indoor', 47680, 5, 1, 'Fire alarms / Sounders & beacons ', 0),
(71, 'Paradox outdoor dual technology sensor', 'Paradox', 'Intrusion systems', 'Sensors', 'Module', 'Professional', 26190, 7, 1, 'Intrusion systems / Sensors ', 0),
(72, 'Generic intercom kit (1 outdoor + 1 indoor)', 'Generic', 'Intercom', 'Kits', 'Outdoor', 'Accessory', 190670, 3, 1, 'Intercom / Kits ', 0),
(73, 'Dahua indoor audio unit', 'Dahua', 'Intercom', 'Indoor units', 'Accessory', 'Professional', 100090, 2, 1, 'Intercom / Indoor units ', 0),
(74, 'Pyronix four beam infra barrier gate (outdoor)', 'Pyronix', 'Intrusion systems', 'Infrared & microwave barriers', 'Indoor', 'Outdoor', 375330, 12, 1, 'Intrusion systems / Infrared & microwave barriers ', 0),
(75, 'Gate receiver + remote', 'Beninca', 'Gate automation', 'Accessories', 'Fotocella', 'Remote', 48830, 0, 1, 'Gate automation / Accessories ', 0),
(76, 'Beninca maglock for gate 280 kg', 'Beninca', 'Gate automation', 'Maglocks', 'Remote', 'Fotocella', 41800, 7, 1, 'Gate automation / Maglocks ', 0),
(77, 'Jablotron outdoor siren strobeval', 'Jablotron', 'Intrusion systems', 'Accessories', 'Module', 'Accessory', 20980, 5, 1, 'Intrusion systems / Accessories ', 0),
(78, 'Axis NVR 8 channel (4K)', 'Axis', 'CCTV', 'Recorders', 'Accessory', 'Outdoor', 157410, 10, 1, 'CCTV / Recorders ', 0),
(79, 'Texecom control panel 8 zone (expandable)', 'Texecom', 'Intrusion systems', 'Control panels', 'Accessory', 'Indoor', 151940, 0, 1, 'Intrusion systems / Control panels ', 0),
(80, 'HID maglock external for door', 'HID', 'Access control', 'Maglocks', 'Accessory', 'Outdoor', 48100, 3, 1, 'Access control / Maglocks ', 0),
(81, 'HID emergency release button (break glass)', 'HID', 'Access control', 'Accessories', 'Outdoor', 'Accessory', 16510, 10, 1, 'Access control / Accessories ', 0),
(82, 'Uniview UPS (aux power)', 'Uniview', 'CCTV', 'Accessories', 'Accessory', 'Module', 33040, 7, 1, 'CCTV / Accessories ', 0),
(83, 'Gate receiver + remote', 'Nice', 'Gate automation', 'Accessories', '230V', '24V', 2570, 0, 1, 'Gate automation / Accessories ', 0),
(84, 'HID exit sensor (IR)', 'HID', 'Access control', 'Accessories', 'Outdoor', 'Professional', 2630, 0, 1, 'Access control / Accessories ', 0),
(85, 'Fire-resistant cable 2x1.5 (50 m)', 'Honeywell', 'Fire alarms', 'Fire cables', 'Indoor', 'EN54', 20530, 3, 1, 'Fire alarms / Tűzkábelek ', 0),
(86, 'Crimping pliers RJ45-hez', 'Generic', 'Accessories', 'Tools', 'Module', 'Outdoor', 19530, 7, 1, 'Accessories / Tools ', 0),
(87, 'Generic shutter motor controller (RF)', 'Generic', 'Gate automation', 'Shutter automation', '230V', 'IP54', 77520, 3, 1, 'Gate automation / Shutter automation ', 0),
(88, 'Gigabit switch (8 port)', 'Generic', 'Accessories', 'Network equipment', 'Accessory', 'Outdoor', 55100, 12, 1, 'Accessories / Network equipment ', 0),
(89, 'Gate strobe lamp', 'Nice', 'Gate automation', 'Accessories', 'Fotocella', 'IP54', 9330, 7, 1, 'Gate automation / Accessories ', 0),
(90, 'Generic siren strobeval (piros)', 'Generic', 'Fire alarms', 'Sounders & beacons', 'Conventional', 'EN54', 36430, 12, 1, 'Fire alarms / Sounders & beacons ', 0),
(91, 'Jablotron wireless receivermodul', 'Jablotron', 'Intrusion systems', 'Accessories', 'Accessory', 'Indoor', 1500, 12, 1, 'Intrusion systems / Accessories ', 0),
(92, 'Inim fire alarm panel 2 loop', 'Inim', 'Fire alarms', 'Fire control panels', 'Addressable', 'Indoor', 983060, 25, 1, 'Fire alarms / Tűzközpontok ', 0),
(93, 'ZKTeco electric strike (fail-secure)', 'ZKTeco', 'Access control', 'Electromagnetic locks', 'Professional', 'Accessory', 55730, 7, 1, 'Access control / Electromagnetic locks ', 0),
(94, 'Inim heat detector', 'Inim', 'Fire alarms', 'Sensors', 'Addressable', 'EN54', 28970, 10, 1, 'Fire alarms / Sensors ', 0),
(95, 'Seagate Surveillance HDD 2TB', 'Seagate', 'Accessories', 'Hard drives', 'Professional', 'Accessory', 34960, 25, 1, 'Accessories / Hard drives ', 0),
(96, 'Rosslare 2 door access control controller', 'Rosslare', 'Access control', 'Controllers', 'Outdoor', 'Accessory', 95970, 10, 1, 'Access control / Controllers ', 0),
(97, 'ZKTeco emergency release button (break glass)', 'ZKTeco', 'Access control', 'Accessories', 'Module', 'Professional', 11570, 10, 1, 'Access control / Accessories ', 0),
(98, 'EM-Marine RFID card (125 kHz)', 'Generic', 'Access control', 'Cards & tags', 'EM-Marine', 'MIFARE', 1670, 50, 1, 'Access control / Cards & tags ', 0),
(99, 'Axis DVR 16 channel (1080p)', 'Axis', 'CCTV', 'Recorders', 'Accessory', 'Professional', 211910, 5, 1, 'CCTV / Recorders ', 0),
(100, 'Indoor siren 12V', 'APC', 'Accessories', 'Sounders & beacons', 'Outdoor', 'Accessory', 10610, 7, 1, 'Accessories / Sounders & beacons ', 0),
(101, 'Fire-resistant cable (50 m)', 'Western Digital', 'Accessories', 'Cables', 'Module', 'Accessory', 27680, 200, 1, 'Accessories / Cables ', 0),
(102, 'Generic maglock for gate 180 kg', 'Generic', 'Gate automation', 'Maglocks', '230V', 'Remote', 47840, 10, 1, 'Gate automation / Maglocks ', 0),
(103, 'Rosslare electric strike (fail-safe)', 'Rosslare', 'Access control', 'Electromagnetic locks', 'Indoor', 'Outdoor', 33580, 5, 1, 'Access control / Electromagnetic locks ', 0),
(104, 'Notifier optikai smoke detector', 'Notifier', 'Fire alarms', 'Sensors', 'Addressable', 'Indoor', 22150, 5, 1, 'Fire alarms / Sensors ', 0),
(105, 'Pyronix touch keypadpanel', 'Pyronix', 'Intrusion systems', 'Keypads', 'Module', 'Outdoor', 21220, 5, 1, 'Intrusion systems / Keypads ', 0),
(106, 'Gel battery 12V 7Ah', 'Seagate', 'Accessories', 'Batteries', 'Professional', 'Outdoor', 53510, 0, 1, 'Accessories / Batteries ', 0),
(107, 'Seagate power supply 12V 5A', 'Seagate', 'Accessories', 'Power supplies', 'Outdoor', 'Accessory', 12920, 7, 1, 'Accessories / Power supplies ', 0),
(108, 'Paradox LED keypad (keypad)', 'Paradox', 'Intrusion systems', 'Keypads', 'Accessory', 'Professional', 60010, 7, 1, 'Intrusion systems / Keypads ', 0),
(109, 'Axis turret camera (4MP) PoE', 'Axis', 'CCTV', 'Cameras', 'WDR', 'Bullet', 50190, 0, 1, 'CCTV / Cameras ', 0),
(110, 'Paradox remotemonitoring communicator (IP/GSM)', 'Paradox', 'Intrusion systems', 'Accessories', 'Professional', 'Indoor', 21130, 2, 1, 'Intrusion systems / Accessories ', 0),
(111, 'Fire-resistant cable 2x1.5 (50 m)', 'Bosch', 'Fire alarms', 'Fire cables', 'EN54', 'Addressable', 47090, 7, 1, 'Fire alarms / Tűzkábelek ', 0),
(112, 'HID MIFARE reader, surface-mount', 'HID', 'Access control', 'Standalone readers', 'Professional', 'Outdoor', 140230, 12, 1, 'Access control / Standalone readers ', 0),
(113, 'Generic garage door motor (indoor)', 'Generic', 'Gate automation', 'Motorok', '230V', 'Remote', 237610, 25, 1, 'Gate automation / Motorok ', 0),
(114, 'LTE communicator (alarm)', 'Seagate', 'Accessories', 'Communicators', 'Professional', 'Indoor', 105730, 0, 1, 'Accessories / Communicators ', 0),
(115, 'Dahua indoor audio unit', 'Dahua', 'Intercom', 'Indoor units', 'Indoor', 'Outdoor', 99130, 7, 1, 'Intercom / Indoor units ', 0),
(116, 'DSC outdoor siren strobeval', 'DSC', 'Intrusion systems', 'Accessories', 'Outdoor', 'Indoor', 23590, 2, 1, 'Intrusion systems / Accessories ', 0),
(117, 'Inim isolator modul', 'Inim', 'Fire alarms', 'Accessories', 'Conventional', 'EN54', 49630, 25, 1, 'Fire alarms / Accessories ', 0),
(118, 'Outdoor siren strobeval', 'Western Digital', 'Accessories', 'Sounders & beacons', 'Indoor', 'Outdoor', 26150, 25, 1, 'Accessories / Sounders & beacons ', 0),
(119, 'Rosslare controllerpanel (PoE)', 'Rosslare', 'Access control', 'Controllers', 'Accessory', 'Indoor', 111620, 5, 1, 'Access control / Controllers ', 0),
(120, 'Jablotron LCD keypad (Hungarian menu)', 'Jablotron', 'Intrusion systems', 'Keypads', 'Module', 'Outdoor', 66040, 3, 1, 'Intrusion systems / Keypads ', 0),
(121, 'Dahua 4 camera PoE kit (NVR + cameras)', 'Dahua', 'CCTV', 'Kits', 'Professional', 'Module', 134350, 7, 1, 'CCTV / Kits ', 0),
(122, 'Photocell pair (for gate)', 'Beninca', 'Gate automation', 'Accessories', 'Remote', '230V', 39380, 7, 1, 'Gate automation / Accessories ', 0),
(123, 'Generic mikroSD card 128GB', 'Generic', 'CCTV', 'Accessories', 'Indoor', 'Professional', 42440, 25, 1, 'CCTV / Accessories ', 0),
(124, 'Texecom touch keypadpanel', 'Texecom', 'Intrusion systems', 'Keypads', 'Indoor', 'Professional', 62440, 7, 1, 'Intrusion systems / Keypads ', 0),
(125, 'Hikvision 4 camera analog kit (DVR + cameras)', 'Hikvision', 'CCTV', 'Kits', 'Module', 'Indoor', 353910, 0, 1, 'CCTV / Kits ', 0),
(126, 'Bosch indoor sounder', 'Bosch', 'Fire alarms', 'Sounders & beacons', 'Conventional', 'Addressable', 50500, 25, 1, 'Fire alarms / Sounders & beacons ', 0),
(127, 'Fire-resistant cable 2x2.5 (50 m)', 'Generic', 'Fire alarms', 'Fire cables', 'Indoor', 'Conventional', 41270, 1, 1, 'Fire alarms / Tűzkábelek ', 0),
(128, 'Texecom touch keypadpanel', 'Texecom', 'Intrusion systems', 'Keypads', 'Outdoor', 'Module', 39290, 2, 1, 'Intrusion systems / Keypads ', 0),
(129, 'Axis DVR 16 channel (1080p)', 'Axis', 'CCTV', 'Recorders', 'Professional', 'Indoor', 124430, 12, 1, 'CCTV / Recorders ', 0),
(130, 'Indoor siren 12V', 'APC', 'Accessories', 'Sounders & beacons', 'Module', 'Indoor', 28750, 7, 1, 'Accessories / Sounders & beacons ', 0),
(131, 'Wi‑Fi router (dual band)', 'APC', 'Accessories', 'Network equipment', 'Accessory', 'Indoor', 4170, 25, 1, 'Accessories / Network equipment ', 0),
(132, 'Hikvision DVR 8 channel (1080p)', 'Hikvision', 'CCTV', 'Recorders', 'Accessory', 'Indoor', 234010, 25, 1, 'CCTV / Recorders ', 0),
(133, 'Dahua indoor monitor (10\")', 'Dahua', 'Intercom', 'Indoor units', 'Accessory', 'Professional', 72920, 7, 1, 'Intercom / Indoor units ', 0),
(134, 'Honeywell fire alarm panel 1 loop', 'Honeywell', 'Fire alarms', 'Fire control panels', 'Addressable', 'Conventional', 975770, 5, 1, 'Fire alarms / Tűzközpontok ', 0),
(135, 'Fire-resistant cable 2x1.5 (50 m)', 'Generic', 'Fire alarms', 'Fire cables', 'EN54', 'Addressable', 46230, 12, 1, 'Fire alarms / Tűzkábelek ', 0),
(136, 'Mean Well Surveillance HDD 2TB', 'Mean Well', 'Accessories', 'Hard drives', 'Accessory', 'Module', 24610, 3, 1, 'Accessories / Hard drives ', 0),
(137, 'Generic manual call point (resettable)', 'Generic', 'Fire alarms', 'Manual call points', 'Indoor', 'Addressable', 14490, 25, 1, 'Fire alarms / Kézi jelzésadók ', 0),
(138, 'Akuvox maglock external for door', 'Akuvox', 'Access control', 'Maglocks', 'Outdoor', 'Professional', 24830, 12, 1, 'Access control / Maglocks ', 0),
(139, 'HID standalone RFID reader (IP65)', 'HID', 'Access control', 'Standalone readers', 'Module', 'Professional', 141580, 12, 1, 'Access control / Standalone readers ', 0),
(140, 'Cablecable tie (100 db)', 'Mean Well', 'Accessories', 'Consumables', 'Professional', 'Accessory', 12710, 200, 1, 'Accessories / Consumables ', 0),
(141, 'ZKTeco standalone RFID reader (IP65)', 'ZKTeco', 'Access control', 'Standalone readers', 'Module', 'Professional', 103230, 25, 1, 'Access control / Standalone readers ', 0),
(142, 'Generic mikroSD card 128GB', 'Generic', 'CCTV', 'Accessories', 'Module', 'Outdoor', 32890, 25, 1, 'CCTV / Accessories ', 0),
(143, 'ZKTeco MIFARE reader, surface-mount', 'ZKTeco', 'Access control', 'Standalone readers', 'Accessory', 'Indoor', 77730, 5, 1, 'Access control / Standalone readers ', 0),
(144, 'Notifier manual call point (resettable)', 'Notifier', 'Fire alarms', 'Manual call points', 'Indoor', 'Addressable', 20430, 12, 1, 'Fire alarms / Kézi jelzésadók ', 0),
(145, 'Rack cabinet 9U wall-mount', 'APC', 'Accessories', 'Rack cabinets', 'Indoor', 'Accessory', 91350, 10, 1, 'Accessories / Rack cabinets ', 0),
(146, 'Dahua mikroSD card 128GB', 'Dahua', 'CCTV', 'Accessories', 'Outdoor', 'Accessory', 39420, 0, 1, 'CCTV / Accessories ', 0),
(147, 'Gigabit switch (8 port)', 'Western Digital', 'Accessories', 'Network equipment', 'Module', 'Accessory', 80910, 7, 1, 'Accessories / Network equipment ', 0),
(148, 'LED reflektor 50W (IP65)', 'Mean Well', 'Accessories', 'LED floodlights', 'Module', 'Accessory', 58230, 12, 1, 'Accessories / LED floodlights ', 0),
(149, 'Generic maglock kit for door', 'Generic', 'Access control', 'Electromagnetic locks', 'Outdoor', 'Module', 63570, 2, 1, 'Access control / Electromagnetic locks ', 0);

-- --------------------------------------------------------

--
-- Table structure for table `rate_limits`
--

DROP TABLE IF EXISTS `rate_limits`;
CREATE TABLE IF NOT EXISTS `rate_limits` (
  `id` int NOT NULL AUTO_INCREMENT,
  `rate_key` varchar(255) NOT NULL,
  `hits` int NOT NULL,
  `last_hit` int NOT NULL,
  `expires_at` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_rate_key` (`rate_key`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
CREATE TABLE IF NOT EXISTS `reservations` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `service` varchar(64) NOT NULL,
  `reservation_date` date NOT NULL,
  `reservation_time` time NOT NULL,
  `location` varchar(64) NOT NULL,
  `customer_name` varchar(128) NOT NULL,
  `customer_phone` varchar(32) NOT NULL,
  `customer_email` varchar(128) NOT NULL,
  `note` varchar(255) DEFAULT NULL,
  `duration` time NOT NULL DEFAULT '00:00:00',
  `reservation_submitted` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `user_id` int UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `reservation_date` (`reservation_date`),
  KEY `fk_res_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `reservations`
--

INSERT INTO `reservations` (`id`, `service`, `reservation_date`, `reservation_time`, `location`, `customer_name`, `customer_phone`, `customer_email`, `note`, `duration`, `reservation_submitted`, `user_id`) VALUES
(2, 'Camera system survey', '2026-04-09', '09:30:00', 'At our office', 'Ákos Gonda', '+36205455866', 'gonda.akosdonat@gmail.com', 'hfhff', '00:00:00', '2026-04-08 01:54:32', 5);

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE IF NOT EXISTS `user` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` varchar(32) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `role` enum('user','admin') NOT NULL DEFAULT 'user',
  PRIMARY KEY (`id`),
  UNIQUE KEY `username_unique` (`username`),
  UNIQUE KEY `email_unique` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
CREATE TABLE IF NOT EXISTS `user_secret` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `password` varchar(255) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `phone` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `username` varchar(32) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_sec_username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `user_secret`
--

INSERT INTO `user_secret` (`id`, `password`, `address`, `phone`, `username`) VALUES
(1, '123445678', '7630 Pécs, Diósi út 42.', '', 'mintapeti123'),
(2, '123445678', '7630 Pécs, Diósi út 42.', '', 'jackgypsum'),
(3, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, '', 'testuser'),
(4, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, '', 'testuser2'),
(5, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, '', 'john_doe'),
(6, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, '', 'john_doe2'),
(7, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, '', 'frontendform_1'),
(8, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, '', 'rakoskaa'),
(9, 'd77c63d2083b13c20b3c708a6e9a3d2480e7bfe2c68e0860f9c0832d4f2aa308', NULL, '', 'czehszabi'),
(10, '6cb35d4af024a5a6e602d4c54af0887afedd7b00897933bb1d07612ad0a31501', NULL, '', 'jani01');

--
-- Constraints for dumped tables
--

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_orders_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_order_items_orders_id` FOREIGN KEY (`orders_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_order_items_product_id` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reservations`
--
ALTER TABLE `reservations`
  ADD CONSTRAINT `fk_res_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_secret`
--
ALTER TABLE `user_secret`
  ADD CONSTRAINT `fk_sec_username` FOREIGN KEY (`username`) REFERENCES `user` (`username`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
