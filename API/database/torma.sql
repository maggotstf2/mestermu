-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Feb 12, 2026 at 02:03 PM
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
DROP PROCEDURE IF EXISTS `authUser`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `authUser` (IN `pUsername` VARCHAR(50), IN `pPassword` VARCHAR(100))   BEGIN
SELECT u.id, u.username, u.email
FROM user u
JOIN user_secret c ON u.username = c.username
WHERE u.username = pUsername
AND c.password = SHA2(pPassword, 256);
END$$

DROP PROCEDURE IF EXISTS `createReservation`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `createReservation` (IN `pAbout` CHAR(255), IN `pReservationDate` DATETIME, IN `pDuration` TIME, IN `pUserId` INT(12))   BEGIN
INSERT INTO reservations (about,reservation_date,duration,user_id)
VALUES(pAbout,pReservationDate,pDuration,pUserId);
END$$

DROP PROCEDURE IF EXISTS `createUser`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `createUser` (IN `pUsername` VARCHAR(32), IN `pPassword` VARCHAR(32), IN `pEmail` VARCHAR(100), IN `pFirstname` VARCHAR(50), IN `pLastname` VARCHAR(50))   BEGIN
INSERT INTO user(username, email, first_name, last_name)
VALUES(pUsername, pEmail, pFirstname, pLastname);
INSERT INTO user_secret(password, username)
VALUES(SHA2(pPassword,256),pUsername);
END$$

DROP PROCEDURE IF EXISTS `deleteReservation`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `deleteReservation` (IN `pId` INT(12))   BEGIN
DELETE FROM reservations WHERE id=pId;
END$$

DROP PROCEDURE IF EXISTS `deleteUser`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `deleteUser` (IN `pUsername` VARCHAR(50))   BEGIN
DELETE FROM user WHERE username = pUsername;
END$$

DROP PROCEDURE IF EXISTS `getAllUsers`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `getAllUsers` ()   BEGIN
SELECT u.id, u.username, u.first_name, u.last_name, u.role, u.created_at
FROM user u
ORDER BY u.created_at DESC;
END$$

DROP PROCEDURE IF EXISTS `getUserById`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `getUserById` (IN `pId` INT(12))   BEGIN
SELECT u.id, u.username, u.first_name, u.last_name, u.role, u.created_at
FROM user u
WHERE u.id=pId;
END$$

DROP PROCEDURE IF EXISTS `getUserByUsername`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `getUserByUsername` (IN `pUsername` VARCHAR(32))   BEGIN
SELECT u.id, u.username, u.first_name, u.last_name, u.role, u.created_at
FROM user u 
WHERE u.username = pUsername;
END$$

DROP PROCEDURE IF EXISTS `getUserReservations`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `getUserReservations` (IN `pUserId` INT(12))   BEGIN
SELECT id AS "ID", about AS "INFO", reservation_date AS "RESERVATION DATE", duration AS "DURATION", reservation_submitted AS "SUBMITTED AT"
FROM reservations
WHERE user_id=pUserId
ORDER BY reservation_date ASC;
END$$

DROP PROCEDURE IF EXISTS `setAdminStatus`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `setAdminStatus` (IN `pId` INT(12), IN `pStatus` TINYINT(1))   BEGIN
UPDATE user
SET role = IF(pStatus=1,'admin','user')
WHERE id=pId;
END$$

DROP PROCEDURE IF EXISTS `updatePassword`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `updatePassword` (IN `pUsername` VARCHAR(50), IN `pNewPass` VARCHAR(100))   BEGIN
UPDATE user_secret
SET password = SHA2(pNewPass, 256)
WHERE username = pUsername;
END$$

DROP PROCEDURE IF EXISTS `updateReservation`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `updateReservation` (IN `pId` INT(12), IN `pAbout` CHAR(255), IN `pReservationDate` DATETIME, IN `pDuration` TIME)   BEGIN
UPDATE reservations
SET about=pAbout,
reservationDate=pReservationDate,
duration=pDuration
WHERE id=pId;
END$$

