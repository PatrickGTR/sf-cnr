/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: server.pwn
 * Purpose: server related definitions
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define FILE_BUILD					"v11.40.120"
#define SERVER_NAME					"San Fierro Cops And Robbers (0.3.7)"
#define SERVER_WEBSITE				"www.sfcnr.com"
#define SERVER_IP					"54.36.127.43:7777"

/* ** Functions ** */
stock IsPlayerLeadMaintainer( playerid ) {
	return GetPlayerAccountID( playerid ) == 1; // limits money, coin, xp spawning to this user
}

stock IsPlayerServerMaintainer( playerid )
{
	new
		account_id = GetPlayerAccountID( playerid );

	return IsPlayerLeadMaintainer( playerid ) || account_id == 277833 || account_id == 758617; // same as lead maintainer, just cant spawn money/xp/coins
}
