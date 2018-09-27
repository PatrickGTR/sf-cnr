/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define DIALOG_IC_SELLORDERS		( 5921 )
#define DIALOG_IC_BUY				( 5922 )

/* ** Variables ** */
static const
	p_PlayerMarket_SellOrders 		[ MAX_PLAYERS ] [ 50 ];


/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_IC_SELLORDERS && response )
	{
		for ( new i = 0, x = 0; i < sizeof ( p_PlayerMarket_SellOrders ); i ++ ) if ( p_PlayerMarket_SellOrders[ playerid ] [ i ] != -1 )
		{
			if ( x == listitem )
			{
				PlayerMarket_ShowSellOrder( playerid, p_PlayerMarket_SellOrders[ playerid ] [ i ] );
				break;
			}
			x ++;
		}
	}
	else if ( dialogid == DIALOG_IC_BUY )
	{
		if ( ! response ) {
			return ShowPlayerCoinSellOrders( playerid );
		}

		new sellorderid = GetPVarInt( playerid, "playermarket_sellorder" );
		new Float: purchase_amount;

		if ( sscanf( inputtext, "f", purchase_amount ) )
		{
			SendError( playerid, "Please specify a valid amount." );
			return PlayerMarket_ShowSellOrder( playerid, sellorderid );
		}
		else
		{
			mysql_tquery( dbHandle, sprintf( "SELECT * FROM `IC_SELL_ORDERS` WHERE `ID` = %d", sellorderid ), "PlayerMarket_OnPurchaseOrder", "ddf", playerid, sellorderid, purchase_amount );
			return 1;
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:sellcoins( playerid, params[ ] )
{
	new
		Float: quantity, price;

	if ( sscanf( params, "df", price, quantity ) ) return SendUsage( playerid, "/sellcoins [PRICE_PER_COIN] [COINS]" );
	else if ( quantity < 10.0 ) return SendError( playerid, "The minimum amount you can sell is 10.0 Irresistible Coins." );
	else if ( quantity > GetPlayerIrresistibleCoins( playerid ) ) return SendError( playerid, "You do not have this many Irresistible Coins." );
	else if ( ! ( 1000 <= price <= 125000 )) return SendError( playerid, "Selling price must be between $1,000 and $125,000 per coin." );
	else
	{
		// insert into database
		mysql_format( dbHandle, szBigString, sizeof( szBigString ), "INSERT INTO IC_SELL_ORDERS (USER_ID, ASK_PRICE, AVAILABLE_IC, TOTAL_IC) VALUES (%d, %d, %f, %f)", GetPlayerAccountID( playerid ), price, quantity, quantity );
		mysql_single_query( szBigString );

		// deduct the coins
		SendServerMessage( playerid, "Sell order for %s Irresistible Coins (at %s/IC) has been placed. Cancel via /ic cancel.", number_format( quantity, .decimals = 2 ), cash_format( price ) );
		GivePlayerIrresistibleCoins( playerid, -quantity );
	}
	return 1;
}

CMD:buycoins( playerid, params[ ] )
{
	ShowPlayerCoinSellOrders( playerid );
	return 1;
}

/* ** SQL Threads ** */
thread PlayerMarket_OnShowSellOrders( playerid )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		static
			seller[ 24 ];

		// set headers
		szHugeString = ""COL_GREY"Player\t"COL_GREY"Quantity Available\t"COL_GREY"Price Per Coin\n";

		for ( new row = 0; row < sizeof ( p_PlayerMarket_SellOrders[ ] ); row ++ )
		{
			if ( row < rows )
			{
				// store all the listing ids to the player
				p_PlayerMarket_SellOrders[ playerid ] [ row ] = cache_get_field_content_int( row, "ID" );

				cache_get_field_content( row, "NAME", seller );

				new Float: quantity = cache_get_field_content_float( row, "AVAILABLE_IC" );
				new ask_price = cache_get_field_content_int( row, "ASK_PRICE" );

				format( szHugeString, sizeof( szHugeString ), "%s%s\t%s\t"COL_GREEN"%s\n", szHugeString, seller, number_format( quantity, .decimals = 2 ), cash_format( ask_price ) );
			}
			else
			{
				p_PlayerMarket_SellOrders[ playerid ] [ row ] = -1;
			}
		}
		return ShowPlayerDialog( playerid, DIALOG_IC_SELLORDERS, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Irresistible Coin - "COL_WHITE"Buy Coins", szHugeString, "Buy", "Close" );
	}
	else
	{
		return SendError( playerid, "There are no available coin sell orders at current." );
	}
}

thread PlayerMarket_OnShowSellOrder( playerid, sellorderid )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "This sell order no longer exists. Please try again." );
	}

	new Float: quantity = cache_get_field_content_float( 0, "AVAILABLE_IC" );
	new ask_price = cache_get_field_content_int( 0, "ASK_PRICE" );

	SetPVarInt( playerid, "playermarket_sellorder", sellorderid );

	format( szBigString, sizeof( szBigString ), "This player has %s Irresistible Coins to sell at %s per coin.\n\nHow many Irresistible Coins would you like to buy?", number_format( quantity, .decimals = 2 ), cash_format( ask_price ) );
	return ShowPlayerDialog( playerid, DIALOG_IC_BUY, DIALOG_STYLE_INPUT, ""COL_GOLD"Irresistible Coin - "COL_WHITE"Buy Coins", szBigString, "Buy", "Back" ), 1;
}

