/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\stocks\stocks.pwn
 * Purpose: stock market system for players
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_STOCKS					( 16 )

#define STOCK_REPORTING_PERIOD 		( 86400 ) // 1 day

#define STOCK_REPORTING_PERIODS 	( 30 ) // last 30 periods (days)

#define DIALOG_STOCK_MARKET 		8923
#define DIALOG_PLAYER_STOCKS 		8924
#define DIALOG_STOCK_MARKET_BUY 	8925
#define DIALOG_STOCK_MARKET_SELL 	8926
#define DIALOG_STOCK_MARKET_OPTIONS 8927
#define DIALOG_STOCK_MARKET_HOLDERS 8928

#define STOCK_MM_USER_ID			( 0 )

/* ** Constants ** */
static const Float: STOCK_MARKET_TRADING_FEE = 0.01;		// trading fee (buy/sell) percentage as decimal

static const Float: STOCK_DEFAULT_START_POOL = 0.0; 		// the default amount that the pool is set to upon a new report
static const Float: STOCK_DEFAULT_START_PRICE = 0.0; 		// the default starting price for a new report (useless for now)

/* ** Variables ** */
enum E_STOCK_MARKET_DATA
{
	E_NAME[ 64 ],				E_SYMBOL[ 4 ],			Float: E_MAX_SHARES,
	Float: E_POOL_FACTOR,		Float: E_PRICE_FACTOR,

	// market maker
	Float: E_IPO_SHARES,		Float: E_IPO_PRICE,		Float: E_MAX_PRICE
};

enum E_STOCK_MARKET_PRICE_DATA
{
	E_SQL_ID,					Float: E_PRICE, 		Float: E_POOL
};

enum
{
	E_STOCK_MINING_COMPANY,
	E_STOCK_AMMUNATION,
	E_STOCK_VEHICLE_DEALERSHIP,
	E_STOCK_SUPA_SAVE,
	E_STOCK_TRUCKING_COMPANY,
	E_STOCK_CLUCKIN_BELL,
	E_STOCK_PAWN_STORE,
	E_STOCK_CASINO,
	E_STOCK_GOVERNMENT
};

static stock
	g_stockMarketData 				[ MAX_STOCKS ] [ E_STOCK_MARKET_DATA ],
	g_stockMarketReportData 		[ MAX_STOCKS ] [ STOCK_REPORTING_PERIODS ] [ E_STOCK_MARKET_PRICE_DATA ],
	Iterator: stockmarkets 			< MAX_STOCKS >,

	Float: p_PlayerShares 			[ MAX_PLAYERS ] [ MAX_STOCKS ]
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// server variables
	AddServerVariable( "stock_report_time", "0", GLOBAL_VARTYPE_INT );
	AddServerVariable( "stock_trading_fees", "0.0", GLOBAL_VARTYPE_FLOAT );

	// 					ID 							NAME 					SYMBOL 	MAX SHARES 	IPO_PRICE 	MAX_PRICE 	POOL_FACTOR 	PRICE_FACTOR
	CreateStockMarket( E_STOCK_MINING_COMPANY,		"The Mining Company", 	"MC", 	100000.0, 	25.0, 		500.0, 		100000.0,		5.0 );
	CreateStockMarket( E_STOCK_AMMUNATION, 			"Ammu-Nation", 			"A", 	100000.0, 	25.0, 		250.0, 		100000.0,		5.0 );
	CreateStockMarket( E_STOCK_VEHICLE_DEALERSHIP, 	"Vehicle Dealership", 	"VD", 	100000.0, 	100.0,		250.0, 		100000.0,		5.0 );
	CreateStockMarket( E_STOCK_SUPA_SAVE, 			"Supa-Save", 			"SS", 	100000.0, 	25.0, 		250.0, 		100000.0,		5.0 );
	CreateStockMarket( E_STOCK_TRUCKING_COMPANY, 	"The Trucking Company", "TC", 	100000.0, 	50.0, 		250.0, 		100000.0,		5.0 );
	CreateStockMarket( E_STOCK_CLUCKIN_BELL,		"Cluckin' Bell", 		"CB", 	100000.0, 	50.0, 		250.0, 		100000.0,		5.0 );
	CreateStockMarket( E_STOCK_PAWN_STORE, 			"Pawn Store", 			"PS", 	100000.0, 	50.0, 		250.0, 		100000.0,		5.0 );
	CreateStockMarket( E_STOCK_CASINO, 				"Casino", 				"CAS", 	100000.0, 	990.0, 		5000.0,		100000.0,		20.0 );
	CreateStockMarket( E_STOCK_GOVERNMENT, 			"Government", 			"GOV", 	100000.0, 	750.0, 		5000.0,		100000.0,		20.0 );
	return 1;
}

