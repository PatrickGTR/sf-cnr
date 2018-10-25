/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnrs
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_STOCKS					( 32 )

#define STOCK_REPORTING_PERIOD 		( 500 ) // 1 day

#define STOCK_REPORTING_PERIODS 	( 30 ) // last 30 periods (days)

#define DIALOG_STOCK_MARKET 		8923

/* ** Variables ** */
enum E_STOCK_MARKET_DATA
{
	E_NAME[ 64 ],			E_SYMBOL[ 4 ],			E_MAX_SHARES,

	// market maker
	E_MM_SHARES,			E_MM_IPO_PRICE
};

enum E_STOCK_MARKET_PRICE_DATA
{
	E_SQL_ID,				Float: E_PRICE,
	Float: E_EARNINGS
};

static stock
	g_stockMarketData 				[ MAX_STOCKS ] [ E_STOCK_MARKET_DATA ],
	g_stockMarketPriceData 			[ MAX_STOCKS ] [ STOCK_REPORTING_PERIODS ] [ E_STOCK_MARKET_PRICE_DATA ],
	Iterator: stockmarkets 			< MAX_STOCKS >
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// server variables
	AddServerVariable( "stock_report_time", "0", GLOBAL_VARTYPE_INT );

	// create markets
	CreateStockMarket( 0, "The Mining Company", "MC", 50000000, 100 );
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
			StockMarket_CreateReport( s );
		}

		print( "Successfully created new reporting period for all online companies" );
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
			g_stockMarketPriceData[ stockid ] [ row ] [ E_SQL_ID ] = cache_get_field_content_int( row, "ID" );
			g_stockMarketPriceData[ stockid ] [ row ] [ E_PRICE ] = cache_get_field_content_float( row, "CURRENT_PRICE" );
			g_stockMarketPriceData[ stockid ] [ row ] [ E_EARNINGS ] = cache_get_field_content_float( row, "CURRENT_EARNINGS" );
		}
	}
	return 1;
}

thread StockMarket_InsertReport( stockid )
{
	g_stockMarketPriceData[ stockid ] [ 0 ] [ E_SQL_ID ] = cache_insert_id( );
	return 1;
}

/* ** Command ** */
CMD:increase( playerid, params[ ] ) {
	StockMarket_UpdateEarnings( 0, strval( params ) );
	return 1;
}

CMD:newreport( playerid, params[ ] ) {
	StockMarket_CreateReport( 0 );
	return 1;
}

CMD:stockmarkets( playerid, params[ ] )
{
	szLargeString = ""COL_WHITE"Stock\t"COL_WHITE"Current Price\t"COL_WHITE"Market Capitalization\t"COL_WHITE"Price Change (24H)\n";

	foreach ( new s : stockmarkets )
	{
		printf("%f %f\n", g_stockMarketPriceData[ s ] [ 0 ] [ E_EARNINGS ], g_stockMarketPriceData[ s ] [ 1 ] [ E_EARNINGS ]);
		new Float: price_difference = ( g_stockMarketPriceData[ s ] [ 1 ] [ E_EARNINGS ] / g_stockMarketPriceData[ s ] [ 2 ] [ E_EARNINGS ] - 1.0 ) * 100.0;
		new Float: current_price = g_stockMarketPriceData[ s ] [ 1 ] [ E_PRICE ];

		format(
			szLargeString, sizeof( szLargeString ),
			"%s%s (%s)\t"COL_GREEN"%s\t%s%s%%\n",
			szLargeString,
			g_stockMarketData[ s ] [ E_NAME ],
			g_stockMarketData[ s ] [ E_SYMBOL ],
			cash_format( current_price, .decimals = 0 ),
			price_difference >= 0.0 ? ( COL_GREEN ) : ( COL_RED ),
			number_format( price_difference, .decimals = 2 )
		);
	}

	SendServerMessage( playerid, "The stock market will close in %s.", secondstotime( GetServerVariableInt( "stock_report_time" ) - GetServerTime( ) ) );
	return ShowPlayerDialog( playerid, DIALOG_STOCK_MARKET, DIALOG_STYLE_TABLIST_HEADERS, ""COL_WHITE"Stock Market", szLargeString, "Select", "Close" );
}

/* ** Functions ** */
stock CreateStockMarket( stockid, const name[ 64 ], const symbol[ 4 ], max_shares, ipo_price )
{
	if ( ! Iter_Contains( stockmarkets, stockid ) )
	{
		strcpy( g_stockMarketData[ stockid ] [ E_NAME ], name );
		strcpy( g_stockMarketData[ stockid ] [ E_SYMBOL ], symbol );

		g_stockMarketData[ stockid ] [ E_MM_SHARES ] = max_shares;
		g_stockMarketData[ stockid ] [ E_MM_IPO_PRICE ] = ipo_price;

		// reset stock price information
		for ( new r = 0; r < sizeof( g_stockMarketPriceData[ ] ); r ++ ) {
			g_stockMarketPriceData[ stockid ] [ r ] [ E_PRICE ] = 0.0;
			g_stockMarketPriceData[ stockid ] [ r ] [ E_EARNINGS ] = 0.0;
		}

		// load price information if there is
 		mysql_tquery( dbHandle, sprintf( "SELECT * FROM `STOCK_REPORTS` WHERE `STOCK_ID`=%d ORDER BY `REPORTING_TIME` DESC LIMIT %d", stockid, sizeof( g_stockMarketPriceData[ ] ) ), "Stock_UpdateReportingPeriods", "d", stockid );

 		// add to iterator
		Iter_Add( stockmarkets, stockid );
	}
	return stockid;
}

