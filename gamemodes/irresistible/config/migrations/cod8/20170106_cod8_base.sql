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

-- Dumping structure for table sa-mp.cod
CREATE TABLE IF NOT EXISTS `cod` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `NAME` varchar(24) NOT NULL,
  `PASSWORD` varchar(130) NOT NULL,
  `SALT` varchar(16) NOT NULL,
  `SCORE` int(10) NOT NULL DEFAULT '0',
  `KILLS` int(10) NOT NULL DEFAULT '1',
  `DEATHS` int(10) NOT NULL DEFAULT '1',
  `ADMIN` int(2) NOT NULL DEFAULT '0',
  `XP` int(10) NOT NULL DEFAULT '0',
  `RANK` int(2) NOT NULL DEFAULT '0',
  `PRESTIGE` int(4) NOT NULL DEFAULT '0',
  `PRIMARY1` int(3) NOT NULL,
  `PRIMARY2` int(3) NOT NULL,
  `PRIMARY3` int(3) NOT NULL,
  `SECONDARY1` int(3) NOT NULL,
  `SECONDARY2` int(3) NOT NULL,
  `SECONDARY3` int(3) NOT NULL,
  `PERK_ONE1` int(2) DEFAULT '0',
  `PERK_ONE2` int(2) DEFAULT '0',
  `PERK_ONE3` int(2) DEFAULT '0',
  `PERK_TWO1` int(2) DEFAULT '0',
  `PERK_TWO2` int(2) DEFAULT '0',
  `PERK_TWO3` int(2) DEFAULT '0',
  `SPECIAL1` int(2) NOT NULL DEFAULT '0',
  `SPECIAL2` int(2) DEFAULT '0',
  `SPECIAL3` int(2) DEFAULT '0',
  `KILLSTREAK1` int(3) NOT NULL,
  `KILLSTREAK2` int(3) NOT NULL,
  `KILLSTREAK3` int(3) NOT NULL,
  `MUTE_TIME` int(11) DEFAULT '0',
  `CLASSNAME1` varchar(24) NOT NULL DEFAULT 'Custom Class 1',
  `CLASSNAME2` varchar(24) NOT NULL DEFAULT 'Custom Class 2',
  `CLASSNAME3` varchar(24) NOT NULL DEFAULT 'Custom Class 3',
  `HITMARKER` tinyint(1) NOT NULL DEFAULT '0',
  `HIT_SOUND` int(5) NOT NULL DEFAULT '0',
  `UPTIME` int(11) DEFAULT '0',
  `LAST_LOGGED` int(11) DEFAULT NULL,
  `CASH` int(11) NOT NULL DEFAULT '0',
  `WINS` int(6) NOT NULL DEFAULT '0',
  `LOSES` int(6) NOT NULL DEFAULT '0',
  `ZM_RANK` tinyint(2) NOT NULL DEFAULT '0',
  `ZM_XP` int(11) NOT NULL DEFAULT '0',
  `ZM_KILLS` int(6) NOT NULL DEFAULT '1',
  `ZM_DEATHS` int(6) NOT NULL DEFAULT '1',
  `VIP` tinyint(1) DEFAULT '0',
  `VIP_EXPIRE` int(11) DEFAULT '0',
  `DOUBLE_XP` int(11) DEFAULT '0',
  `LIVES` tinyint(2) DEFAULT '0',
  `MEDKITS` tinyint(2) DEFAULT '0',
  `WEAPONS` varchar(11) DEFAULT '0|0',
  `SKIN` smallint(3) DEFAULT '0',
  `ZM_PRESTIGE` smallint(3) DEFAULT '0',
  `ZM_SKIN` smallint(3) DEFAULT '-1',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `NAME` (`NAME`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Dumping data for table sa-mp.cod: ~0 rows (approximately)
/*!40000 ALTER TABLE `cod` DISABLE KEYS */;
/*!40000 ALTER TABLE `cod` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