hook OnServerUpdate( )
{
	new current_time = GetServerTime( );
	new last_reporting = GetServerVariableInt( "stock_report_time" );

	// check if its reporting time
	if ( current_time > last_reporting )
	{
		// reporting period
		UpdateServerVariableInt( "stock_report_time", current_time + STOCK_REPORTING_PERIOD );

		// create a new reporting period for every stock there
		foreach ( new s : stockmarkets )
		{
			StockMarket_ReleaseDividends( s );
		}

		print( "Successfully created new reporting period for all online companies" );
	}
	return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	for ( new i = 0; i < sizeof( p_PlayerShares[ ] ); i ++ ) {
		p_PlayerShares[ playerid ] [ i ] = 0.0;
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_STOCK_MARKET && response )
	{
		new
			x = 0;

		foreach ( new s : stockmarkets )
		{
			if ( x == listitem )
			{
				ShowPlayerStockMarketOptions( playerid, s );
				SetPVarInt( playerid, "stockmarket_selection", s );
				break;
			}
			x ++;
		}
		return 1;
	}
	else if ( dialogid == DIALOG_STOCK_MARKET_HOLDERS && response )
	{
		new
			stockid = GetPVarInt( playerid, "stockmarket_selection" );

		if ( ! Iter_Contains( stockmarkets, stockid ) ) {
			return SendError( playerid, "There was an error with the stock you were seeing, please try again." );
		}
		return ShowPlayerStockMarketOptions( playerid, stockid );
	}
	else if ( dialogid == DIALOG_STOCK_MARKET_OPTIONS )
	{
		if ( ! response ) {
			return ShowPlayerStockMarket( playerid );
		}

		new
			stockid = GetPVarInt( playerid, "stockmarket_selection" );

		if ( ! Iter_Contains( stockmarkets, stockid ) ) {
			return SendError( playerid, "There was an error with the stock you were seeing, please try again." );
		}

		switch ( listitem )
		{
			case 0: StockMarket_ShowBuySlip( playerid, stockid );
			case 1: mysql_tquery( dbHandle, sprintf( "SELECT s.*, u.`NAME`, u.`ONLINE` FROM `STOCK_OWNERS` s LEFT JOIN `USERS` u ON s.`USER_ID` = u.`ID` WHERE s.`STOCK_ID`=%d ORDER BY s.`SHARES` DESC", stockid ), "StockMarket_ShowShareholders", "dd", playerid, stockid );
		}
		return 1;
	}
	else if ( dialogid == DIALOG_PLAYER_STOCKS && response )
	{
		new
			x = 0;

		foreach ( new stockid : stockmarkets ) if ( p_PlayerShares[ playerid ] [ stockid ] )
		{
			if ( x == listitem )
			{
				SetPVarInt( playerid, "stockmarket_selling_stock", stockid );
				StockMarket_ShowSellSlip( playerid, stockid );
				break;
			}
			x ++;
		}
		return 1;
	}
	else if ( dialogid == DIALOG_STOCK_MARKET_SELL )
	{
		if ( ! response ) {
			return ShowPlayerStockMarket( playerid );
		}

		new
			stockid = GetPVarInt( playerid, "stockmarket_selling_stock" );

		if ( ! Iter_Contains( stockmarkets, stockid ) ) {
			return SendError( playerid, "There was an error processing your sell order, please try again." );
		}

		new
			input_shares;

		if ( sscanf( inputtext, "d", input_shares ) ) SendError( playerid, "You must use a valid value." );
		else if ( input_shares > floatround( p_PlayerShares[ playerid ] [ stockid ], floatround_floor ) ) SendError( playerid, "You do not have this many shares available to sell." );
		else if ( input_shares < 1 ) SendError( playerid, "The minimum number of shares you can sell is 1." );
		else
		{
			new
				Float: shares = float( input_shares );

			if ( ( p_PlayerShares[ playerid ] [ stockid ] -= shares ) < 0.1 ) {
				mysql_single_query( sprintf( "DELETE FROM `STOCK_OWNERS` WHERE `USER_ID`=%d AND `STOCK_ID`=%d", GetPlayerAccountID( playerid ), stockid ) );
			} else {
				StockMarket_GiveShares( stockid, GetPlayerAccountID( playerid ), -shares );
			}
			StockMarket_UpdateSellOrder( stockid, GetPlayerAccountID( playerid ), shares );
			SendServerMessage( playerid, "You have placed a sell order for %s shares at %s each. "COL_ORANGE"To cancel your sell order, /shares cancel", number_format( shares, .decimals = 2 ), cash_format( g_stockMarketReportData[ stockid ] [ 1 ] [ E_PRICE ], .decimals = 2 ) );
			return 1;
		}
		return StockMarket_ShowSellSlip( playerid, stockid );
	}
	else if ( dialogid == DIALOG_STOCK_MARKET_BUY )
	{
		new
			stockid = GetPVarInt( playerid, "stockmarket_selection" );

		if ( response )
		{
			new
				shares;

			if ( sscanf( inputtext, "d", shares ) ) SendError( playerid, "You must use a valid value." );
			else if ( shares < 1 ) SendError( playerid, "The minimum number of shares you can buy is 1." );
			else
			{
				mysql_tquery( dbHandle, sprintf( "SELECT * FROM `STOCK_SELL_ORDERS` WHERE `STOCK_ID`=%d ORDER BY `LIST_DATE` ASC", stockid ), "StockMarket_OnPurchaseOrder", "ddf", playerid, stockid, float( shares ) );
				return 1;
			}
			return StockMarket_ShowBuySlip( playerid, stockid );
		}
		else
		{
			return ShowPlayerStockMarket( playerid );
		}
	}
	return 1;
}