stock StockMarket_CreateReport( stockid )
{
	// limit a 20% loss for players
	new Float: circuit_breaker = g_stockMarketPriceData[ stockid ] [ 1 ] [ E_EARNINGS ] * 0.8;

	if ( g_stockMarketPriceData[ stockid ] [ 0 ] [ E_EARNINGS ] < circuit_breaker ) {
		g_stockMarketPriceData[ stockid ] [ 0 ] [ E_EARNINGS ] = circuit_breaker;
	}

	// change stock price proportional to earnings increase/decrease
	new Float: price_difference = g_stockMarketPriceData[ stockid ] [ 0 ] [ E_EARNINGS ] / g_stockMarketPriceData[ stockid ] [ 1 ] [ E_EARNINGS ];
	printf("Earnings %f\n", price_difference );

	if ( ( g_stockMarketPriceData[ stockid ] [ 0 ] [ E_PRICE ] = g_stockMarketPriceData[ stockid ] [ 1 ] [ E_PRICE ] * price_difference ) < 1.0 ) {
		g_stockMarketPriceData[ stockid ] [ 0 ] [ E_PRICE ] = 1.0;
	}

	// store temporary stock info
	new temp_stock_price_data[ MAX_STOCKS ] [ STOCK_REPORTING_PERIODS ] [ E_STOCK_MARKET_PRICE_DATA ];
	temp_stock_price_data = g_stockMarketPriceData;

	// shift all earnings by one
	for ( new r = 0; r < sizeof( g_stockMarketPriceData[ ] ) - 2; r ++ ) {
		g_stockMarketPriceData[ stockid ] [ r + 1 ] [ E_PRICE ] = temp_stock_price_data[ stockid ] [ r ] [ E_PRICE ];
		g_stockMarketPriceData[ stockid ] [ r + 1 ] [ E_EARNINGS ] = temp_stock_price_data[ stockid ] [ r ] [ E_EARNINGS ];
	}

	// set current price to previous reporting period price
	g_stockMarketPriceData[ stockid ] [ 0 ] [ E_PRICE ] = g_stockMarketPriceData[ stockid ] [ 1 ] [ E_PRICE ];

	// reset earnings
	g_stockMarketPriceData[ stockid ] [ 0 ] [ E_EARNINGS ] = 0.0; // set to 0

	// insert to database the old information
	mysql_format(
		dbHandle, szBigString, sizeof ( szBigString ),
		"INSERT INTO `STOCK_REPORTS` (`STOCK_ID`, `CURRENT_PRICE`, `CURRENT_EARNINGS`) VALUES (%d, %f, %f)",
		stockid,
		g_stockMarketPriceData[ stockid ] [ 0 ] [ E_PRICE ],
		g_stockMarketPriceData[ stockid ] [ 0 ] [ E_EARNINGS ]
	);

	mysql_tquery( dbHandle, szBigString, "StockMarket_InsertReport", "d", stockid );
	return 1;
}

stock StockMarket_UpdateEarnings( stockid, amount )
{
	if ( ! Iter_Contains( stockmarkets, stockid ) )
		return 0;

	printf( "Current Earnings: %f, Prior Earnings: %f", g_stockMarketPriceData[ stockid ] [ 0 ] [ E_EARNINGS ], g_stockMarketPriceData[ stockid ] [ 1 ] [ E_EARNINGS ] );
	g_stockMarketPriceData[ stockid ] [ 0 ] [ E_EARNINGS ] += amount;
	mysql_single_query( sprintf( "UPDATE `STOCK_REPORTS` SET `CURRENT_EARNINGS` = `CURRENT_EARNINGS` + %d WHERE `ID` = %d", g_stockMarketPriceData[ stockid ] [ 0 ] [ E_EARNINGS ], g_stockMarketPriceData[ stockid ] [ 0 ] [ E_SQL_ID ] ) );
	return 1;
}

stock Float: StockMarket_GetEarnings( stockid ) {
	return g_stockMarketPriceData[ stockid ] [ 0 ] [ E_EARNINGS ];
}

stock Float: StockMarket_GetCurrentPrice( stockid ) {
	return g_stockMarketPriceData[ stockid ] [ 0 ] [ E_PRICE ];
}

stock StockMarket_MakeSellOrder( stockid, accountid, Float: shares, Float: price )
{
	//INSERT INTO `STOCK_ORDERS` (`USER_ID`, `STOCK_ID`, ``)
	return 1;
}

/*

	CREATE TABLE IF NOT EXISTS `STOCK_REPORTS` (
		`ID` int(11) primary key auto_increment,
		`STOCK_ID` int(11),
		`CURRENT_PRICE` float,
		`CURRENT_EARNINGS` float,
		`REPORTING_TIME` TIMESTAMP default CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS `STOCK_OWNERS` (
		`ID` int(11) primary key auto_increment,
		`USER_ID` int(11),
		`STOCK_ID` int(11),
		`SHARES` float,
		`PRICE` float
	);

	CREATE TABLE IF NOT EXISTS `STOCK_ORDERS` (
		`ID` int(11) primary key auto_increment,
		`USER_ID` int(11),
		`STOCK_ID` int(11),
		`SHARES` float,
		`PRICE` float,
	);
 */