DROP PROCEDURE IF EXISTS `updateUsername`$$
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `updateUsername` (IN `pUsername` VARCHAR(50), IN `pId` INT(12))   BEGIN
UPDATE user
SET username=pUsername
WHERE id=pId;
END$$

DROP PROCEDURE IF EXISTS `updateUserRole`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUserRole` (IN `pId` INT(12), IN `pRole` VARCHAR(12))   BEGIN
UPDATE user SET role=pRole
WHERE id=pId;
END$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `isAdmin`$$
CREATE DEFINER=`gonda`@`localhost` FUNCTION `isAdmin` (`pUsername` VARCHAR(32)) RETURNS TINYINT(1) DETERMINISTIC READS SQL DATA BEGIN
RETURN EXISTS
(
	SELECT 1 FROM user
	WHERE username=pUsername AND role='admin'
);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
CREATE TABLE `messages` (
  `id` int(12) NOT NULL,
  `content` varchar(150) NOT NULL,
  `user_id` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `id` int(12) NOT NULL,
  `order_date` datetime NOT NULL DEFAULT current_timestamp(),
  `user_id` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

DROP TABLE IF EXISTS `order_items`;
CREATE TABLE `order_items` (
  `id` int(12) NOT NULL,
  `orders_id` int(12) NOT NULL,
  `product_id` int(12) NOT NULL,
  `quantity` smallint(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product`
--

DROP TABLE IF EXISTS `product`;
CREATE TABLE `product` (
  `id` int(12) NOT NULL,
  `product` text NOT NULL,
  `quantity` smallint(5) UNSIGNED NOT NULL,
  `in_stock` tinyint(1) NOT NULL DEFAULT 1,
  `is_bundled` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reservations`
--

DROP TABLE IF EXISTS `reservations`;
CREATE TABLE `reservations` (
  `id` int(12) NOT NULL,
  `about` char(255) NOT NULL,
  `reservation_date` datetime NOT NULL DEFAULT current_timestamp(),
  `duration` time NOT NULL,
  `reservation_submitted` datetime NOT NULL DEFAULT current_timestamp(),
  `user_id` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(12) NOT NULL,
  `username` varchar(32) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `role` varchar(12) NOT NULL DEFAULT 'user'
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
(6, 'john_doe2', '', '', 'john2@example.com', '2026-02-10 11:30:32', 'user');

-- --------------------------------------------------------

--
-- Table structure for table `user_secret`
--

DROP TABLE IF EXISTS `user_secret`;
CREATE TABLE `user_secret` (
  `id` int(12) NOT NULL,
  `password` text NOT NULL,
  `address` char(255) DEFAULT NULL,
  `username` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `user_secret`
--

INSERT INTO `user_secret` (`id`, `password`, `address`, `username`) VALUES
(1, '123445678', '7630 Pécs, Diósi út 42.', NULL),
(2, '123445678', '7630 Pécs, Diósi út 42.', NULL),
(3, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, 'testuser'),
(4, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, 'testuser2'),
(5, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, 'john_doe'),
(6, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, 'john_doe2');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_user_id` (`user_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_user_id` (`user_id`);

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
-- Indexes for table `reservations`
--
ALTER TABLE `reservations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `reservation_date` (`reservation_date`),
  ADD KEY `fk_user_id` (`user_id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `user_secret`
--
ALTER TABLE `user_secret`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product`
--
ALTER TABLE `product`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reservations`
--
ALTER TABLE `reservations`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `user_secret`
--
ALTER TABLE `user_secret`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `1` FOREIGN KEY (`orders_id`) REFERENCES `orders` (`id`),
  ADD CONSTRAINT `2` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`);

--
-- Constraints for table `reservations`
--
ALTER TABLE `reservations`
  ADD CONSTRAINT `fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `user_secret`
--
ALTER TABLE `user_secret`
  ADD CONSTRAINT `fk_username` FOREIGN KEY (`username`) REFERENCES `user` (`username`) ON DELETE CASCADE ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