/* ** SQL Thread ** */
thread Stock_UpdateReportingPeriods( stockid )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		for ( new row = 0; row < rows; row ++ )
		{
			g_stockMarketReportData[ stockid ] [ row ] [ E_SQL_ID ] = cache_get_field_content_int( row, "ID" );
			g_stockMarketReportData[ stockid ] [ row ] [ E_POOL ] = cache_get_field_content_float( row, "POOL" );
			g_stockMarketReportData[ stockid ] [ row ] [ E_PRICE ] = cache_get_field_content_float( row, "PRICE" );
		}
	}
	else // no historical reporting data, restock the market maker
	{
		// set current stock market prices to IPO
		g_stockMarketReportData[ stockid ] [ 1 ] [ E_PRICE ] = g_stockMarketData[ stockid ] [ E_IPO_PRICE ];

		// create 2 reports for the company using the IPO price ... this way the price is not $0
		for ( new i = 0; i < 3; i ++ ) {
			StockMarket_ReleaseDividends( stockid );
		}

		// put market maker shares on the market
		StockMarket_UpdateSellOrder( stockid, STOCK_MM_USER_ID, g_stockMarketData[ stockid ] [ E_IPO_SHARES ] );
	}
	return 1;
}

thread StockMarket_InsertReport( stockid, Float: default_start_pool, Float: default_start_price )
{
	// set the new price of the company [TODO: use parabola for factor difficulty?]
	new Float: price_floor = g_stockMarketData[ stockid ] [ E_IPO_PRICE ] / 2.0;
	new Float: new_price = ( g_stockMarketReportData[ stockid ] [ 0 ] [ E_POOL ] / g_stockMarketData[ stockid ] [ E_POOL_FACTOR ] ) * g_stockMarketData[ stockid ] [ E_PRICE_FACTOR ] + price_floor;

	if ( new_price > g_stockMarketData[ stockid ] [ E_MAX_PRICE ] ) { // dont want wild market caps
		new_price = g_stockMarketData[ stockid ] [ E_MAX_PRICE ];
	}
	else if ( new_price < g_stockMarketData[ stockid ] [ E_IPO_PRICE ] ) { // force a minimum of IPO price
		new_price = g_stockMarketData[ stockid ] [ E_IPO_PRICE ];
	}

	g_stockMarketReportData[ stockid ] [ 0 ] [ E_PRICE ] = new_price;
	mysql_single_query( sprintf( "UPDATE `STOCK_REPORTS` SET `PRICE` = %f WHERE `ID` = %d", g_stockMarketReportData[ stockid ] [ 0 ] [ E_PRICE ], g_stockMarketReportData[ stockid ] [ 0 ] [ E_SQL_ID ] ) );

	// store temporary stock info
	new temp_stock_price_data[ MAX_STOCKS ] [ STOCK_REPORTING_PERIODS ] [ E_STOCK_MARKET_PRICE_DATA ];
	temp_stock_price_data = g_stockMarketReportData;

	// shift all report data by one
	for ( new r = 0; r < sizeof( g_stockMarketReportData[ ] ) - 2; r ++ ) {
		g_stockMarketReportData[ stockid ] [ r + 1 ] [ E_SQL_ID ] = temp_stock_price_data[ stockid ] [ r ] [ E_SQL_ID ];
		g_stockMarketReportData[ stockid ] [ r + 1 ] [ E_POOL ] = temp_stock_price_data[ stockid ] [ r ] [ E_POOL ];
		g_stockMarketReportData[ stockid ] [ r + 1 ] [ E_PRICE ] = temp_stock_price_data[ stockid ] [ r ] [ E_PRICE ];
	}

	// reset earnings
	g_stockMarketReportData[ stockid ] [ 0 ] [ E_SQL_ID ] = cache_insert_id( );
	g_stockMarketReportData[ stockid ] [ 0 ] [ E_POOL ] = default_start_pool;
	g_stockMarketReportData[ stockid ] [ 0 ] [ E_PRICE ] = default_start_price;
	return 1;
}

