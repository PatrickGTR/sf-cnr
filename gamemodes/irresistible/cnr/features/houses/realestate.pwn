/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\home\realestate.pwn
 * Purpose: home listings for player homes
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define DIALOG_HOUSE_LISTINGS		5838
#define DIALOG_HOUSE_LIST_VIEW		5839

/* ** Macros ** */
#define ShowPlayerHomeListings(%0) \
	mysql_tquery( dbHandle, "SELECT HL.ID, HL.HOUSE_ID, H.NAME, U.NAME AS OWNER, HL.ASK FROM HOUSE_LISTINGS HL INNER JOIN HOUSES H ON H.ID = HL.HOUSE_ID INNER JOIN USERS U ON U.ID = HL.USER_ID WHERE SALE_DATE IS NULL", "HouseListing_OnShowHomes", "d", %0 )

#define ShowPlayerHomeListing(%0,%1) \
	mysql_tquery( dbHandle, sprintf( "SELECT * FROM `HOUSE_LISTINGS` WHERE `ID` = %d", %1 ), "HouseListing_OnShowHome", "dd", %0, %1 )

/* ** Constants ** */
static const
	HOUSE_LISTING_FEE 				= 50000;

/* ** Variables ** */
static stock
	p_CurrentListings 				[ MAX_PLAYERS ] [ 20 ];

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_HOUSE_LISTINGS && response )
	{
		for ( new i = 0, x = 0; i < sizeof ( p_CurrentListings ); i ++ ) if ( p_CurrentListings[ playerid ] [ i ] != -1 )
		{
			if ( x == listitem )
			{
				ShowPlayerHomeListing( playerid, p_CurrentListings[ playerid ] [ i ] );
				break;
			}
			x ++;
		}
	}
	else if ( dialogid == DIALOG_HOUSE_LIST_VIEW )
	{
		if ( ! response )
			return ShowPlayerHomeListings( playerid );

		new houseid = GetPVarInt( playerid, "house_listing_houseid" );
		new listingid = GetPVarInt( playerid, "house_listing_viewid" );

		switch ( listitem )
		{
			case 0: mysql_tquery( dbHandle, sprintf( "SELECT *, UNIX_TIMESTAMP(`SALE_DATE`) as `SALE_DATE_TS` FROM `HOUSE_LISTINGS` WHERE `ID` = %d", listingid ), "HouseListing_OnBuyHome", "dd", playerid, listingid );
			case 1:
			{
				if ( IsPlayerInAnyVehicle( playerid ) )
				{
					GPS_SetPlayerWaypoint( playerid, g_houseData[ houseid ] [ E_HOUSE_NAME ], g_houseData[ houseid ] [ E_EX ], g_houseData[ houseid ] [ E_EY ], g_houseData[ houseid ] [ E_EZ ] );
					SendClientMessageFormatted( playerid, -1, ""COL_GREY"[GPS]"COL_WHITE" You have set your destination to %s. Follow the arrow to reach your destination.", g_houseData[ houseid ] [ E_HOUSE_NAME ] );
				}
				else
				{
					ShowPlayerHomeListing( playerid, listingid );
					SendError( playerid, "You need to be in a vehicle to set a GPS waypoint." );
					return 1;
				}
			}
		}
	}
	return 1;
}

