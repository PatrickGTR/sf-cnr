/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\home\realestate.pwn
 * Purpose: home listings for player homes
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
// #define DIALOG_HOUSE_LISTINGS		5838
// #define DIALOG_HOUSE_LIST_VIEW		5839

/* ** Macros ** */
#define ShowPlayerHomeListing(%0,%1) \
	mysql_tquery( dbHandle, sprintf( "SELECT * FROM `HOUSE_LISTINGS` WHERE `ID` = %d", %1 ), "HouseListing_OnShowHome", "dd", %0, %1 )

/* ** Constants ** */
static const
	HOUSE_LISTING_FEE 				= 75000;

/* ** Variables ** */
static stock
	p_CurrentListings 				[ MAX_PLAYERS ] [ 20 ];

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_HOUSE_LISTINGS && response )
	{
		new curr_page = GetPVarInt( playerid, "houselisting_page" );
		new curr_page_items = GetPVarInt( playerid, "houselisting_rows" );

		// pressed previous
		if ( listitem >= curr_page_items + 1 )
		{
			return ShowPlayerHomeListings( playerid, curr_page - 1 );
		}

		// pressed previous (on last page) / next page
		else if ( listitem == curr_page_items )
		{
			// pressed first item, but theres not even 20 items?
			if ( curr_page_items < sizeof ( p_CurrentListings[ ] ) ) {
				return ShowPlayerHomeListings( playerid, curr_page - 1 );
			} else {
				return ShowPlayerHomeListings( playerid, curr_page + 1 );
			}
		}

		else
		{
			for ( new i = 0, x = 0; i < sizeof ( p_CurrentListings[ ] ); i ++ ) if ( p_CurrentListings[ playerid ] [ i ] != -1 )
			{
				if ( x == listitem )
				{
					ShowPlayerHomeListing( playerid, p_CurrentListings[ playerid ] [ i ] );
					break;
				}
				x ++;
			}
		}
		return 1;
	}
	else if ( dialogid == DIALOG_HOUSE_LIST_VIEW )
	{
		if ( ! response )
			return ShowPlayerHomeListings( playerid, GetPVarInt( playerid, "houselisting_page" ) );

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
					SendClientMessageFormatted( playerid, -1, ""COL_GREY"[GPS]"COL_WHITE" You have set your destination to %s"COL_WHITE". Follow the arrow to reach your destination.", g_houseData[ houseid ] [ E_HOUSE_NAME ] );
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

hook OnHouseOwnerChange( houseid, owner )
{
	mysql_single_query( sprintf( "DELETE FROM `HOUSE_LISTINGS` WHERE `HOUSE_ID` = %d AND `SALE_DATE` IS NULL", houseid ) );
	return 1;
}

/* ** Commands ** */
CMD:realestate( playerid, params[ ] ) return cmd_estate( playerid, params );
CMD:estate( playerid, params[ ] )
{
	new
		houseid = p_InHouse[ playerid ];

	if ( strmatch( params, "list cancel" ) )
	{
		if ( ! Iter_Contains( houses, houseid ) ) return SendError( playerid, "You are not inside of any home." );
		else if ( ! IsPlayerHomeOwner( playerid, houseid ) ) return SendError( playerid, "You are not the owner of this home." );
		{
			mysql_tquery( dbHandle, sprintf( "DELETE FROM `HOUSE_LISTINGS` WHERE `HOUSE_ID` = %d AND `SALE_DATE` IS NULL", houseid ), "HouseListing_OnDeleteListing", "dd", playerid, houseid );
		}
		return 1;
	}
	else if ( !strcmp( params, "list", false, 4 ) )
	{
		new
			Float: coins;

		if ( sscanf( params[ 5 ], "f", coins ) ) return SendUsage( playerid, "/estate list [IC_ASK_PRICE/CANCEL]");
		else if ( ! Iter_Contains( houses, houseid ) ) return SendError( playerid, "You are not inside of any home." );
		else if ( g_houseData[ houseid ] [ E_COST ] > 2500 ) return SendError( playerid, "This home is not a V.I.P home." );
		else if ( ! IsPlayerHomeOwner( playerid, houseid ) ) return SendError( playerid, "You are not the owner of this home." );
		else if ( coins < 25.0 ) return SendError( playerid, "Please specify an ask price greater than 25.00 IC." );
		else if ( coins > 25000.0 ) return SendError( playerid, "Please specify an ask price less than 25,000 IC." );
		else if ( GetPlayerCash( playerid ) < HOUSE_LISTING_FEE && GetPlayerVIPLevel( playerid ) < VIP_PLATINUM ) return SendError( playerid, "You need at least %s to create a house listing.", cash_format( HOUSE_LISTING_FEE ) );
		else
		{
			mysql_tquery( dbHandle, sprintf( "SELECT * FROM `HOUSE_LISTINGS` WHERE `HOUSE_ID` = %d AND `SALE_DATE` IS NULL", houseid ), "HouseListing_OnCreateListing", "ddf", playerid, houseid, coins );
		}
		return 1;
	}
	else
	{
		SendServerMessage( playerid, "You can list your own home using "COL_GREY"/estate list"COL_WHITE" for %s.", p_VIPLevel[ playerid ] < VIP_PLATINUM ? ( cash_format( HOUSE_LISTING_FEE ) ) : ( "FREE" ) );
		return ShowPlayerHomeListings( playerid );
	}
}

/* ** SQL Threads ** */
thread HouseListing_OnShowHomes( playerid, page )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		static
			location[ MAX_ZONE_NAME ],
			city[ 3 ],
			house_name[ 32 ],
			owner[ 24 ];

		// set headers
		szHugeString = ""COL_GREY"House\t"COL_GREY"Owner\t"COL_GREY"Location\t"COL_GREY"Ask Price (IC)\n";

		for ( new row = 0; row < sizeof ( p_CurrentListings[ ] ); row ++ )
		{
			if ( row < rows )
			{
				// store all the listing ids to the player
				p_CurrentListings[ playerid ] [ row ] = cache_get_field_content_int( row, "ID" );

				cache_get_field_content( row, "NAME", house_name );
				cache_get_field_content( row, "OWNER", owner );

				new houseid = cache_get_field_content_int( row, "HOUSE_ID" );

			    Get2DCityShort( city, g_houseData[ houseid ] [ E_EX ], g_houseData[ houseid ] [ E_EY ] );
			    GetZoneFromCoordinates( location, g_houseData[ houseid ] [ E_EX ], g_houseData[ houseid ] [ E_EY ], .placeholder = "Island" );

				new Float: coins = cache_get_field_content_float( row, "ASK" );

				format( szHugeString, sizeof( szHugeString ), "%s%s\t%s\t%s, %s\t"COL_GREEN"%s IC\n", szHugeString, house_name, owner, location, city, number_format( coins, .decimals = 2 ) );
			}
			else
			{
				p_CurrentListings[ playerid ] [ row ] = -1;
			}
		}

		if ( rows >= sizeof ( p_CurrentListings[ ] ) ) {
			strcat( szHugeString, ""COL_GREEN"Next Page\t"COL_GREEN">>>\t"COL_GREEN">>>\t"COL_GREEN">>>\t"COL_GREEN">>>\n" );
		}

		if ( page ) {
			strcat( szHugeString, ""COL_ORANGE"Previous Page\t"COL_ORANGE"<<<\t"COL_ORANGE"<<<\t"COL_ORANGE"<<<\t"COL_ORANGE"<<<\n" );
		}

		SetPVarInt( playerid, "houselisting_page", page );
		SetPVarInt( playerid, "houselisting_rows", rows );

		return ShowPlayerDialog( playerid, DIALOG_HOUSE_LISTINGS, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Irresistible Coin - "COL_WHITE"Premium Home Estate", szHugeString, "Select", "Close" );
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
			""COL_GOLD"Irresistible Coin - "COL_WHITE"Premium Home Estate",
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
			return SendError( playerid, "You do not have enough Irresistible Coins for this home (%s IC).", number_format( ask_price, .decimals = 2 ) );
		}

		// check if player is over the limit
		if ( p_OwnedHouses[ playerid ] >= GetPlayerHouseSlots( playerid ) ) {
			ShowPlayerHomeListing( playerid, house_listing_id );
			return SendError( playerid, "You cannot purchase any more houses, you've reached the limit." );
		}

		// check if sale already completed
		new
			sale_date_ts = cache_get_field_content_int( 0, "SALE_DATE_TS" );

		if ( sale_date_ts != 0 && GetServerTime( ) > sale_date_ts ) {
			return SendError( playerid, "You can no longer buy this home as it has been sold." );
		}

		// check if buyer is the player himself
		new
			owner_account_id = cache_get_field_content_int( 0, "USER_ID" );

		if ( GetPlayerAccountID( playerid ) == owner_account_id ) {
			ShowPlayerHomeListing( playerid, house_listing_id );
			return SendError( playerid, "You cannot buy your own home." );
		}

		// credit seller if they are on/offline
		new
			houseid = cache_get_field_content_int( 0, "HOUSE_ID" ),
			sellerid;

		foreach ( sellerid : Player ) if ( GetPlayerAccountID( sellerid ) == owner_account_id ) {
			break;
		}

		// validate seller id
		if ( 0 <= sellerid < MAX_PLAYERS && Iter_Contains( Player, sellerid ) ) {
			p_OwnedHouses[ sellerid ] --;
			GivePlayerIrresistibleCoins( sellerid, ask_price );
			SendServerMessage( sellerid, "You have successfully sold your home (%s) for "COL_GOLD"%s IC"COL_WHITE" to %s(%d)!", g_houseData[ houseid ] [ E_HOUSE_NAME ], number_format( ask_price, .decimals = 2 ), ReturnPlayerName( playerid ), playerid );
		} else {
			mysql_single_query( sprintf( "UPDATE `USERS` SET `COINS` = `COINS` + %f WHERE `ID` = %d", ask_price, owner_account_id ) );
		}

		// show sellers name & house name
		SendServerMessage( playerid, "You have successfully bought %s's home (%s"COL_WHITE") for "COL_GOLD"%s IC"COL_WHITE"!", g_houseData[ houseid ] [ E_OWNER ], g_houseData[ houseid ] [ E_HOUSE_NAME ], number_format( ask_price, .decimals = 2 ) );

		// set listing as sold and transfer home
		mysql_single_query( sprintf( "UPDATE `HOUSE_LISTINGS` SET `SALE_DATE` = CURRENT_TIMESTAMP WHERE `ID` = %d", house_listing_id ) );
		SetHouseOwner( houseid, GetPlayerAccountID( playerid ), ReturnPlayerName( playerid ) );
		GivePlayerIrresistibleCoins( playerid, -ask_price );
		p_OwnedHouses[ playerid ] ++;
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
		if ( GetPlayerVIPLevel( playerid ) < VIP_PLATINUM ) {
			GivePlayerCash( playerid, -HOUSE_LISTING_FEE );
		}

		// insert into database and notify
		mysql_single_query( sprintf( "INSERT INTO `HOUSE_LISTINGS` (`HOUSE_ID`, `USER_ID`, `ASK`) VALUES (%d, %d, %f)", houseid, GetPlayerAccountID( playerid ), ask_price ) );
		return SendServerMessage( playerid, "You have listed your home. You can retract your listing using "COL_GREY"/estate list cancel"COL_WHITE"." );
	}
	else
	{
		return SendError( playerid, "This home is already listed. You can retract your listing using "COL_GREY"/estate list cancel"COL_WHITE"." );
	}
}