thread StockMarket_OnPurchaseOrder( playerid, stockid, Float: shares )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "This stock has no available shares for sale." );
	}

	// check if quantity is valid
	new
		Float: available_quantity = 0.0;

	for ( new r = 0; r < rows; r ++ ) {
		available_quantity += cache_get_field_content_float( r, "SHARES" );
	}

	if ( shares > available_quantity ) {
		return SendError( playerid, "There are not that many shares available for sale." ), StockMarket_ShowBuySlip( playerid, stockid ), 1;
	}

	// check if the player has the money for the purchase
	new Float: ask_price = g_stockMarketReportData[ stockid ] [ 1 ] [ E_PRICE ];
	new purchase_cost = floatround( ask_price * shares );

	new Float: purchase_fee = ask_price * shares * STOCK_MARKET_TRADING_FEE;

	UpdateServerVariableFloat( "stock_trading_fees", GetServerVariableFloat( "stock_trading_fees" ) + ( purchase_fee / 1000.0 ) );

	new purchase_cost_plus_fee = purchase_cost + floatround( purchase_fee );

	if ( GetPlayerCash( playerid ) < purchase_cost_plus_fee ) {
		return SendError( playerid, "You need at least %s to purchase this many shares.", cash_format( purchase_cost_plus_fee ) ), StockMarket_ShowBuySlip( playerid, stockid ), 1;
	}

	new
		Float: amount_remaining = shares;

	for ( new row = 0; row < rows; row ++ )
	{
		new sell_order_user_id = cache_get_field_content_int( row, "USER_ID" );
		new Float: sell_order_shares = cache_get_field_content_float( row, "SHARES" );

		// check if seller is online
		new
			sellerid;

		foreach ( sellerid : Player ) if ( GetPlayerAccountID( sellerid ) == sell_order_user_id ) {
			break;
		}

		new Float: sold_shares = amount_remaining > sell_order_shares ? sell_order_shares : amount_remaining;

		StockMarket_CreateTradeLog( stockid, GetPlayerAccountID( playerid ), sell_order_user_id, sold_shares, ask_price );

		new Float: sold_amount_fee = sold_shares * ask_price * STOCK_MARKET_TRADING_FEE;

		UpdateServerVariableFloat( "stock_trading_fees", GetServerVariableFloat( "stock_trading_fees" ) + ( sold_amount_fee / 1000.0 ) );

		new sold_amount_minus_fee = floatround( sold_shares * ask_price - sold_amount_fee );

		if ( 0 <= sellerid < MAX_PLAYERS && Iter_Contains( Player, sellerid ) && IsPlayerLoggedIn( sellerid ) ) {
			GivePlayerBankMoney( sellerid, sold_amount_minus_fee ), Beep( sellerid );
			SendServerMessage( sellerid, "You have sold %s %s shares to %s(%d) for "COL_GOLD"%s"COL_WHITE" (plus %0.1f%s fee)!", number_format( sold_shares, .decimals = 2 ), g_stockMarketData[ stockid ] [ E_NAME ], ReturnPlayerName( playerid ), playerid, cash_format( sold_amount_minus_fee ), STOCK_MARKET_TRADING_FEE * 100.0, "%%" );
		} else {
			mysql_single_query( sprintf( "UPDATE `USERS` SET `BANKMONEY` = `BANKMONEY` + %d WHERE `ID` = %d", sold_amount_minus_fee, sell_order_user_id ) );
		}

		// remove the sell order if there is little to no shares available
		if ( sell_order_shares - amount_remaining < 1.0 )
		{
			// get rid of this sell order
			mysql_single_query( sprintf( "DELETE FROM `STOCK_SELL_ORDERS` WHERE `USER_ID`=%d and `STOCK_ID`=%d", sell_order_user_id, stockid ) );

			// deduct the sell order amount from amount remaining
			amount_remaining -= sell_order_shares;
		}
		else
		{
			// reduce sell order quantity
			StockMarket_UpdateSellOrder( stockid, sell_order_user_id, -amount_remaining );

			// the player's buy order was filled in the single sell order ... prevent updating
			break;
		}
	}

	// increment the players shares
	StockMarket_GiveShares( stockid, GetPlayerAccountID( playerid ), shares );

	// reduce player balance and alert
	GivePlayerCash( playerid, -purchase_cost_plus_fee );
	SendServerMessage( playerid, "You have purchased %s shares of %s (@ %s/ea) for %s. (inc. %0.1f%s fee)", number_format( shares, .decimals = 2 ), g_stockMarketData[ stockid ] [ E_NAME ], cash_format( ask_price, .decimals = 2 ), cash_format( purchase_cost_plus_fee ), STOCK_MARKET_TRADING_FEE * 100.0, "%%" );
	return 1;
}