/* ** Commands ** */
hook cmd_h( playerid, params[ ] )
{
	new
		houseid = p_InHouse[ playerid ];

	if ( strmatch( params, "listings" ) ) {
		return ShowPlayerHomeListings( playerid ), Y_HOOKS_BREAK_RETURN_1;
	}
	if ( strmatch( params, "list cancel" ) )
	{
		if ( ! Iter_Contains( houses, houseid ) ) return SendError( playerid, "You are not inside of any home." );
		else if ( ! IsPlayerHomeOwner( playerid, houseid ) ) return SendError( playerid, "You are not the owner of this home." );
		{
			mysql_tquery( dbHandle, sprintf( "DELETE FROM `HOUSE_LISTINGS` WHERE `HOUSE_ID` = %d AND `SALE_DATE` IS NULL", houseid ), "HouseListing_OnDeleteListing", "dd", playerid, houseid );
		}
		return Y_HOOKS_BREAK_RETURN_1;
	}
	else if ( !strcmp( params, "list", false, 4 ) )
	{
		new
			Float: coins;

		if ( sscanf( params[ 5 ], "f", coins ) ) return SendUsage( playerid, "/h list [ASK_PRICE (IC)]");
		else if ( ! Iter_Contains( houses, houseid ) ) return SendError( playerid, "You are not inside of any home." );
		else if ( g_houseData[ houseid ] [ E_COST ] > 2500 ) return SendError( playerid, "This home is not a V.I.P home." );
		else if ( ! IsPlayerHomeOwner( playerid, houseid ) ) return SendError( playerid, "You are not the owner of this home." );
		else if ( coins < 25.0 ) return SendError( playerid, "Please specify an ask price greater than 25.00 IC." );
		else if ( coins > 25000.0 ) return SendError( playerid, "Please specify an ask price less than 25,000 IC." );
		else if ( GetPlayerCash( playerid ) < HOUSE_LISTING_FEE && GetPlayerVIPLevel( playerid ) != VIP_GOLD ) return SendError( playerid, "You need at least %s to create a house listing.", cash_format( HOUSE_LISTING_FEE ) );
		else
		{
			mysql_tquery( dbHandle, sprintf( "SELECT * FROM `HOUSE_LISTINGS` WHERE `HOUSE_ID` = %d AND `SALE_DATE` IS NULL", houseid ), "HouseListing_OnCreateListing", "ddf", playerid, houseid, coins );
		}
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

/* ** SQL Threads ** */
thread HouseListing_OnShowHomes( playerid )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		static
			location[ MAX_ZONE_NAME ],
			city[ MAX_ZONE_NAME ],
			house_name[ 32 ],
			owner[ 24 ];

		// set headers
		szLargeString = ""COL_GREY"House\t"COL_GREY"Owner\t"COL_GREY"Location\t"COL_GREY"Ask Price (IC)\n";

		for ( new row = 0; row < sizeof ( p_CurrentListings[ ] ); row ++ )
		{
			if ( row < rows )
			{
				// store all the listing ids to the player
				p_CurrentListings[ playerid ] [ row ] = cache_get_field_content_int( row, "ID" );

				cache_get_field_content( row, "NAME", house_name );
				cache_get_field_content( row, "OWNER", owner );

				new houseid = cache_get_field_content_int( row, "HOUSE_ID" );

			    Get2DCity( city, g_houseData[ houseid ] [ E_EX ], g_houseData[ houseid ] [ E_EX ] );
			    GetZoneFromCoordinates( location, g_houseData[ houseid ] [ E_EX ], g_houseData[ houseid ] [ E_EX ] );

				new Float: coins = cache_get_field_content_float( row, "ASK" );

				format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\t%s, %s\t"COL_GREEN"%s IC\n", szLargeString, house_name, owner, city, location, number_format( coins, .decimals = 2 ) );
			}
			else
			{
				p_CurrentListings[ playerid ] [ row ] = -1;
			}
		}
		return ShowPlayerDialog( playerid, DIALOG_HOUSE_LISTINGS, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}House Real Estate", szLargeString, "Select", "Back" );
	}
	else
	{
		return SendError( playerid, "There are no available homes for sale at current." );
	}
}

thread HouseListing_OnShowHome( playerid, house_listing_id )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		new house_id = cache_get_field_content_int( 0, "HOUSE_ID" );
		new Float: coins = cache_get_field_content_float( 0, "ASK" );

		SetPVarInt( playerid, "house_listing_viewid", house_listing_id );
		SetPVarInt( playerid, "house_listing_houseid", house_id );

		return ShowPlayerDialog(
			playerid, DIALOG_HOUSE_LIST_VIEW, DIALOG_STYLE_TABLIST,
			"{FFFFFF}House Real Estate",
			sprintf( "Purchase Home\t"COL_GREEN"%s IC\nSet GPS Waypoint\t"COL_GREY">>>", number_format( coins, .decimals = 2 ) ),
			"Select", "Back"
		);
	}
	else
	{
		return SendError( playerid, "An error has occurred, please try again." );
	}
}