thread HouseListing_OnDeleteListing( playerid, houseid )
{
	new
		deleted_rows = cache_affected_rows( );

	if ( deleted_rows )
	{
		return SendServerMessage( playerid, "You have delisted your home. You can create a new listing using "COL_GREY"/estate list"COL_WHITE"." );
	}
	else
	{
		return SendError( playerid, "This home is not listed on the premium realestate market." );
	}
}

/* ** Functions ** */
stock ShowPlayerHomeListings( playerid, page = 0 )
{
	// just incase we get some negative page from user ... reset
	if ( page < 0 ) {
		page = 0;
	}

	// format query, offset according to page
	format(
		szBigString, sizeof( szBigString ),
		"SELECT HL.ID, HL.HOUSE_ID, H.NAME, U.NAME AS OWNER, HL.ASK FROM HOUSE_LISTINGS HL " \
		"INNER JOIN HOUSES H ON H.ID = HL.HOUSE_ID " \
		"INNER JOIN USERS U ON U.ID = HL.USER_ID " \
		"WHERE SALE_DATE IS NULL LIMIT %d OFFSET %d",
		sizeof( p_CurrentListings[ ] ), page * sizeof( p_CurrentListings[ ] )
	);
	return mysql_tquery( dbHandle, szBigString, "HouseListing_OnShowHomes", "dd", playerid, page );
}

/* ** Migrations ** */
/*
	DROP TABLE HOUSE_LISTINGS;
	CREATE TABLE IF NOT EXISTS HOUSE_LISTINGS (
		ID int(11) AUTO_INCREMENT PRIMARY KEY,
		HOUSE_ID int(11),
		USER_ID int(11),
		ASK float,
		LISTING_DATE TIMESTAMP default CURRENT_TIMESTAMP,
		SALE_DATE TIMESTAMP nullable default null,
		FOREIGN KEY (HOUSE_ID) REFERENCES HOUSES (ID) ON DELETE CASCADE
	)
*/