thread StockMarket_OnShowBuySlip( playerid, stockid )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "This stock does not currently have any shares available to buy." );
	}

	new
		Float: available_quantity = cache_get_field_content_float( 0, "SALE_SHARES" );

	format(
		szBigString, sizeof ( szBigString ),
		""COL_WHITE"You can buy shares of %s for "COL_GREEN"%s"COL_WHITE" each.\n\nThere are %s available shares to buy.",
		g_stockMarketData[ stockid ] [ E_NAME ],
		cash_format( g_stockMarketReportData[ stockid ] [ 1 ] [ E_PRICE ], .decimals = 2 ),
		number_format( available_quantity, .decimals = 2 )
	);
	ShowPlayerDialog( playerid, DIALOG_STOCK_MARKET_BUY, DIALOG_STYLE_INPUT, ""COL_WHITE"Stock Market", szBigString, "Buy", "Close" );
	return 1;
}

thread StockMarket_OnShowShares( playerid )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "You are not holding any shares of any company." );
	}

	szLargeString = ""COL_WHITE"Stock\t"COL_WHITE"Total Shares\t"COL_WHITE"Current Price ($)\t"COL_GREEN"Value ($)\n";

	for ( new row = 0; row < rows; row ++ )
	{
		new
			stockid = cache_get_field_content_int( row, "STOCK_ID" );

		if ( Iter_Contains( stockmarkets, stockid ) )
		{
			new Float: current_price = g_stockMarketReportData[ stockid ] [ 1 ] [ E_PRICE ];
			new Float: shares = cache_get_field_content_float( row, "SHARES" );

			format(
				szLargeString, sizeof( szLargeString ),
				"%s%s (%s)\t%s (%0.2f%%)\t%s\t"COL_GREEN"%s\n",
				szLargeString,
				g_stockMarketData[ stockid ] [ E_NAME ],
				g_stockMarketData[ stockid ] [ E_SYMBOL ],
				number_format( shares, .decimals = 2 ),
				( shares / g_stockMarketData[ stockid ] [ E_MAX_SHARES ] ) * 100.0,
				cash_format( current_price, .decimals = 2 ),
				cash_format( floatround( shares * current_price ) )
			);

			// store player stocks in a variable for reference
			p_PlayerShares[ playerid ] [ stockid ] = shares;
		}
	}
	return ShowPlayerDialog( playerid, DIALOG_PLAYER_STOCKS, DIALOG_STYLE_TABLIST_HEADERS, ""COL_WHITE"Stock Market", szLargeString, "Sell", "Close" ), 1;
}

thread Stock_OnDividendPayout( stockid )
{
	new
		rows = cache_get_row_count( );

	// pay out existing shareholders
	if ( rows )
	{
		new
			Float: total_shares = g_stockMarketData[ stockid ] [ E_MAX_SHARES ];

		for ( new row = 0; row < rows; row ++ )
		{
			new account_id = cache_get_field_content_int( row, "USER_ID" );
			new Float: shares_owned = cache_get_field_content_float( row, "SHARES" );

			new Float: dividend_rate = shares_owned / total_shares;
			new dividend_payout = floatround( g_stockMarketReportData[ stockid ] [ 0 ] [ E_POOL ] * dividend_rate );

			new
				shareholder;

			foreach ( shareholder : Player ) if ( GetPlayerAccountID( shareholder ) == account_id ) {
				break;
			}

			if ( 0 <= shareholder < MAX_PLAYERS && Iter_Contains( Player, shareholder ) ) {
				GivePlayerBankMoney( shareholder, dividend_payout ), Beep( shareholder );
				SendServerMessage( shareholder, "You have been paid a "COL_GOLD"%s"COL_WHITE" dividend (%0.2f%s) for owning %s!", cash_format( dividend_payout ), dividend_rate * 100.0, "%%", g_stockMarketData[ stockid ] [ E_NAME ] );
			} else {
				mysql_single_query( sprintf( "UPDATE `USERS` SET `BANKMONEY` = `BANKMONEY` + %d WHERE `ID` = %d", dividend_payout, account_id ) );
			}
		}
	}

	// insert to database a new report
	mysql_format( dbHandle, szBigString, sizeof ( szBigString ), "INSERT INTO `STOCK_REPORTS` (`STOCK_ID`, `POOL`, `PRICE`) VALUES (%d, %f, %f)", stockid, STOCK_DEFAULT_START_POOL, STOCK_DEFAULT_START_PRICE );
	mysql_tquery( dbHandle, szBigString, "StockMarket_InsertReport", "dff", stockid, STOCK_DEFAULT_START_POOL, STOCK_DEFAULT_START_PRICE );
	return 1;
}

thread Stock_UpdateMaximumShares( stockid )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		g_stockMarketData[ stockid ] [ E_MAX_SHARES ] = cache_get_field_content_float( 0, "SHARES_OWNED" ) + cache_get_field_content_float( 0, "SHARES_HELD" );

		// rows shown but still showing as 0 maximum shares? set it to the ipo issued amount
		if ( ! g_stockMarketData[ stockid ] [ E_MAX_SHARES ] )
		{
			g_stockMarketData[ stockid ] [ E_MAX_SHARES ] = g_stockMarketData[ stockid ] [ E_IPO_SHARES ];
		}
	}
	else
	{
		g_stockMarketData[ stockid ] [ E_MAX_SHARES ] = g_stockMarketData[ stockid ] [ E_IPO_SHARES ];
	}
	return 1;
}

