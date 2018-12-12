-- --------------------------------------------------------
-- Host:                         localhost
-- Server version:               5.7.19 - MySQL Community Server (GPL)
-- Server OS:                    Win64
-- HeidiSQL Version:             9.4.0.5125
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- Dumping structure for table sa-mp.ADMIN_LEVELS
CREATE TABLE IF NOT EXISTS `ADMIN_LEVELS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `EXEC_ID` int(11) DEFAULT NULL,
  `LEVEL` tinyint(2) DEFAULT NULL,
  `DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.ADMIN_LEVELS: 0 rows
/*!40000 ALTER TABLE `ADMIN_LEVELS` DISABLE KEYS */;
/*!40000 ALTER TABLE `ADMIN_LEVELS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.ADMIN_LOG
CREATE TABLE IF NOT EXISTS `ADMIN_LOG` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) NOT NULL,
  `ACTION` text,
  `ACTION_ID` int(11) DEFAULT NULL,
  `DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.ADMIN_LOG: 0 rows
/*!40000 ALTER TABLE `ADMIN_LOG` DISABLE KEYS */;
/*!40000 ALTER TABLE `ADMIN_LOG` ENABLE KEYS */;

-- Dumping structure for table sa-mp.APARTMENTS
CREATE TABLE IF NOT EXISTS `APARTMENTS` (
  `ID` int(3) NOT NULL,
  `OWNER` varchar(24) DEFAULT NULL,
  `NAME` varchar(30) DEFAULT NULL,
  `LOCKED` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.APARTMENTS: ~0 rows (approximately)
/*!40000 ALTER TABLE `APARTMENTS` DISABLE KEYS */;
/*!40000 ALTER TABLE `APARTMENTS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.bans
CREATE TABLE IF NOT EXISTS `BANS` (
  `NAME` varchar(25) DEFAULT NULL,
  `IP` varchar(16) DEFAULT NULL,
  `REASON` varchar(50) DEFAULT NULL,
  `BANBY` varchar(25) DEFAULT NULL,
  `DATE` int(11) DEFAULT NULL,
  `EXPIRE` int(11) NOT NULL DEFAULT '0',
  `SERVER` tinyint(1) DEFAULT '0',
  `SERIAL` varchar(40) DEFAULT NULL,
  `COUNTRY` varchar(2) DEFAULT NULL,
  `ISP` varchar(128) DEFAULT NULL,
  UNIQUE KEY `NAME` (`NAME`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.bans: ~0 rows (approximately)
/*!40000 ALTER TABLE `BANS` DISABLE KEYS */;
/*!40000 ALTER TABLE `BANS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.bribes
CREATE TABLE IF NOT EXISTS `BRIBES` (
  `ID` int(3) NOT NULL,
  `X` float DEFAULT NULL,
  `Y` float DEFAULT NULL,
  `Z` float DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.bribes: ~0 rows (approximately)
/*!40000 ALTER TABLE `BRIBES` DISABLE KEYS */;
/*!40000 ALTER TABLE `BRIBES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.businesses
CREATE TABLE IF NOT EXISTS `BUSINESSES` (
  `ID` int(11) unsigned NOT NULL,
  `OWNER_ID` int(11) unsigned DEFAULT NULL,
  `NAME` varchar(31) DEFAULT 'Business',
  `COST` int(11) DEFAULT NULL,
  `TYPE` tinyint(3) DEFAULT NULL,
  `SUPPLIES` int(11) DEFAULT '0',
  `PRODUCT` int(11) DEFAULT '0',
  `BANK` int(11) DEFAULT '0',
  `X` float DEFAULT NULL,
  `Y` float DEFAULT NULL,
  `Z` float DEFAULT NULL,
  `PROD_TIMESTAMP` int(11) DEFAULT '0',
  `MEMBERS` varchar(96) DEFAULT '0 0 0 0 0 0 0 0',
  `CAR_MODEL` int(4) DEFAULT '554',
  `AIR_MODEL` int(4) DEFAULT '417',
  `UPGRADES` tinyint(1) DEFAULT '0',
  `HAS_NOS` tinyint(1) DEFAULT '0',
  `HAS_RIMS` tinyint(1) DEFAULT '0',
  `EXTRA_MEMBERS` tinyint(2) DEFAULT '0',
  `SECURITY` tinyint(2) DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.businesses: 0 rows
/*!40000 ALTER TABLE `BUSINESSES` DISABLE KEYS */;
/*!40000 ALTER TABLE `BUSINESSES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.business_vehicles
CREATE TABLE IF NOT EXISTS `BUSINESS_VEHICLES` (
  `BUSINESS_ID` int(11) DEFAULT NULL,
  `VEHICLE_INDEX` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.business_vehicles: ~0 rows (approximately)
/*!40000 ALTER TABLE `BUSINESS_VEHICLES` DISABLE KEYS */;
/*!40000 ALTER TABLE `BUSINESS_VEHICLES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.CASH_CARDS
CREATE TABLE IF NOT EXISTS `CASH_CARDS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) unsigned DEFAULT '1',
  `CODE` varchar(32) NOT NULL,
  `VALUE` int(11) NOT NULL,
  `MAX_USES` int(11) DEFAULT NULL,
  `USES` int(11) DEFAULT '0',
  `EXPIRE_TIME` int(11) DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.CASH_CARDS: ~0 rows (approximately)
/*!40000 ALTER TABLE `CASH_CARDS` DISABLE KEYS */;
/*!40000 ALTER TABLE `CASH_CARDS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.CASH_CARDS_redeemed
CREATE TABLE IF NOT EXISTS `CASH_CARDS_REDEEMED` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `CASH_CARD_ID` int(11) DEFAULT NULL,
  `REDEEMED_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.CASH_CARDS_redeemed: ~0 rows (approximately)
/*!40000 ALTER TABLE `CASH_CARDS_REDEEMED` DISABLE KEYS */;
/*!40000 ALTER TABLE `CASH_CARDS_REDEEMED` ENABLE KEYS */;

-- Dumping structure for table sa-mp.casino_pools
CREATE TABLE IF NOT EXISTS `CASINO_POOLS` (
  `ID` int(11) NOT NULL,
  `POOL` int(11) DEFAULT '0',
  `TOTAL_WINNINGS` int(11) DEFAULT '0',
  `TOTAL_GAMBLED` int(11) DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.casino_pools: ~3 rows (approximately)
/*!40000 ALTER TABLE `CASINO_POOLS` DISABLE KEYS */;
INSERT INTO `CASINO_POOLS` (`ID`, `POOL`, `TOTAL_WINNINGS`, `TOTAL_GAMBLED`) VALUES
	(0, 5000000, 0, 0),
	(1, 25000000, 0, 0),
	(2, 100000000, 0, 0);
/*!40000 ALTER TABLE `CASINO_POOLS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.components
CREATE TABLE IF NOT EXISTS `COMPONENTS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `VEHICLE_ID` int(11) DEFAULT NULL,
  `MODEL` int(5) DEFAULT NULL,
  `X` float DEFAULT NULL,
  `Y` float DEFAULT NULL,
  `Z` float DEFAULT NULL,
  `RX` float DEFAULT NULL,
  `RY` float DEFAULT NULL,
  `RZ` float DEFAULT NULL,
  `DISABLED` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.components: 0 rows
/*!40000 ALTER TABLE `COMPONENTS` DISABLE KEYS */;
/*!40000 ALTER TABLE `COMPONENTS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.crowdfunds
CREATE TABLE IF NOT EXISTS `CROWDFUNDS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `FEATURE` text,
  `DESCRIPTION` text,
  `IMAGE` text,
  `ORDER` int(3) DEFAULT '0',
  `FUND_TARGET` float DEFAULT NULL,
  `RELEASE_DATE` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `END_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.crowdfunds: ~0 rows (approximately)
/*!40000 ALTER TABLE `CROWDFUNDS` DISABLE KEYS */;
/*!40000 ALTER TABLE `CROWDFUNDS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.crowdfund_packages
CREATE TABLE IF NOT EXISTS `CROWDFUND_PACKAGES` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `CROWDFUND_ID` int(11) DEFAULT NULL,
  `TITLE` text,
  `DESCRIPTION` text,
  `REQUIRED_AMOUNT` float DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.crowdfund_packages: ~0 rows (approximately)
/*!40000 ALTER TABLE `CROWDFUND_PACKAGES` DISABLE KEYS */;
/*!40000 ALTER TABLE `CROWDFUND_PACKAGES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.crowdfund_patreons
CREATE TABLE IF NOT EXISTS `CROWDFUND_PATREONS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `CROWDFUND_ID` int(11) DEFAULT NULL,
  `AMOUNT` float DEFAULT NULL,
  `DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.crowdfund_patreons: ~0 rows (approximately)
/*!40000 ALTER TABLE `CROWDFUND_PATREONS` DISABLE KEYS */;
/*!40000 ALTER TABLE `CROWDFUND_PATREONS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.db_migrations
CREATE TABLE IF NOT EXISTS `DB_MIGRATIONS` (
  `MIGRATION` varchar(255) NOT NULL,
  `DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`MIGRATION`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.db_migrations: ~0 rows (approximately)
/*!40000 ALTER TABLE `DB_MIGRATIONS` DISABLE KEYS */;
INSERT INTO `DB_MIGRATIONS` (`MIGRATION`) VALUES
	('20181212_cnr_base');
/*!40000 ALTER TABLE `DB_MIGRATIONS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.emails
CREATE TABLE IF NOT EXISTS `EMAILS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `EMAIL` varchar(64) DEFAULT NULL,
  `MODE` tinyint(2) DEFAULT NULL,
  `LAST_CHANGED` int(11) DEFAULT NULL,
  `LAST_DISABLED` int(11) DEFAULT '0',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `USER_ID` (`USER_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.emails: 0 rows
/*!40000 ALTER TABLE `EMAILS` DISABLE KEYS */;
/*!40000 ALTER TABLE `EMAILS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.email_verify
CREATE TABLE IF NOT EXISTS `EMAIL_VERIFY` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `EMAIL` varchar(64) DEFAULT NULL,
  `DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `USER_ID` (`USER_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.email_verify: 0 rows
/*!40000 ALTER TABLE `EMAIL_VERIFY` DISABLE KEYS */;
/*!40000 ALTER TABLE `EMAIL_VERIFY` ENABLE KEYS */;

-- Dumping structure for table sa-mp.entrances
CREATE TABLE IF NOT EXISTS `ENTRANCES` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `OWNER` varchar(24) NOT NULL,
  `LABEL` varchar(32) NOT NULL,
  `X` float DEFAULT NULL,
  `Y` float DEFAULT NULL,
  `Z` float DEFAULT NULL,
  `EX` float DEFAULT NULL,
  `EY` float DEFAULT NULL,
  `EZ` float DEFAULT NULL,
  `INTERIOR` int(6) DEFAULT NULL,
  `WORLD` int(6) DEFAULT NULL,
  `CUSTOM` tinyint(1) DEFAULT '1',
  `VIP_ONLY` tinyint(1) DEFAULT '0',
  `MAP_ICON` tinyint(2) DEFAULT '-1',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.entrances: ~73 rows (approximately)
/*!40000 ALTER TABLE `ENTRANCES` DISABLE KEYS */;
INSERT INTO `ENTRANCES` (`ID`, `OWNER`, `LABEL`, `X`, `Y`, `Z`, `EX`, `EY`, `EZ`, `INTERIOR`, `WORLD`, `CUSTOM`, `VIP_ONLY`, `MAP_ICON`) VALUES
	(1, 'Jendral', '[ROOFTOP]', -2440.51, 820.97, 35.1838, -2438.12, 819.736, 65.5078, 0, 0, 0, 1, -1),
	(2, 'Queens', '[ROOFTOP]', -2475.42, 161.524, 35.1406, -2476.4, 155.654, 64.9332, 0, 0, 0, 1, -1),
	(3, 'Lorenc', '[ROOFTOP]', -2281.28, 923.617, 66.7333, -2280.7, 907.226, 96.8359, 0, 0, 0, 1, -1),
	(4, 'Lorenc', '[ROOFTOP]', -2372.56, 851.794, 41.0832, -2372.99, 856.774, 57.6094, 0, 0, 0, 1, -1),
	(5, 'MrFreeze', '[ROOFTOP]', -1696.34, 1030.73, 45.21, -1693.03, 1030.27, 56.906, 0, 0, 0, 1, -1),
	(6, 'Arros', '[ROOFTOP]', -2113.28, 1087.92, 71.5219, -2120.26, 1060.57, 96.9456, 0, 0, 0, 1, -1),
	(7, 'Deedz', '[ROOFTOP]', -1991.55, 821.036, 45.4453, -1984.25, 821.753, 92.3203, 0, 0, 0, 1, -1),
	(8, 'Arntz', '[ROOFTOP]', -1887.05, 761.114, 45.4469, -1860.11, 783.469, 93.9143, 0, 0, 0, 1, -1),
	(12, 'Cake', '[ROOFTOP]', -2724.62, 73.5155, 4.3359, -2727.8, 60.5538, 11.1953, 0, 0, 0, 1, -1),
	(13, '[RR]Natushi', '[ROOFTOP]', -1948.45, 827.377, 42.5405, -1947.54, 813.565, 77.73, 0, 0, 0, 1, -1),
	(14, 'Assassin', '[ROOFTOP]', 1370.81, -1341.39, 13.5469, 1378.12, -1381.71, 34.5537, 0, 0, 0, 1, -1),
	(15, 'Versec', '[ROOFTOP]', -2591.54, 147.298, 4.3359, -2586.2, 142.757, 17.6344, 0, 0, 0, 1, -1),
	(16, 'levi69', '[ROOFTOP]', -2496.06, 92.0874, 25.6172, -2506.09, 105.367, 35.1719, 0, 0, 0, 1, -1),
	(17, 'Robox', '[ROOFTOP]', -1732.39, 632.288, 25.0978, -1734.81, 634.491, 105.141, 0, 0, 0, 1, -1),
	(18, 'Amy', '[ROOFTOP]', -1975.7, 743.855, 45.4453, -1981.08, 759.798, 85.9219, 0, 0, 0, 1, -1),
	(19, 'Zorba', '[ROOFTOP]', 2408.47, 2005.9, 10.8203, 2400.15, 1997.04, 19.1563, 0, 0, 0, 1, -1),
	(21, 'Chrome_TV', '[ROOFTOP]', 2119.96, 1483.14, 10.8302, 2162.64, 1452.9, 24.1406, 0, 0, 0, 1, -1),
	(22, 'Rexer', '[ROOFTOP]', -2455.29, -113.917, 26.0669, -2450.13, -129.221, 51.8439, 0, 0, 0, 1, -1),
	(26, 'Thecover', '[ROOFTOP]', -1990.2, 767.386, 45.4453, -1982.22, 790.783, 107.031, 0, 0, 0, 1, -1),
	(27, 'Niels', '[ROOFTOP]', -2517.21, 234.854, 16.5137, -2517.21, 233.668, 21.9738, 0, 0, 0, 1, -1),
	(28, 'Diller', '[ROOFTOP]', -1779.65, 1013.57, 24.8906, -1774.93, 1019.54, 97.6932, 0, 0, 0, 1, -1),
	(29, 'PrinZeco', '[ROOFTOP]', 2238.69, 2225.7, 10.8203, 2220.89, 2245.89, 24.9297, 0, 0, 0, 1, -1),
	(30, 'Miley', '[ROOFTOP]', -2430.87, 1.8262, 35.3203, -2435.19, -3.0185, 47.9531, 0, 0, 0, 1, -1),
	(34, 'Syndicate', '[ROOFTOP]', -1806.33, 998.964, 24.8906, -1823.38, 988.706, 77.1422, 0, 0, 0, 1, -1),
	(35, 'Bang.', '[ROOFTOP]', -1977.5, 955.782, 45.4453, -1988.96, 967.918, 50.9922, 0, 0, 0, 1, -1),
	(36, 'Biscuits', '[ROOFTOP]', -1880.31, 960.538, 35.1719, -1860.13, 977.676, 49.8047, 0, 0, 0, 1, -1),
	(38, '_[Esteban]_', '[HOUSE]', -2121.42, 659.906, 52.3985, -2120.53, 659.958, 60.7005, 0, 0, 0, 0, -1),
	(39, '_[Esteban]_', '[HOUSE]', -2106.35, 659.913, 52.3932, -2107.25, 659.898, 60.7005, 0, 0, 0, 0, -1),
	(42, 'Executive Esuite Roof', '[ROOFTOP]', -1757.24, 774.058, 45.297, -1739.37, 787.629, 167.654, 0, 0, 0, 1, -1),
	(43, 'Executive Esuite Roof', '[HOUSE]', -1737.09, 801.052, 24.8906, -1757.27, 805.695, 45.3265, 0, 0, 0, 1, -1),
	(44, 'Niels', '[HOUSE]', -2521.84, 248.884, 11.0938, -2521.79, 248.882, 16.4937, 0, 0, 0, 1, -1),
	(45, 'wolfganja', '[VAULT]', -2912.62, 461.508, 9.7935, -2875.36, 459.966, 1240.33, 0, 0, 1, 0, -1),
	(48, 'Faze', '[ROOFTOP]', -2629.48, 696.284, 27.9394, -2697.61, 689.003, 66.0922, 0, 0, 0, 1, -1),
	(49, 'Tcc', '[ROOFTOP]', -1811.68, 1115.49, 45.4375, -1814.46, 1134.58, 68.9618, 0, 0, 0, 1, -1),
	(52, 'iTRiiPY', '[ROOFTOP]', -2016.31, 900.751, 45.4453, -2035.34, 893.64, 67.2109, 0, 0, 0, 1, -1),
	(54, 'CHUKYCDM', '[ROOFTOP]', 1328.13, -1271.28, 13.5469, 1324.01, -1262.32, 27.4789, 0, 0, 0, 1, -1),
	(56, 'Seen', '[ROOFTOP]', -2208.02, 553.712, 35.1719, -2213.91, 544.318, 82.3334, 0, 0, 0, 1, -1),
	(59, 'Lorenc', '[ROOFTOP]', -1857.58, 864.584, 35.1831, -1846.45, 867.364, 87.1946, 0, 0, 0, 1, -1),
	(61, 'LivBoeree', '[LIVBOEREE\'S PENTHOUSE]', -1618.64, 1043.39, 7.1875, -1635.13, 1033.46, 48.1747, 0, 0, 1, 0, -1),
	(62, 'LivBoeree', '[ROOFTOP]', -1623.27, 1008.77, 54.0357, -1656.63, 1015.86, 69.828, 0, 0, 1, 0, -1),
	(64, 'levi69', '[ROOFTOP]', 1333.07, -1359.98, 13.5469, 1314.44, -1333.09, 35.6641, 0, 0, 0, 1, -1),
	(65, 'Lorenc', '[GARAGE]', -2661.93, 2075, 2.01314, -2701.12, 2074.98, 2.0231, 0, 0, 1, 0, -1),
	(66, 'Lorenc', '[ROOFTOP]', -1313.99, -753.419, 67.2459, -1314, -753.424, 60.2479, 0, 0, 0, 1, -1),
	(68, 'Lorenc', '[ROOFTOP]', 2576.9, 2082.43, 10.813, 2592.97, 2091.7, 15.672, 0, 0, 0, 0, -1),
	(69, 'Alone_GUY', '[ALONE\'S APARTMENT]', -1815.08, 1078.64, 46.0821, -1856.5, 1045.62, 137.369, 0, 0, 1, 1, -1),
	(71, 'Ahmyy', '[ROOFTOP]', -1833.83, 679.203, 35.1919, -1840.67, 685.234, 81.3984, 0, 0, 0, 1, -1),
	(72, 'Lorenc', '[ROOFTOP]', -1671.79, 1338.72, 7.1875, -1690.58, 1334.51, 16.2976, 0, 0, 0, 0, -1),
	(74, 'Lorenc', '[PENTHOUSE]', -2084.51, 771.092, 69.5625, -2086.39, 771.069, 76.4063, 0, 0, 0, 1, -1),
	(75, 'Lorenc', 'STUDIO', -2094.97, 769.829, 76.4062, -2094.94, 771.599, 81.5225, 0, 0, 0, 0, -1),
	(76, 'Brad', '[ROOFTOP]', 2182.04, 1128.86, 12.6542, 2188.4, 1120.87, 23.3469, 0, 0, 0, 1, -1),
	(77, 'ProKiller.', '[ROOFTOP]', -2156.06, 413.27, 35.1936, -2160.97, 416.587, 59.5489, 0, 0, 0, 1, -1),
	(79, 'Lorenc', '[ROOFTOP]', -1863.45, 1070.08, 46.0859, -1861.66, 1070.67, 145.133, 0, 0, 0, 1, -1),
	(80, 'NeXuS', '[ROOFTOP]', 2185.61, 2302.34, 10.8203, 2193.25, 2305.33, 21.2902, 0, 0, 0, 1, -1),
	(81, 'HydrogeN', '[UNDERWATER MANSION]', -1726.22, 1436.25, 1.40673, -1722.46, 1468.95, -27.277, 0, 0, 0, 1, -1),
	(82, '[TDK]Will_Joh', '[ROOFTOP]', 2627.71, 2840.92, 10.8203, 2631.1, 2817.15, 36.3222, 0, 0, 0, 0, -1),
	(83, '[TDK]Will_Joh', '[ROOFTOP]', 2679.58, 2776.53, 10.8203, 2691.8, 2784.9, 78.6257, 0, 0, 0, 0, -1),
	(84, 'Lorenc', '[PENTHOUSE]', -1911.85, 958.107, 35.1719, -1924.65, 953.512, 45.9203, 0, 0, 0, 1, -1),
	(94, 'Smoshi', '[ROOFTOP]', -2746.72, 208.866, 7.17272, -2735.31, 191.795, 19.835, 0, 0, 0, 1, -1),
	(95, 'Smoshi', '[ROOFTOP]', -1879.12, 743.359, 45.4453, -1822.92, 756.285, 107.211, 0, 0, 0, 1, -1),
	(96, 'Royce', '[CONTROL ROOM]', -820.083, 672.156, 19.369, -762.853, 712.583, 1582.97, 0, 0, 0, 1, -1),
	(98, 'Abbott', '[ROOFTOP]', -2037.05, 451.403, 35.1723, -2067.77, 443.605, 139.742, 0, 0, 0, 0, -1),
	(99, 'Sultan', '[ROOFTOP]', -1676.72, 1027.74, 7.92188, -1687.05, 1003.51, 74.8015, 0, 0, 0, 0, -1),
	(100, 'haynoplays', '[UPSTAIRS]', -2273.55, 419.151, 35.253, -2273.51, 419.228, 41.152, 0, 0, 0, 1, -1),
	(101, 'haynoplays', '[UPSTAIRS]', -2272.58, 453.917, 41.163, -2272.4, 454.009, 49.243, 0, 0, 0, 1, -1),
	(103, 'Lorenc', '[NG FACILITY]', -2369.63, 583.402, 25.618, -2342.68, 592.17, 41.978, 0, 0, 0, 0, -1),
	(104, '[vT][A]VeNGe[R]171_', '[ROOFTOP]', -1697.55, 868.545, 24.8534, -1643.69, 880.439, 136.042, 0, 0, 0, 0, -1),
	(105, 'Stev', '[STEV\'S APARTMENT]', -2084.66, 849.106, 69.5625, -2087.36, 839.434, 76.427, 0, 0, 0, 1, -1),
	(106, 'willHunting', 'ROOFTOP', -2018.75, 1194.19, 45.4574, -2019.49, 1198.32, 80.75, 0, 0, 0, 0, -1),
	(107, 'willHunting', '[ROOF TOP]', -2018.76, 1194.18, 45.4574, -2019.49, 1198.32, 80.75, 0, 0, 0, 0, -1),
	(108, 'willHunting', '[ROOFTOP]', -2018.76, 1194.19, 45.4574, -2019.49, 1198.32, 80.75, 0, 0, 0, 0, -1),
	(109, 'Milky', '[SEWER]', -1990.77, 1033.78, 55.7266, 3638.48, 5215.5, 1203.32, 0, 50, 1, 1, -1),
	(110, 'Milky', '[SEWER]', -1990.77, 1033.73, 55.7266, 3638.48, 5215.5, 1203.32, 1, 50, 1, 1, -1),
	(111, 'Milky', '[SEWER]', -1990.77, 1033.74, 55.7266, 3638.48, 5215.5, 1203.32, 1, 1, 1, 0, -1);
/*!40000 ALTER TABLE `ENTRANCES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.feedback
CREATE TABLE IF NOT EXISTS `FEEDBACK` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) NOT NULL,
  `FEEDBACK` text,
  `REWARD` int(3) DEFAULT '0',
  `DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.feedback: ~0 rows (approximately)
/*!40000 ALTER TABLE `FEEDBACK` DISABLE KEYS */;
/*!40000 ALTER TABLE `FEEDBACK` ENABLE KEYS */;

-- Dumping structure for table sa-mp.furniture
CREATE TABLE IF NOT EXISTS `FURNITURE` (
  `ID` int(11) NOT NULL,
  `HOUSE_ID` int(11) NOT NULL,
  `OWNER` int(11) DEFAULT NULL,
  `MODEL` int(11) NOT NULL,
  `X` float NOT NULL,
  `Y` float NOT NULL,
  `Z` float NOT NULL,
  `RX` float DEFAULT '0',
  `RY` float DEFAULT '0',
  `RZ` float DEFAULT '0',
  PRIMARY KEY (`ID`,`HOUSE_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.furniture: ~0 rows (approximately)
/*!40000 ALTER TABLE `FURNITURE` DISABLE KEYS */;
/*!40000 ALTER TABLE `FURNITURE` ENABLE KEYS */;

-- Dumping structure for table sa-mp.gangs
CREATE TABLE IF NOT EXISTS `GANGS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(30) NOT NULL,
  `CLAN_TAG` varchar(8) DEFAULT NULL,
  `LEADER` int(11) NOT NULL,
  `COLOR` int(11) NOT NULL,
  `BANK` int(10) DEFAULT '0',
  `KILLS` int(10) DEFAULT '1',
  `DEATHS` int(10) DEFAULT '1',
  `SCORE` int(10) DEFAULT '0',
  `INVITE_ONLY` tinyint(1) DEFAULT '0',
  `JOIN_MSG` varchar(96) DEFAULT NULL,
  `RESPECT` int(10) DEFAULT '0',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `LEADER` (`LEADER`)
) ENGINE=InnoDB AUTO_INCREMENT=10619 DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.gangs: ~0 rows (approximately)
/*!40000 ALTER TABLE `GANGS` DISABLE KEYS */;
/*!40000 ALTER TABLE `GANGS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.gang_coleaders
CREATE TABLE IF NOT EXISTS `GANG_COLEADERS` (
  `GANG_ID` int(11) DEFAULT NULL,
  `USER_ID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`USER_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.gang_coleaders: 0 rows
/*!40000 ALTER TABLE `GANG_COLEADERS` DISABLE KEYS */;
/*!40000 ALTER TABLE `GANG_COLEADERS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.gang_facilities
CREATE TABLE IF NOT EXISTS `GANG_FACILITIES` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `GANG_ID` int(11) DEFAULT NULL,
  `ENTER_X` float DEFAULT NULL,
  `ENTER_Y` float DEFAULT NULL,
  `ENTER_Z` float DEFAULT NULL,
  `ZONE_MIN_X` float DEFAULT NULL,
  `ZONE_MIN_Y` float DEFAULT NULL,
  `ZONE_MAX_X` float DEFAULT NULL,
  `ZONE_MAX_Y` float DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.gang_facilities: ~0 rows (approximately)
/*!40000 ALTER TABLE `GANG_FACILITIES` DISABLE KEYS */;
/*!40000 ALTER TABLE `GANG_FACILITIES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.gang_vehicles
CREATE TABLE IF NOT EXISTS `GANG_VEHICLES` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `GANG_ID` int(11) DEFAULT NULL,
  `MODEL_ID` int(11) DEFAULT NULL,
  `COLOR1` int(4) DEFAULT NULL,
  `COLOR2` int(4) DEFAULT NULL,
  `PAINTJOB` tinyint(2) DEFAULT NULL,
  `MODS` varchar(90) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `GANG_ID` (`GANG_ID`),
  CONSTRAINT `GANG_VEHICLES_ibfk_1` FOREIGN KEY (`GANG_ID`) REFERENCES `GANGS` (`ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.gang_vehicles: ~0 rows (approximately)
/*!40000 ALTER TABLE `GANG_VEHICLES` DISABLE KEYS */;
/*!40000 ALTER TABLE `GANG_VEHICLES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.garages
CREATE TABLE IF NOT EXISTS `GARAGES` (
  `ID` smallint(4) NOT NULL,
  `OWNER` int(11) NOT NULL DEFAULT '0',
  `PRICE` int(11) NOT NULL,
  `INTERIOR` tinyint(2) NOT NULL,
  `X` float NOT NULL,
  `Y` float NOT NULL,
  `Z` float NOT NULL,
  `ANGLE` float NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.garages: ~0 rows (approximately)
/*!40000 ALTER TABLE `GARAGES` DISABLE KEYS */;
/*!40000 ALTER TABLE `GARAGES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.gates
CREATE TABLE IF NOT EXISTS `GATES` (
  `ID` int(4) NOT NULL,
  `OWNER` int(11) DEFAULT NULL,
  `PASSWORD` varchar(8) DEFAULT NULL,
  `NAME` varchar(24) DEFAULT NULL,
  `MODEL` int(5) DEFAULT NULL,
  `TIME` int(9) DEFAULT '2000',
  `SPEED` float DEFAULT NULL,
  `RANGE` float DEFAULT NULL,
  `X` float DEFAULT NULL,
  `Y` float DEFAULT NULL,
  `Z` float DEFAULT NULL,
  `RX` float DEFAULT NULL,
  `RY` float DEFAULT NULL,
  `RZ` float DEFAULT NULL,
  `MOVE_X` float DEFAULT NULL,
  `MOVE_Y` float DEFAULT NULL,
  `MOVE_Z` float DEFAULT NULL,
  `MOVE_RX` float DEFAULT NULL,
  `MOVE_RY` float DEFAULT NULL,
  `MOVE_RZ` float DEFAULT NULL,
  `GANG_ID` int(11) DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.gates: ~0 rows (approximately)
/*!40000 ALTER TABLE `GATES` DISABLE KEYS */;
/*!40000 ALTER TABLE `GATES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.help
CREATE TABLE IF NOT EXISTS `HELP` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `CATEGORY` tinyint(3) DEFAULT NULL,
  `SUBJECT` varchar(64) DEFAULT NULL,
  `CONTENT` text,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.help: ~0 rows (approximately)
/*!40000 ALTER TABLE `HELP` DISABLE KEYS */;
/*!40000 ALTER TABLE `HELP` ENABLE KEYS */;

-- Dumping structure for table sa-mp.houses
CREATE TABLE IF NOT EXISTS `HOUSES` (
  `ID` int(3) NOT NULL,
  `NAME` varchar(30) DEFAULT NULL,
  `OWNER` varchar(24) DEFAULT NULL,
  `COST` int(11) DEFAULT NULL,
  `EX` float DEFAULT NULL,
  `EY` float DEFAULT NULL,
  `EZ` float DEFAULT NULL,
  `TX` float DEFAULT NULL,
  `TY` float DEFAULT NULL,
  `TZ` float DEFAULT NULL,
  `INTERIOR` int(3) DEFAULT NULL,
  `PASSWORD` varchar(4) DEFAULT 'N/A',
  `WEAPONS` varchar(21) DEFAULT '0.0.0.0.0.0.0.',
  `AMMO` varchar(50) DEFAULT '-1.-1.-1.-1.-1.-1.-1.',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.houses: ~0 rows (approximately)
/*!40000 ALTER TABLE `HOUSES` DISABLE KEYS */;
/*!40000 ALTER TABLE `HOUSES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.house_listings
CREATE TABLE IF NOT EXISTS `HOUSE_LISTINGS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `HOUSE_ID` int(11) DEFAULT NULL,
  `USER_ID` int(11) DEFAULT NULL,
  `ASK` float DEFAULT NULL,
  `LISTING_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `SALE_DATE` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `HOUSE_ID` (`HOUSE_ID`),
  CONSTRAINT `HOUSE_LISTINGS_ibfk_1` FOREIGN KEY (`HOUSE_ID`) REFERENCES `HOUSES` (`ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.house_listings: ~0 rows (approximately)
/*!40000 ALTER TABLE `HOUSE_LISTINGS` DISABLE KEYS */;
/*!40000 ALTER TABLE `HOUSE_LISTINGS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.ic_market_log
CREATE TABLE IF NOT EXISTS `IC_MARKET_LOG` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `SELLER_ID` int(11) DEFAULT NULL,
  `BUYER_ID` int(11) DEFAULT NULL,
  `ASK_RATE` int(11) DEFAULT NULL,
  `IC_AMOUNT` float DEFAULT NULL,
  `DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.ic_market_log: ~0 rows (approximately)
/*!40000 ALTER TABLE `IC_MARKET_LOG` DISABLE KEYS */;
/*!40000 ALTER TABLE `IC_MARKET_LOG` ENABLE KEYS */;

-- Dumping structure for table sa-mp.ic_sell_orders
CREATE TABLE IF NOT EXISTS `IC_SELL_ORDERS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `ASK_PRICE` int(11) DEFAULT NULL,
  `AVAILABLE_IC` float DEFAULT NULL,
  `TOTAL_IC` float DEFAULT NULL,
  `LISTING_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.ic_sell_orders: ~0 rows (approximately)
/*!40000 ALTER TABLE `IC_SELL_ORDERS` DISABLE KEYS */;
/*!40000 ALTER TABLE `IC_SELL_ORDERS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.megaban
CREATE TABLE IF NOT EXISTS `MEGABAN` (
  `ISP` varchar(128) DEFAULT NULL,
  `TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `ISP` (`ISP`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.megaban: ~0 rows (approximately)
/*!40000 ALTER TABLE `MEGABAN` DISABLE KEYS */;
/*!40000 ALTER TABLE `MEGABAN` ENABLE KEYS */;

-- Dumping structure for table sa-mp.name_changes
CREATE TABLE IF NOT EXISTS `name_changes` (
  `USER_ID` int(11) DEFAULT NULL,
  `ADMIN_ID` int(11) DEFAULT NULL,
  `NAME` varchar(25) DEFAULT NULL,
  `TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.name_changes: ~0 rows (approximately)
/*!40000 ALTER TABLE `name_changes` DISABLE KEYS */;
/*!40000 ALTER TABLE `name_changes` ENABLE KEYS */;

-- Dumping structure for table sa-mp.notes
CREATE TABLE IF NOT EXISTS `NOTES` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) NOT NULL,
  `ADDED_BY` int(11) NOT NULL,
  `NOTE` varchar(72) DEFAULT NULL,
  `TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `DELETED` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.notes: ~0 rows (approximately)
/*!40000 ALTER TABLE `NOTES` DISABLE KEYS */;
/*!40000 ALTER TABLE `NOTES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.ranks_previous
CREATE TABLE IF NOT EXISTS `RANKS_PREVIOUS` (
  `USER_ID` int(11) NOT NULL,
  `RANK` int(6) DEFAULT NULL,
  PRIMARY KEY (`USER_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.ranks_previous: 0 rows
/*!40000 ALTER TABLE `RANKS_PREVIOUS` DISABLE KEYS */;
/*!40000 ALTER TABLE `RANKS_PREVIOUS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.redeemed
CREATE TABLE IF NOT EXISTS `REDEEMED` (
  `ID` varchar(32) NOT NULL,
  `REDEEMER` varchar(25) NOT NULL,
  `TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `ID` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.redeemed: ~0 rows (approximately)
/*!40000 ALTER TABLE `REDEEMED` DISABLE KEYS */;
/*!40000 ALTER TABLE `REDEEMED` ENABLE KEYS */;

-- Dumping structure for table sa-mp.server
CREATE TABLE IF NOT EXISTS `SERVER` (
  `NAME` varchar(64) NOT NULL,
  `INT_VAL` int(11) NOT NULL,
  `FLOAT_VAL` float NOT NULL,
  `STRING_VAL` varchar(128) NOT NULL,
  `TYPE` tinyint(1) DEFAULT '1',
  UNIQUE KEY `NAME` (`NAME`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.server: ~0 rows (approximately)
/*!40000 ALTER TABLE `SERVER` DISABLE KEYS */;
/*!40000 ALTER TABLE `SERVER` ENABLE KEYS */;

-- Dumping structure for table sa-mp.settings
CREATE TABLE IF NOT EXISTS `SETTINGS` (
  `USER_ID` int(11) DEFAULT NULL,
  `SETTING_ID` tinyint(3) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.settings: ~0 rows (approximately)
/*!40000 ALTER TABLE `SETTINGS` DISABLE KEYS */;
/*!40000 ALTER TABLE `SETTINGS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.slot_machines
CREATE TABLE IF NOT EXISTS `SLOT_MACHINES` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `DESCRIPTION` varchar(16) DEFAULT NULL,
  `ENTRY_FEE` int(11) DEFAULT NULL,
  `POOL_ID` int(11) DEFAULT NULL,
  `X` float DEFAULT NULL,
  `Y` float DEFAULT NULL,
  `Z` float DEFAULT NULL,
  `ROTATION` float DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.slot_machines: ~54 rows (approximately)
/*!40000 ALTER TABLE `SLOT_MACHINES` DISABLE KEYS */;
INSERT INTO `SLOT_MACHINES` (`ID`, `DESCRIPTION`, `ENTRY_FEE`, `POOL_ID`, `X`, `Y`, `Z`, `ROTATION`) VALUES
	(1, 'calig-petty', 5000, 0, 2255.19, 1618.08, 1006.77, 180),
	(2, 'calig-low', 5000, 0, 2255.15, 1617.55, 1006.77, 0),
	(3, 'calig-petty', 5000, 0, 2255.19, 1614.19, 1006.77, 180),
	(4, 'calig-low', 5000, 0, 2255.15, 1613.63, 1006.77, 0),
	(5, 'calig-petty', 5000, 0, 2255.19, 1610.14, 1006.77, 180),
	(6, 'calig-petty', 5000, 0, 2255.15, 1609.59, 1006.77, 0),
	(7, 'calig-high', 5000, 0, 2269.24, 1606.68, 1006.77, -90),
	(8, 'calig-high', 5000, 0, 2269.8, 1606.65, 1006.77, 90),
	(9, 'calig-high', 5000, 0, 2273.28, 1606.68, 1006.77, -90),
	(10, 'calig-high', 5000, 0, 2273.85, 1606.65, 1006.77, 90),
	(11, 'calig-med', 5000, 0, 2220.66, 1603.93, 1006.77, -90),
	(12, 'calig-med', 5000, 0, 2221.22, 1603.9, 1006.77, 90),
	(13, 'calig-med', 5000, 0, 2217.01, 1603.93, 1006.77, -90),
	(14, 'calig-med', 5000, 0, 2217.57, 1603.9, 1006.77, 90),
	(15, 'calig-low', 5000, 0, 2218.63, 1614.2, 1006.77, 0),
	(16, 'calig-low', 5000, 0, 2218.66, 1614.76, 1006.77, 180),
	(17, 'calig-low', 5000, 0, 2218.63, 1618.55, 1006.77, 0),
	(18, 'calig-low', 5000, 0, 2218.66, 1619.1, 1006.77, 180),
	(19, 'calig-low', 5000, 0, 2218.66, 1592.92, 1006.77, 180),
	(20, 'calig-low', 5000, 0, 2218.63, 1592.36, 1006.77, 0),
	(21, 'calig-low', 5000, 0, 2218.66, 1588.62, 1006.77, 180),
	(22, 'calig-low', 5000, 0, 2218.63, 1588.06, 1006.77, 0),
	(23, 'drag-med', 10000, 1, 1965.1, 1037.35, 992.981, 101.8),
	(24, 'drag-med', 10000, 1, 1964.56, 1037.28, 992.981, -77.6999),
	(25, 'drag-med', 10000, 1, 1961.92, 1043.37, 992.981, -56.2999),
	(26, 'drag-med', 10000, 1, 1962.39, 1043.64, 992.981, 124.2),
	(27, 'drag-med', 10000, 1, 1957.33, 1047.98, 992.981, -34.5998),
	(28, 'drag-med', 10000, 1, 1957.65, 1048.41, 992.981, 145.4),
	(29, 'drag-low', 10000, 1, 1965.08, 998.305, 992.981, 79.2),
	(30, 'drag-low', 10000, 1, 1964.58, 998.448, 992.981, -100.9),
	(31, 'drag-low', 10000, 1, 1962.41, 991.869, 992.981, 55.3999),
	(32, 'drag-low', 10000, 1, 1961.99, 992.215, 992.981, -124.8),
	(33, 'drag-low', 10000, 1, 1957.45, 987.664, 992.981, -146.399),
	(34, 'drag-low', 10000, 1, 1957.72, 987.198, 992.981, 33.9),
	(35, 'visage', 25000, 2, 2597.91, 1612.59, 1506.72, 0),
	(36, 'visage', 25000, 2, 2597.91, 1618.59, 1506.72, 0),
	(37, 'visage', 25000, 2, 2597.91, 1618.94, 1506.74, 180),
	(38, 'visage', 25000, 2, 2597.91, 1612.94, 1506.74, 180),
	(39, 'visage', 25000, 2, 2597.91, 1594.46, 1506.74, 180),
	(40, 'visage', 25000, 2, 2597.91, 1594.12, 1506.72, 0),
	(41, 'visage', 25000, 2, 2597.91, 1588.12, 1506.72, 0),
	(42, 'visage', 25000, 2, 2597.91, 1588.46, 1506.74, 180),
	(43, 'visage', 25000, 2, 2608.91, 1588.12, 1506.72, 0),
	(44, 'visage', 25000, 2, 2608.91, 1588.46, 1506.74, 180),
	(45, 'visage', 25000, 2, 2608.91, 1594.46, 1506.74, 180),
	(46, 'visage', 25000, 2, 2608.91, 1612.59, 1506.72, 0),
	(47, 'visage', 25000, 2, 2608.91, 1612.94, 1506.74, 180),
	(48, 'visage', 25000, 2, 2608.91, 1618.59, 1506.72, 0),
	(49, 'visage', 25000, 2, 2608.91, 1618.94, 1506.74, 180),
	(50, 'visage', 25000, 2, 2608.91, 1594.11, 1506.74, 0),
	(51, 'visage', 50000, 2, 2587.27, 1609.03, 1506.74, 0),
	(52, 'visage', 50000, 2, 2587.27, 1609.53, 1506.74, 180),
	(53, 'visage', 50000, 2, 2587.08, 1615.62, 1506.74, -90),
	(54, 'visage', 50000, 2, 2587.6, 1615.58, 1506.74, 90);
/*!40000 ALTER TABLE `SLOT_MACHINES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.stats
CREATE TABLE IF NOT EXISTS `STATS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(200) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `INT_VAL` int(32) DEFAULT NULL,
  `STRING_VAL` varchar(200) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `FLOAT_VAL` float DEFAULT NULL,
  `CREATED_AT` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.stats: ~0 rows (approximately)
/*!40000 ALTER TABLE `STATS` DISABLE KEYS */;
/*!40000 ALTER TABLE `STATS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.stock_owners
CREATE TABLE IF NOT EXISTS `STOCK_OWNERS` (
  `USER_ID` int(11) NOT NULL DEFAULT '0',
  `STOCK_ID` int(11) NOT NULL DEFAULT '0',
  `SHARES` float DEFAULT NULL,
  PRIMARY KEY (`USER_ID`,`STOCK_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.stock_owners: ~0 rows (approximately)
/*!40000 ALTER TABLE `STOCK_OWNERS` DISABLE KEYS */;
/*!40000 ALTER TABLE `STOCK_OWNERS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.stock_reports
CREATE TABLE IF NOT EXISTS `STOCK_REPORTS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `STOCK_ID` int(11) DEFAULT NULL,
  `POOL` float DEFAULT NULL,
  `DONATIONS` float DEFAULT '0',
  `PRICE` float DEFAULT NULL,
  `REPORTING_TIME` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.stock_reports: ~0 rows (approximately)
/*!40000 ALTER TABLE `STOCK_REPORTS` DISABLE KEYS */;
/*!40000 ALTER TABLE `STOCK_REPORTS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.stock_sell_orders
CREATE TABLE IF NOT EXISTS `STOCK_SELL_ORDERS` (
  `STOCK_ID` int(11) NOT NULL DEFAULT '0',
  `USER_ID` int(11) NOT NULL DEFAULT '0',
  `SHARES` float DEFAULT NULL,
  `LIST_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`STOCK_ID`,`USER_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.stock_sell_orders: ~0 rows (approximately)
/*!40000 ALTER TABLE `STOCK_SELL_ORDERS` DISABLE KEYS */;
/*!40000 ALTER TABLE `STOCK_SELL_ORDERS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.stock_trade_log
CREATE TABLE IF NOT EXISTS `STOCK_TRADE_LOG` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `STOCK_ID` int(11) DEFAULT NULL,
  `BUYER_ID` int(11) DEFAULT NULL,
  `SELLER_ID` int(11) DEFAULT NULL,
  `SHARES` float DEFAULT NULL,
  `PRICE` float DEFAULT NULL,
  `DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.stock_trade_log: ~0 rows (approximately)
/*!40000 ALTER TABLE `STOCK_TRADE_LOG` DISABLE KEYS */;
/*!40000 ALTER TABLE `STOCK_TRADE_LOG` ENABLE KEYS */;

-- Dumping structure for table sa-mp.streaks
CREATE TABLE IF NOT EXISTS `STREAKS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `STREAK_ID` tinyint(3) DEFAULT NULL,
  `STREAK` int(5) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `USER_STREAK_ID` (`USER_ID`,`STREAK_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.streaks: 0 rows
/*!40000 ALTER TABLE `STREAKS` DISABLE KEYS */;
/*!40000 ALTER TABLE `STREAKS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.top_donor
CREATE TABLE IF NOT EXISTS `TOP_DONOR` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `AMOUNT` float DEFAULT NULL,
  `LAST_AMOUNT` float DEFAULT '0',
  `TIME` int(11) DEFAULT '0',
  `HIDE` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `USER_ID` (`USER_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.top_donor: ~0 rows (approximately)
/*!40000 ALTER TABLE `TOP_DONOR` DISABLE KEYS */;
/*!40000 ALTER TABLE `TOP_DONOR` ENABLE KEYS */;

-- Dumping structure for table sa-mp.toys
CREATE TABLE IF NOT EXISTS `TOYS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `SLOT_ID` tinyint(1) DEFAULT NULL,
  `ENABLED` tinyint(1) DEFAULT NULL,
  `MODEL_ID` mediumint(6) DEFAULT NULL,
  `BONE` tinyint(2) DEFAULT NULL,
  `OX` float DEFAULT '0',
  `OY` float DEFAULT '0',
  `OZ` float DEFAULT '0',
  `RX` float DEFAULT '0',
  `RY` float DEFAULT '0',
  `RZ` float DEFAULT '0',
  `SX` float DEFAULT '1',
  `SY` float DEFAULT '1',
  `SZ` float DEFAULT '1',
  `COLOR` int(11) DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.toys: ~0 rows (approximately)
/*!40000 ALTER TABLE `TOYS` DISABLE KEYS */;
/*!40000 ALTER TABLE `TOYS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.toy_unlocks
CREATE TABLE IF NOT EXISTS `TOY_UNLOCKS` (
  `USER_ID` int(11) DEFAULT NULL,
  `TOY_ID` smallint(3) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.toy_unlocks: ~0 rows (approximately)
/*!40000 ALTER TABLE `TOY_UNLOCKS` DISABLE KEYS */;
/*!40000 ALTER TABLE `TOY_UNLOCKS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.transactions
CREATE TABLE IF NOT EXISTS `TRANSACTIONS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `TO_ID` int(11) DEFAULT NULL,
  `FROM_ID` int(11) DEFAULT NULL,
  `CASH` int(11) NOT NULL DEFAULT '0',
  `NATURE` varchar(16) DEFAULT 'transaction',
  `DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.transactions: ~0 rows (approximately)
/*!40000 ALTER TABLE `TRANSACTIONS` DISABLE KEYS */;
/*!40000 ALTER TABLE `TRANSACTIONS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.transactions_ic
CREATE TABLE IF NOT EXISTS `TRANSACTIONS_IC` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `TO_ID` int(11) DEFAULT NULL,
  `FROM_ID` int(11) DEFAULT NULL,
  `IC` float DEFAULT NULL,
  `DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.transactions_ic: ~0 rows (approximately)
/*!40000 ALTER TABLE `TRANSACTIONS_IC` DISABLE KEYS */;
/*!40000 ALTER TABLE `TRANSACTIONS_IC` ENABLE KEYS */;

-- Dumping structure for table sa-mp.users
CREATE TABLE IF NOT EXISTS `USERS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(25) DEFAULT NULL,
  `PASSWORD` varchar(130) DEFAULT NULL,
  `SALT` varchar(24) DEFAULT NULL,
  `IP` varchar(16) DEFAULT NULL,
  `SCORE` int(10) DEFAULT NULL,
  `CASH` int(10) DEFAULT NULL,
  `ADMINLEVEL` int(2) DEFAULT NULL,
  `BANKMONEY` int(10) DEFAULT NULL,
  `OWNEDHOUSES` int(2) DEFAULT NULL,
  `KILLS` int(10) DEFAULT NULL,
  `DEATHS` int(10) DEFAULT NULL,
  `RANK` decimal(13,3) NOT NULL DEFAULT '0.000',
  `XP` int(10) DEFAULT NULL,
  `OWNEDCARS` int(2) DEFAULT NULL,
  `LASTLOGGED` int(15) DEFAULT NULL,
  `VIP_PACKAGE` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `VIP_EXPIRE` int(12) DEFAULT NULL,
  `LAST_SKIN` int(4) DEFAULT NULL,
  `COP_BAN` int(2) DEFAULT NULL,
  `UPTIME` int(10) DEFAULT NULL,
  `ARRESTS` int(10) DEFAULT NULL,
  `FIGHTSTYLE` int(3) DEFAULT NULL,
  `VIPWEP1` int(3) DEFAULT NULL,
  `VIPWEP2` int(3) DEFAULT NULL,
  `VIPWEP3` int(3) DEFAULT NULL,
  `MUTE_TIME` int(12) DEFAULT NULL,
  `WANTEDLVL` int(6) DEFAULT NULL,
  `ROBBERIES` int(8) DEFAULT NULL,
  `PING_IMMUNE` int(2) DEFAULT NULL,
  `FIRES` int(10) DEFAULT NULL,
  `CONTRACTS` int(8) DEFAULT NULL,
  `COP_TUTORIAL` tinyint(2) DEFAULT NULL,
  `JOB` tinyint(2) NOT NULL DEFAULT '0',
  `JAIL_TIME` int(6) NOT NULL DEFAULT '0',
  `JAIL_ADMIN` tinyint(1) NOT NULL DEFAULT '0',
  `BURGLARIES` int(8) NOT NULL DEFAULT '0',
  `ARMY_BAN` tinyint(1) NOT NULL DEFAULT '0',
  `ROPES` tinyint(2) DEFAULT '0',
  `C4` tinyint(2) DEFAULT '0',
  `MELTERS` tinyint(2) DEFAULT '0',
  `SCISSORS` tinyint(2) DEFAULT '0',
  `FOILS` tinyint(2) DEFAULT '0',
  `PINS` tinyint(2) DEFAULT '0',
  `BOUNTY` int(11) DEFAULT '0',
  `WEED` tinyint(3) DEFAULT '0',
  `LAST_IP` varchar(16) DEFAULT NULL,
  `CITY` tinyint(1) DEFAULT '0',
  `METH` tinyint(3) NOT NULL DEFAULT '0',
  `SODA` tinyint(3) NOT NULL DEFAULT '0',
  `ACID` tinyint(3) NOT NULL DEFAULT '0',
  `GAS` tinyint(3) NOT NULL DEFAULT '0',
  `IS_CUFFED` tinyint(1) DEFAULT '0',
  `BLEW_JAILS` int(10) DEFAULT '0',
  `BLEW_VAULT` int(10) DEFAULT '0',
  `VEHICLES_JACKED` int(10) DEFAULT '0',
  `METH_YIELDED` int(10) DEFAULT '0',
  `WEEKEND_UPTIME` int(10) DEFAULT '0',
  `DRILL` smallint(3) unsigned DEFAULT '0',
  `VIP_JOB` tinyint(2) NOT NULL DEFAULT '0',
  `TRUCKED` int(10) DEFAULT '0',
  `PILOT` int(6) DEFAULT '0',
  `COINS` decimal(16,6) DEFAULT '0.000000',
  `GANG_ID` int(6) DEFAULT '-1',
  `ONLINE` tinyint(1) DEFAULT '0',
  `HIT_SOUND` tinyint(2) unsigned DEFAULT '0',
  `EXTRA_SLOTS` tinyint(2) NOT NULL DEFAULT '0',
  `FORCE_AC` int(11) DEFAULT '0',
  `CASINO_REWARDS` float DEFAULT '0',
  `VISAGE_HIGHROLLER` tinyint(1) DEFAULT '0',
  `FIREWORKS` int(5) DEFAULT '0',
  `USED_EMAIL` tinyint(1) DEFAULT '0',
  `TAX_TIME` int(11) DEFAULT '0',
  `EXPLOSIVE_BULLETS` int(10) DEFAULT '0',
  `SPAWN` varchar(9) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `NAME` (`NAME`),
  UNIQUE KEY `NAME_2` (`NAME`)
) ENGINE=InnoDB AUTO_INCREMENT=926053 DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.users: ~0 rows (approximately)
/*!40000 ALTER TABLE `USERS` DISABLE KEYS */;
/*!40000 ALTER TABLE `USERS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.user_confirmed_ips
CREATE TABLE IF NOT EXISTS `USER_CONFIRMED_IPS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `IP` varchar(16) DEFAULT NULL,
  `TOKEN` varchar(8) DEFAULT NULL,
  `CONFIRMED` tinyint(1) DEFAULT NULL,
  `DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `USER_ID_IP` (`USER_ID`,`IP`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.user_confirmed_ips: 0 rows
/*!40000 ALTER TABLE `USER_CONFIRMED_IPS` DISABLE KEYS */;
/*!40000 ALTER TABLE `USER_CONFIRMED_IPS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.user_levels
CREATE TABLE IF NOT EXISTS `USER_LEVELS` (
  `USER_ID` int(11) NOT NULL DEFAULT '0',
  `LEVEL_ID` int(11) NOT NULL DEFAULT '0',
  `EXPERIENCE` float DEFAULT NULL,
  PRIMARY KEY (`USER_ID`,`LEVEL_ID`),
  CONSTRAINT `USER_LEVELS_ibfk_1` FOREIGN KEY (`USER_ID`) REFERENCES `USERS` (`ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.user_levels: ~0 rows (approximately)
/*!40000 ALTER TABLE `USER_LEVELS` DISABLE KEYS */;
/*!40000 ALTER TABLE `USER_LEVELS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.vehicles
CREATE TABLE IF NOT EXISTS `VEHICLES` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `MODEL` int(3) DEFAULT NULL,
  `LOCKED` tinyint(1) DEFAULT NULL,
  `X` float DEFAULT NULL,
  `Y` float DEFAULT NULL,
  `Z` float DEFAULT NULL,
  `ANGLE` float DEFAULT NULL,
  `COLOR1` int(3) DEFAULT NULL,
  `COLOR2` int(3) DEFAULT NULL,
  `PRICE` int(11) DEFAULT NULL,
  `OWNER` int(11) DEFAULT NULL,
  `PLATE` varchar(32) DEFAULT 'SF-CNR',
  `PAINTJOB` tinyint(1) DEFAULT '3',
  `MODS` varchar(75) DEFAULT '0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.',
  `GARAGE` smallint(4) NOT NULL DEFAULT '-1',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.vehicles: ~0 rows (approximately)
/*!40000 ALTER TABLE `VEHICLES` DISABLE KEYS */;
/*!40000 ALTER TABLE `VEHICLES` ENABLE KEYS */;

-- Dumping structure for table sa-mp.visage_APARTMENTS
CREATE TABLE IF NOT EXISTS `VISAGE_APARTMENTS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `OWNER_ID` int(11) DEFAULT NULL,
  `TITLE` varchar(30) DEFAULT 'Apartment',
  `PASSCODE` varchar(4) DEFAULT NULL,
  `WORLD` int(11) DEFAULT NULL,
  `GAMBLING` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.visage_APARTMENTS: ~0 rows (approximately)
/*!40000 ALTER TABLE `VISAGE_APARTMENTS` DISABLE KEYS */;
/*!40000 ALTER TABLE `VISAGE_APARTMENTS` ENABLE KEYS */;

-- Dumping structure for table sa-mp.weapon_stats
CREATE TABLE IF NOT EXISTS `WEAPON_STATS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) DEFAULT NULL,
  `WEAPON_ID` tinyint(2) DEFAULT NULL,
  `KILLS` int(6) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `USER_WEAPON_ID` (`USER_ID`,`WEAPON_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.weapon_stats: ~0 rows (approximately)
/*!40000 ALTER TABLE `WEAPON_STATS` DISABLE KEYS */;
/*!40000 ALTER TABLE `WEAPON_STATS` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
