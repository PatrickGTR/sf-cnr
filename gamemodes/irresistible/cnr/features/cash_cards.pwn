/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cash_cards.inc
 * Purpose: enables players to redeem cash cards
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

// #define DIALOG_CASH_CARD 			28373

/* ** Commands ** */
CMD:redeemcashcard( playerid, params[ ] ) return cmd_cashcard( playerid, params );
CMD:cashcard( playerid, params[ ] )
{
	if ( ! IsPlayerEmailVerified( playerid ) ) return SendError( playerid, "This feature is accessible only to players that have an "COL_GREY"/email"COL_WHITE" on their account." );
	ShowPlayerDialog( playerid, DIALOG_CASH_CARD, DIALOG_STYLE_INPUT, ""COL_GREEN"Redeem Cash Card", ""COL_WHITE"Redeem your cash card by entering the code down below:", "Redeem", "Cancel" );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_CASH_CARD )
	{
		new
			cash_card[ 32 ];

		if ( sscanf( inputtext, "s[32]", cash_card ) )
		{
			SendError( playerid, "Your cash card must be between 1 and 32 characters." );
			ShowPlayerDialog( playerid, DIALOG_CASH_CARD, DIALOG_STYLE_INPUT, ""COL_GREEN"Redeem Cash Card", ""COL_WHITE"Redeem your cash card by entering the code down below:\n\n"COL_RED"Your cash card code must be between 1 and 32 characters.", "Redeem", "Cancel" );
			return 1;
		}

		// search database
		mysql_format( dbHandle, szBigString, sizeof( szBigString ), "SELECT * FROM `CASH_CARDS` WHERE `CODE` = '%e'", cash_card );
   		mysql_function_query( dbHandle, szBigString, true, "OnCheckCashCard", "d", playerid );
	}
	return 1;
}

thread OnCheckCashCard( playerid )
{
	new
		rows;

	cache_get_data( rows, tmpVariable );

	if ( ! rows )
		return SendError( playerid, "This cash card does not exist." ), 1;

	new max_uses = cache_get_field_content_int( 0, "MAX_USES", dbHandle );
	new uses = cache_get_field_content_int( 0, "USES", dbHandle );

	if ( uses >= max_uses )
		return SendError( playerid, "This cash card cannot be redeemed anymore as it had a limit of %d uses.", max_uses ), 1;

	new expire_time = cache_get_field_content_int( 0, "EXPIRE_TIME", dbHandle );

	if ( expire_time != 0 && GetServerTime( ) > expire_time )
		return SendError( playerid, "This cash card cannot be redeemed anymore as it has expired." ), 1;

	new card_id = cache_get_field_content_int( 0, "ID", dbHandle );
	new card_value = cache_get_field_content_int( 0, "VALUE", dbHandle );

	mysql_format( dbHandle, szBigString, sizeof( szBigString ), "SELECT * FROM `CASH_CARDS_REDEEMED` WHERE `USER_ID`=%d AND `CASH_CARD_ID`=%d", GetPlayerAccountID( playerid ), card_id );
	mysql_function_query( dbHandle, szBigString, true, "OnPlayerRedeemCashCard", "ddd", playerid, card_id, card_value );
	return 1;
}

thread OnPlayerRedeemCashCard( playerid, card_id, card_value )
{
	new
		rows;

	cache_get_data( rows, tmpVariable );

	if ( rows )
		return SendError( playerid, "You have already redeemed this cash card before." );

	// alert and give cash
	GivePlayerCash( playerid, card_value );
	SendClientMessageToAllFormatted( COLOR_GREY, "[SERVER]"COL_WHITE" %s(%d) has redeemed a "COL_GOLD"%s"COL_WHITE" cash card.", ReturnPlayerName( playerid ), playerid, cash_format( card_value ) );

	// insert into database
	mysql_single_query( sprintf( "UPDATE `CASH_CARDS` SET `USES` = `USES` + 1 WHERE `ID`=%d", card_id ) );
	mysql_single_query( sprintf( "INSERT INTO `CASH_CARDS_REDEEMED`(`USER_ID`,`CASH_CARD_ID`) VALUES (%d,%d)", GetPlayerAccountID( playerid ), card_id ) );
	return 1;
}

/* ** Migrations ** */
/*
DROP TABLE `CASH_CARDS`;
DROP TABLE `CASH_CARDS_REDEEMED`;
CREATE TABLE IF NOT EXISTS `CASH_CARDS` (
	`ID` int(11) primary key auto_increment,
	`USER_ID` int(11) unsigned default 1,
	`CODE` varchar(32) not null,
	`VALUE` int(11) not null,
	`MAX_USES` int(11),
	`USES` int(11) default 0,
	`EXPIRE_TIME` int(11) default 0
);

CREATE TABLE IF NOT EXISTS `CASH_CARDS_REDEEMED` (
	`ID` int(11) primary key auto_increment,
	`USER_ID` int(11),
	`CASH_CARD_ID` int(11),
	`REDEEMED_DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
*/