thread StockMarket_OnCancelOrder( playerid )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		new
			player_account = GetPlayerAccountID( playerid );

		for ( new row = 0; row < rows; row ++ )
		{
			new stockid = cache_get_field_content_int( row, "STOCK_ID" );
			new Float: shares = cache_get_field_content_float( row, "SHARES" );

			mysql_single_query( sprintf( "DELETE FROM `STOCK_SELL_ORDERS` WHERE `STOCK_ID`=%d AND `USER_ID`=%d", stockid, player_account ) );
			StockMarket_GiveShares( stockid, player_account, shares );

			SendServerMessage( playerid, "You have cancelled your order of to sell %s shares of %s.", number_format( shares, .decimals = 2 ), g_stockMarketData[ stockid ] [ E_NAME ] );
		}
		return 1;
	}
	else
	{
		return SendError( playerid, "You have no stock market sell orders to cancel." ), 1;
	}
}

thread StockMarket_ShowShareholders( playerid, stockid )
{
	new rows = cache_get_row_count( );

	// format dialog title
	szLargeString = ""COL_WHITE"User\t"COL_WHITE"Shares\t"COL_WHITE"Percentage (%)\n";

	// track the shares that are held by players
	new Float: out_standing_shares = g_stockMarketData[ stockid ] [ E_MAX_SHARES ];

	// show all the shareholders
	if ( rows )
	{
		new
			player_name[ 24 ];

		for ( new row = 0; row < rows; row ++ )
		{
			cache_get_field_content( row, "NAME", player_name );

			new is_online = cache_get_field_content_int( row, "ONLINE" );
			new Float: shares = cache_get_field_content_float( row, "SHARES" );

			out_standing_shares -= shares;
			format( szLargeString, sizeof ( szLargeString ), "%s%s%s\t%s\t%s%%\n", szLargeString, is_online ? COL_GREEN : COL_WHITE, player_name, number_format( shares, .decimals = 0 ), number_format( shares / g_stockMarketData[ stockid ] [ E_MAX_SHARES ] * 100.0, .decimals = 3 ) );
		}
	}

	// tell players the shares tied up in sell orders
	if ( out_standing_shares > 0.0 ) {
		format( szLargeString, sizeof ( szLargeString ), "%s{666666}Held In Sell Orders\t{666666}%s\t{666666}%s%%\n", szLargeString, number_format( out_standing_shares, .decimals = 0 ), number_format( out_standing_shares / g_stockMarketData[ stockid ] [ E_MAX_SHARES ] * 100.0, .decimals = 3 ) );
	}

	// format dialog
	ShowPlayerDialog( playerid, DIALOG_STOCK_MARKET_HOLDERS, DIALOG_STYLE_TABLIST_HEADERS, ""COL_WHITE"Stock Market - Shareholders", szLargeString, "Back", "Close" );
	return 1;
}

/* ** Command ** */
CMD:stocks( playerid, params[ ] ) return cmd_stockmarkets( playerid, params );
CMD:stockmarkets( playerid, params[ ] )
{
	SendServerMessage( playerid, "The stock market will payout dividends in %s.", secondstotime( GetServerVariableInt( "stock_report_time" ) - GetServerTime( ) ) );
	return ShowPlayerStockMarket( playerid );
}

CMD:shares( playerid, params[ ] )
{
	if ( strmatch( params, "cancel" ) ) {
		// todo: work with dialogs
		mysql_tquery( dbHandle, sprintf( "SELECT * FROM `STOCK_SELL_ORDERS` WHERE `USER_ID` = %d", GetPlayerAccountID( playerid ) ), "StockMarket_OnCancelOrder", "d", playerid );
		return 1;
	}
	mysql_tquery( dbHandle, sprintf( "SELECT * FROM `STOCK_OWNERS` WHERE `USER_ID` = %d", GetPlayerAccountID( playerid ) ), "StockMarket_OnShowShares", "d", playerid );
	return 1;
}

