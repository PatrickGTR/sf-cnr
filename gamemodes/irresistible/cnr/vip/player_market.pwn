/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */

/* ** Variables ** */

/* ** Hooks ** */

/* ** Functions ** */

/* ** Migrations ** */
/*
	CREATE TABLE IF NOT EXISTS IC_SELL_ORDERS (
		USER_ID int(11) PRIMARY KEY,
		ASK_PRICE int(11),
		TOTAL_IC float,
		LISTING_DATE TIMESTAMP default CURRENT_TIMESTAMP,
		UNIQUE (USER_ID),
		FOREIGN KEY (USER_ID) REFERENCES USERS (ID) ON DELETE CASCADE
	);

	CREATE TABLE IF NOT EXISTS IC_MARKET_LOG (
		`ID` int(11) AUTO_INCREMENT PRIMARY KEY,
		`SELLER_ID` int(11),
		`BUYER_ID` int(11),
		`ASK_RATE` int(11),
		`IC_AMOUNT` float,
		`DATE` TIMESTAMP default CURRENT_TIMESTAMP
	);
*/