thread PlayerMarket_OnPurchaseOrder( playerid, sellorderid, Float: purchase_amount )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "This sell order no longer exists. Please try again." );
	}

	// check if the player has the money for the purchase
	new ask_price = cache_get_field_content_int( 0, "ASK_PRICE" );
	new purchase_cost = floatround( float( ask_price ) * purchase_amount );

	if ( GetPlayerCash( playerid ) < purchase_cost ) {
		return SendError( playerid, "You need at least %s to purchase this many coins.", cash_format( purchase_cost ) ), PlayerMarket_ShowSellOrder( playerid, sellorderid ), 1;
	}

	// check if quantity is valid
	new Float: available_quantity = cache_get_field_content_float( 0, "AVAILABLE_IC" );

	if ( purchase_amount > available_quantity ) {
		return SendError( playerid, "This player does not have that many coins for sale." ), PlayerMarket_ShowSellOrder( playerid, sellorderid ), 1;
	}

	// check if seller is the buyer
	new seller_account_id = cache_get_field_content_int( 0, "USER_ID" );

	// delete the sell order if theres little remaining else reduce
	if ( available_quantity - purchase_amount < 0.5 ) {
		mysql_single_query( sprintf( "DELETE FROM IC_SELL_ORDERS WHERE ID = %d", sellorderid ) );
	} else {
		mysql_single_query( sprintf( "UPDATE IC_SELL_ORDERS SET AVAILABLE_IC = AVAILABLE_IC - %f WHERE ID = %d", purchase_amount, sellorderid ) );
	}

	// check if the seller is online
	new
		sellerid;

	foreach ( sellerid : Player ) if ( GetPlayerAccountID( sellerid ) == seller_account_id ) {
		break;
	}

	if ( 0 <= sellerid < MAX_PLAYERS && Iter_Contains( Player, sellerid ) ) {
		GivePlayerCash( playerid, purchase_cost ), Beep( playerid );
		SendServerMessage( sellerid, "You have successfully %s IC to %s(%d) for "COL_GOLD"%s"COL_WHITE"!", number_format( purchase_amount, .decimals = 2 ), ReturnPlayerName( playerid ), playerid, cash_format( purchase_cost ) );
	} else {
		mysql_single_query( sprintf( "UPDATE `USERS` SET `CASH` = `CASH` + %d WHERE `ID` = %d", purchase_cost, seller_account_id ) );
	}

	// log the purchase
	mysql_format( dbHandle, szBigString, sizeof( szBigString ), "INSERT INTO IC_MARKET_LOG (SELLER_ID, BUYER_ID, ASK_RATE, IC_AMOUNT) VALUES (%d, %d, %d, %f)", seller_account_id, GetPlayerAccountID( playerid ), ask_price, purchase_amount );
	mysql_single_query( szBigString );

	// credit the buyer
	GivePlayerCash( playerid, -purchase_cost );
	GivePlayerIrresistibleCoins( playerid, purchase_amount );
	SendServerMessage( playerid, "You have successfully purchased %s IC (rate %s each) for %s.", number_format( purchase_amount, .decimals = 2 ), cash_format( ask_price ), cash_format( purchase_cost ) );
	return 1;
}

/* ** Functions ** */
stock ShowPlayerCoinSellOrders( playerid ) {
	mysql_tquery( dbHandle, "SELECT IC_SELL_ORDERS.*,USERS.NAME FROM IC_SELL_ORDERS INNER JOIN USERS ON USERS.ID = IC_SELL_ORDERS.USER_ID ORDER BY ASK_PRICE ASC", "PlayerMarket_OnShowSellOrders", "d", playerid );
	return 1;
}

static stock PlayerMarket_ShowSellOrder( playerid, sellorderid ) {
	mysql_tquery( dbHandle, sprintf( "SELECT * FROM `IC_SELL_ORDERS` WHERE `ID` = %d", sellorderid ), "PlayerMarket_OnShowSellOrder", "dd", playerid, sellorderid );
	return 1;
}

/* ** Migrations ** */
/*
	CREATE TABLE IF NOT EXISTS IC_SELL_ORDERS (
		`ID` int(11) AUTO_INCREMENT PRIMARY KEY,
		`USER_ID` int(11),
		`ASK_PRICE` int(11),
		`AVAILABLE_IC` float,
		`TOTAL_IC` float,
		`LISTING_DATE` TIMESTAMP default CURRENT_TIMESTAMP
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