/* ** Functions ** */
static stock CreateStockMarket( stockid, const name[ 64 ], const symbol[ 4 ], Float: ipo_shares, Float: ipo_price, Float: max_price, Float: pool_factor, Float: price_factor )
{
	if ( ! Iter_Contains( stockmarkets, stockid ) )
	{
		strcpy( g_stockMarketData[ stockid ] [ E_NAME ], name );
		strcpy( g_stockMarketData[ stockid ] [ E_SYMBOL ], symbol );

		g_stockMarketData[ stockid ] [ E_IPO_SHARES ] = ipo_shares;
		g_stockMarketData[ stockid ] [ E_IPO_PRICE ] = ipo_price;
		g_stockMarketData[ stockid ] [ E_MAX_PRICE ] = max_price;
		g_stockMarketData[ stockid ] [ E_POOL_FACTOR ] = pool_factor;
		g_stockMarketData[ stockid ] [ E_PRICE_FACTOR ] = price_factor;

		// reset stock price information
		for ( new r = 0; r < sizeof( g_stockMarketReportData[ ] ); r ++ ) {
			g_stockMarketReportData[ stockid ] [ r ] [ E_POOL ] = 0.0;
			g_stockMarketReportData[ stockid ] [ r ] [ E_PRICE ] = 0.0;
		}

		// load price information if there is
		print( sprintf( "SELECT * FROM `STOCK_REPORTS` WHERE `STOCK_ID`=%d ORDER BY `REPORTING_TIME` DESC LIMIT %d", stockid, sizeof( g_stockMarketReportData[ ] ) ));
 		mysql_tquery( dbHandle, sprintf( "SELECT * FROM `STOCK_REPORTS` WHERE `STOCK_ID`=%d ORDER BY `REPORTING_TIME` DESC, `ID` DESC LIMIT %d", stockid, sizeof( g_stockMarketReportData[ ] ) ), "Stock_UpdateReportingPeriods", "d", stockid );

 		// load the maximum number of shares
		mysql_tquery( dbHandle, sprintf( "SELECT (SELECT SUM(`SHARES`) FROM `STOCK_OWNERS` WHERE `STOCK_ID`=%d) AS `SHARES_OWNED`, (SELECT SUM(`SHARES`) FROM `STOCK_SELL_ORDERS` WHERE `STOCK_ID`=%d) AS `SHARES_HELD`", stockid, stockid ), "Stock_UpdateMaximumShares", "d", stockid );

 		// add to iterator
		Iter_Add( stockmarkets, stockid );
	}
	return stockid;
}

static stock StockMarket_ReleaseDividends( stockid )
{
	mysql_format( dbHandle, szBigString, sizeof ( szBigString ), "SELECT * FROM `STOCK_OWNERS` WHERE `STOCK_ID`=%d", stockid );
	mysql_tquery( dbHandle, szBigString, "Stock_OnDividendPayout", "d", stockid );
	return 1;
}

stock StockMarket_UpdateEarnings( stockid, amount, Float: factor = 1.0 )
{
	if ( ! Iter_Contains( stockmarkets, stockid ) )
		return 0;

	// ensure that pool remains always above 0 dollars
	if ( ( g_stockMarketReportData[ stockid ] [ 0 ] [ E_POOL ] += float( amount ) * factor ) < 0.0 ) {
		g_stockMarketReportData[ stockid ] [ 0 ] [ E_POOL ] = 0.0;
	}

	// save to database
	mysql_single_query( sprintf( "UPDATE `STOCK_REPORTS` SET `POOL`=%f WHERE `ID` = %d", g_stockMarketReportData[ stockid ] [ 0 ] [ E_POOL ], g_stockMarketReportData[ stockid ] [ 0 ] [ E_SQL_ID ] ) );
	return 1;
}

static stock StockMarket_GiveShares( stockid, accountid, Float: shares )
{
	mysql_format(
		dbHandle, szBigString, sizeof ( szBigString ),
		"INSERT INTO `STOCK_OWNERS` (`USER_ID`, `STOCK_ID`, `SHARES`) VALUES (%d, %d, %f) ON DUPLICATE KEY UPDATE `SHARES` = `SHARES` + %f",
		accountid, stockid, shares, shares
	);
	mysql_single_query( szBigString );
}

static stock StockMarket_UpdateSellOrder( stockid, accountid, Float: shares )
{
	mysql_format(
		dbHandle, szBigString, sizeof ( szBigString ),
		"INSERT INTO `STOCK_SELL_ORDERS` (`STOCK_ID`, `USER_ID`, `SHARES`) VALUES (%d, %d, %f) ON DUPLICATE KEY UPDATE `SHARES` = `SHARES` + %f",
		stockid, accountid, shares, shares
	);
	mysql_single_query( szBigString );
}

static stock StockMarket_CreateTradeLog( stockid, buyer_acc, seller_acc, Float: shares, Float: price )
{
	mysql_format(
		dbHandle, szBigString, sizeof ( szBigString ),
		"INSERT INTO `STOCK_TRADE_LOG` (`STOCK_ID`, `BUYER_ID`, `SELLER_ID`, `SHARES`, `PRICE`) VALUES (%d, %d, %d, %f, %f)",
		stockid, buyer_acc, seller_acc, shares, price
	);
	mysql_single_query( szBigString );
}

static stock StockMarket_ShowBuySlip( playerid, stockid )
{
	mysql_tquery( dbHandle, sprintf( "SELECT SUM(`SHARES`) AS `SALE_SHARES` FROM `STOCK_SELL_ORDERS` WHERE `STOCK_ID`=%d", stockid ), "StockMarket_OnShowBuySlip", "dd", playerid, stockid );
	return 1;
}