thread HouseListing_OnBuyHome( playerid, house_listing_id )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		new
			Float: ask_price = cache_get_field_content_float( 0, "ASK" );

		// does the dude even have the coins
		if ( GetPlayerIrresistibleCoins( playerid ) < ask_price ) {
			ShowPlayerHomeListing( playerid, house_listing_id );
			return SendError( playerid, "You do not have enough Irresistible coins for this home (%s IC).", number_format( ask_price, .decimals = 2 ) );
		}

		// check if sale already completed
		new
			sale_date_ts = cache_get_field_content_int( 0, "SALE_DATE_TS" );

		if ( sale_date_ts != 0 && GetServerTime( ) > sale_date_ts ) {
			return SendError( playerid, "You can no longer buy this home as it has been sold." );
		}

		// credit seller if they are on/offline
		new
			owner_account_id = cache_get_field_content_int( 0, "USER_ID" ),
			sellerid;

		foreach ( sellerid : Player ) if ( GetPlayerAccountID( sellerid ) == owner_account_id ) {
			break;
		}

		// validate seller id
		if ( 0 <= sellerid < MAX_PLAYERS && Iter_Contains( Player, sellerid ) ) {
			p_OwnedHouses[ sellerid ] --;
			GivePlayerIrresistibleCoins( sellerid, ask_price );
			SendServerMessage( sellerid, "You have successfully sold your house for "COL_GOLD"%s IC"COL_WHITE" to %s(%d)!", number_format( ask_price, .decimals = 2 ), ReturnPlayerName( playerid ), playerid );
		} else {
			mysql_single_query( sprintf( "UPDATE `USERS` SET `COINS` = `COINS` + %0.2f WHERE `ID` = %d", ask_price, owner_account_id ) );
		}

		new
			houseid = cache_get_field_content_int( 0, "HOUSE_ID" );

		// show sellers name & house name
		SendServerMessage( playerid, "You have successfully bought %s's home (%s"COL_WHITE") for "COL_GOLD"%s IC"COL_WHITE"!", g_houseData[ houseid ] [ E_OWNER ], g_houseData[ houseid ] [ E_HOUSE_NAME ], number_format( ask_price, .decimals = 2 ) );

		// set listing as sold and transfer home
		mysql_single_query( sprintf( "UPDATE `HOUSE_LISTINGS` SET `SALE_DATE` = CURRENT_TIMESTAMP WHERE `ID` = %d", house_listing_id ) );
		SetHouseOwner( houseid, ReturnPlayerName( playerid ), .buyerid = playerid );
		GivePlayerIrresistibleCoins( playerid, -ask_price );
		return 1;
	}
	else
	{
		return SendError( playerid, "An error has occurred, please try again." );
	}
}

thread HouseListing_OnCreateListing( playerid, houseid, Float: ask_price )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows )
	{
		// debit user account
		if ( GetPlayerVIPLevel( playerid ) != VIP_GOLD ) {
			GivePlayerCash( playerid, -HOUSE_LISTING_FEE );
		}

		// insert into database and notify
		mysql_single_query( sprintf( "INSERT INTO `HOUSE_LISTINGS` (`HOUSE_ID`, `USER_ID`, `ASK`) VALUES (%d, %d, %f)", houseid, GetPlayerAccountID( playerid ), ask_price ) );
		return SendServerMessage( playerid, "You have listed your home. You can retract your listing using "COL_GREY"/h list cancel"COL_WHITE"." );
	}
	else
	{
		return SendError( playerid, "This home is already listed. You can retract your listing using "COL_GREY"/h list cancel"COL_WHITE"." );
	}
}

thread HouseListing_OnDeleteListing( playerid, houseid )
{
	new
		deleted_rows = cache_affected_rows( );

	if ( deleted_rows )
	{
		return SendServerMessage( playerid, "You have delisted your home. You can create a new listing using "COL_GREY"/h list"COL_WHITE"." );
	}
	else
	{
		return SendError( playerid, "This home is not listed on the premium realestate market." );
	}
}

/* ** Migrations ** */
/*
	DROP TABLE HOUSE_LISTINGS;
	CREATE TABLE IF NOT EXISTS HOUSE_LISTINGS (
		ID int(11) AUTO_INCREMENT PRIMARY KEY,
		HOUSE_ID int(11),
		USER_ID int(11),
		ASK float,
		LISTING_DATE DATETIME default CURRENT_TIMESTAMP,
		SALE_DATE DATETIME default null,
		FOREIGN KEY (HOUSE_ID) REFERENCES HOUSES (ID) ON DELETE CASCADE
	);
*/
