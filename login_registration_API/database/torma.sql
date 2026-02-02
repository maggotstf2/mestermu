-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Feb 02, 2026 at 01:14 PM
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

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`gonda`@`localhost` PROCEDURE `auth_user` (IN `pUsername` VARCHAR(50), IN `pPassword` VARCHAR(100))   BEGIN
SELECT u.id, u.username, u.email
FROM user u
JOIN user_secret c ON u.username = c.username
WHERE u.username = pUsername
AND c.password = SHA2(pPassword, 256);
END$$

CREATE DEFINER=`gonda`@`localhost` PROCEDURE `createReservation` (IN `pAbout` CHAR(255), IN `pReservationDate` DATETIME, IN `pDuration` TIME, IN `pUserId` INT(12))   BEGIN
INSERT INTO reservations (about,reservation_date,duration,user_id)
VALUES(pAbout,pReservationDate,pDuration,pUserId);
END$$

CREATE DEFINER=`gonda`@`localhost` PROCEDURE `deleteReservation` (IN `pId` INT(12))   BEGIN
DELETE FROM reservations WHERE id=pId;
END$$

CREATE DEFINER=`gonda`@`localhost` PROCEDURE `delete_user` (IN `pUsername` VARCHAR(50))   BEGIN
DELETE FROM user WHERE username = pUsername;
END$$

CREATE DEFINER=`gonda`@`localhost` PROCEDURE `getUserReservations` (IN `pUserId` INT(12))   BEGIN
SELECT id, about, reservation_date, duration, reservation_submitted
FROM reservations
WHERE user_id=pUserId
ORDER BY reservation_date ASC;
END$$

CREATE DEFINER=`gonda`@`localhost` PROCEDURE `register_user` (IN `pUsername` VARCHAR(50), IN `pFirstName` VARCHAR(50), IN `pLastName` VARCHAR(50), IN `pEmail` VARCHAR(100), IN `pPassword` VARCHAR(100))   BEGIN
INSERT INTO user(username, first_name, last_name, email) VALUES(pUsername, pFirstName, pLastName, pEmail);
INSERT INTO user_secret(password) VALUES(SHA2(pPassword,256));
END$$

CREATE DEFINER=`gonda`@`localhost` PROCEDURE `updateReservation` (IN `pId` INT(12), IN `pAbout` CHAR(255), IN `pReservationDate` DATETIME, IN `pDuration` TIME)   BEGIN
UPDATE reservations
SET about=pAbout,
reservationDate=pReservationDate,
duration=pDuration
WHERE id=pId;
END$$

CREATE DEFINER=`gonda`@`localhost` PROCEDURE `update_password` (IN `pUsername` VARCHAR(50), IN `pNewPass` VARCHAR(100))   BEGIN
UPDATE user_secret
SET password = SHA2(pNewPass, 256)
WHERE username = pUsername;
END$$

CREATE DEFINER=`gonda`@`localhost` PROCEDURE `update_username` (IN `pUsername` VARCHAR(50), IN `pId` INT(12))   BEGIN
UPDATE user
SET username=pUsername
WHERE id=pId;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `id` int(12) NOT NULL,
  `username` varchar(50) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `messages_id` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` int(12) NOT NULL,
  `content` varchar(150) NOT NULL,
  `user_id` int(12) NOT NULL,
  `admin_id` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` int(12) NOT NULL,
  `order_date` datetime NOT NULL DEFAULT current_timestamp(),
  `user_id` int(12) NOT NULL,
  `product_id` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product`
--

CREATE TABLE `product` (
  `id` int(12) NOT NULL,
  `product` text NOT NULL,
  `is_bundled` tinyint(1) NOT NULL DEFAULT 0,
  `orders_id` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reservations`
--

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

CREATE TABLE `user` (
  `id` int(12) NOT NULL,
  `username` varchar(50) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `orders_id` int(12) DEFAULT NULL,
  `messages_id` int(12) DEFAULT NULL,
  `reservations_id` int(12) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`id`, `username`, `first_name`, `last_name`, `email`, `created_at`, `orders_id`, `messages_id`, `reservations_id`) VALUES
(1, 'mintapeti123', 'Péter', 'Minta', 'mintapeter@citromail.hu', '2026-01-06 11:02:48', NULL, NULL, NULL),
(2, 'jackgypsum', 'Jakab', 'Gipsz', 'gipszj@freemail.hu', '2026-01-06 11:06:03', NULL, NULL, NULL),
(3, 'testuser', 'Test', 'User', 'test@example.com', '2026-01-26 12:47:12', NULL, NULL, NULL),
(4, 'testuser2', 'Test', 'User', 'test2@example.com', '2026-01-27 10:16:47', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `user_secret`
--

CREATE TABLE `user_secret` (
  `id` int(12) NOT NULL,
  `password` char(100) NOT NULL,
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
(4, 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', NULL, 'testuser2');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username_2` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `fk_messages_id` (`messages_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_user_id` (`user_id`),
  ADD KEY `fk_admin_id` (`admin_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_user_id` (`user_id`),
  ADD KEY `fk_product_id` (`product_id`);

--
-- Indexes for table `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_orders_id` (`orders_id`);

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
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `fk_orders_id` (`orders_id`),
  ADD KEY `fk_reservations_id` (`reservations_id`),
  ADD KEY `fk_messages_id` (`messages_id`);

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
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT;

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
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `user_secret`
--
ALTER TABLE `user_secret`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `admin`
--
ALTER TABLE `admin`
  ADD CONSTRAINT `fk_messages_id` FOREIGN KEY (`messages_id`) REFERENCES `messages` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `fk_admin_id` FOREIGN KEY (`admin_id`) REFERENCES `admin` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_product_id` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `product`
--
ALTER TABLE `product`
  ADD CONSTRAINT `fk_orders_id` FOREIGN KEY (`orders_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `reservations`
--
ALTER TABLE `reservations`
  ADD CONSTRAINT `fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `user`
--
ALTER TABLE `user`
  ADD CONSTRAINT `fk_messages_id` FOREIGN KEY (`messages_id`) REFERENCES `messages` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_orders_id` FOREIGN KEY (`orders_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_reservations_id` FOREIGN KEY (`reservations_id`) REFERENCES `reservations` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `user_secret`
--
ALTER TABLE `user_secret`
  ADD CONSTRAINT `fk_username` FOREIGN KEY (`username`) REFERENCES `user` (`username`) ON DELETE CASCADE ON UPDATE NO ACTION;
COMMIT;