static stock StockMarket_ShowSellSlip( playerid, stockid )
{
	format(
		szLargeString, sizeof ( szLargeString ),
		""COL_WHITE"You can sell shares of %s for "COL_GREEN"%s"COL_WHITE" each.\n\nThough, you will have to wait until a person buys them.\n\nYou have %s available shares to sell.",
		g_stockMarketData[ stockid ] [ E_NAME ],
		cash_format( g_stockMarketReportData[ stockid ] [ 1 ] [ E_PRICE ], .decimals = 2 ),
		number_format( p_PlayerShares[ playerid ] [ stockid ], .decimals = 2 )
	);
	ShowPlayerDialog( playerid, DIALOG_STOCK_MARKET_SELL, DIALOG_STYLE_INPUT, ""COL_WHITE"Stock Market", szLargeString, "Sell", "Close" );
	return 1;
}

static stock ShowPlayerStockMarket( playerid )
{
	szLargeString = ""COL_WHITE"Stock\t"COL_WHITE"Max Shares\t"COL_WHITE"Dividend Per Share ($)\t"COL_WHITE"Price ($)\n";

	foreach ( new s : stockmarkets )
	{
		new Float: price_change = ( ( g_stockMarketReportData[ s ] [ 1 ] [ E_PRICE ] / g_stockMarketReportData[ s ] [ 2 ] [ E_PRICE ] ) - 1.0 ) * 100.0;
		new Float: payout = g_stockMarketReportData[ s ] [ 0 ] [ E_POOL ] / g_stockMarketData[ s ] [ E_MAX_SHARES ];

		format(
			szLargeString, sizeof( szLargeString ),
			"%s%s (%s)\t%s\t"COL_GREEN"%s\t%s%s (%s%%)\n",
			szLargeString,
			g_stockMarketData[ s ] [ E_NAME ],
			g_stockMarketData[ s ] [ E_SYMBOL ],
			number_format( g_stockMarketData[ s ] [ E_MAX_SHARES ], .decimals = 0 ),
			cash_format( payout, .decimals = 2 ),
			price_change >= 0.0 ? COL_GREEN : COL_RED,
			cash_format( g_stockMarketReportData[ s ] [ 1 ] [ E_PRICE ], .decimals = 2 ),
			number_format( price_change, .decimals = 2, .prefix = ( price_change >= 0.0 ? '+' : '\0' ) )
		);
	}
	return ShowPlayerDialog( playerid, DIALOG_STOCK_MARKET, DIALOG_STYLE_TABLIST_HEADERS, ""COL_WHITE"Stock Market", szLargeString, "Buy", "Close" );
}

static stock ShowPlayerStockMarketOptions( playerid, stockid )
{
	format( szBigString, sizeof( szBigString ), "Buy shares\t"COL_GREEN"%s\nView shareholders\t"COL_GREY">>>", cash_format( g_stockMarketReportData[ stockid ] [ 1 ] [ E_PRICE ], .decimals = 2 ) );
	ShowPlayerDialog( playerid, DIALOG_STOCK_MARKET_OPTIONS, DIALOG_STYLE_TABLIST, sprintf( ""COL_WHITE"Stock Market - %s", g_stockMarketData[ stockid ] [ E_NAME ] ), szBigString, "Select", "Back" );
	return 1;
}

/*
	DROP TABLE `STOCK_REPORTS`;
	CREATE TABLE IF NOT EXISTS `STOCK_REPORTS` (
		`ID` int(11) primary key auto_increment,
		`STOCK_ID` int(11),
		`POOL` float,
		`PRICE` float,
		`REPORTING_TIME` TIMESTAMP default CURRENT_TIMESTAMP
	);

	DROP TABLE `STOCK_OWNERS`;
	CREATE TABLE IF NOT EXISTS `STOCK_OWNERS` (
		`USER_ID` int(11),
		`STOCK_ID` int(11),
		`SHARES` float,
		PRIMARY KEY (USER_ID, STOCK_ID)
	);

	DROP TABLE `STOCK_SELL_ORDERS`;
	CREATE TABLE IF NOT EXISTS `STOCK_SELL_ORDERS` (
		`STOCK_ID` int(11),
		`USER_ID` int(11),
		`SHARES` float,
		`LIST_DATE` TIMESTAMP default CURRENT_TIMESTAMP,
		PRIMARY KEY (STOCK_ID, USER_ID)
	);

	DROP TABLE `STOCK_TRADE_LOG`;
	CREATE TABLE IF NOT EXISTS `STOCK_TRADE_LOG` (
		`ID` int(11) primary key auto_increment,
		`STOCK_ID` int(11),
		`BUYER_ID` int(11),
		`SELLER_ID` int(11),
		`SHARES` float,
		`PRICE` float,
		`DATE` TIMESTAMP default CURRENT_TIMESTAMP
	);
 */
