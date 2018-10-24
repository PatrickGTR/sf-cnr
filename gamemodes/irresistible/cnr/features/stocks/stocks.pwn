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

#define STOCK_REPORTING_PERIOD 		( 86400 ) // 1 day

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
	E_CURRENT_PRICE,
	E_CURRENT_EARNINGS,		E_PREVIOUS_EARNINGS
};

static stock
	g_stockMarketData 				[ MAX_STOCKS ] [ E_STOCK_MARKET_DATA ],
	g_stockMarketPriceData 			[ MAX_STOCKS ] [ STOCK_REPORTING_PERIODS ] [ E_STOCK_MARKET_PRICE_DATA ],
	Iterator: stockmarkets 			< MAX_STOCKS >
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	CreateStockMarket( 0, "The Mining Company", "MC", 10000000, 100 );
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
			g_stockMarketPriceData[ stockid ] [ row ] [ E_CURRENT_PRICE ] = cache_get_field_content_int( row, "CURRENT_PRICE" );
			g_stockMarketPriceData[ stockid ] [ row ] [ E_CURRENT_EARNINGS ] = cache_get_field_content_int( row, "CURRENT_EARNINGS" );
			g_stockMarketPriceData[ stockid ] [ row ] [ E_PREVIOUS_EARNINGS ] = cache_get_field_content_int( row, "PREVIOUS_EARNINGS" );
		}
	}
	return 1;
}

/* ** Command ** */
CMD:increase( playerid, params[ ] ) {
	g_stockMarketPriceData[ 0 ] [ 0 ] [ E_CURRENT_EARNINGS ] += strval( params );
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
		printf("%d %d\n", g_stockMarketPriceData[ s ] [ 0 ] [ E_CURRENT_EARNINGS ], g_stockMarketPriceData[ s ] [ 1 ] [ E_CURRENT_EARNINGS ]);
		new Float: price_difference = ( ( float( g_stockMarketPriceData[ s ] [ 0 ] [ E_CURRENT_EARNINGS ] ) / float( g_stockMarketPriceData[ s ] [ 1 ] [ E_CURRENT_EARNINGS ] ) ) - 1.0 ) * 100.0;
		new current_price = g_stockMarketPriceData[ s ] [ 0 ] [ E_CURRENT_PRICE ];

		// prevent integer overflow (over 2.6B)
		new Float: market_cap_millions = ( float( g_stockMarketData[ s ] [ E_MAX_SHARES ] ) / 1000000.0 ) * ( float( current_price ) / 1000000.0 );
		new Float: market_cap_billions = market_cap_millions / 1000.0;

		format(
			szLargeString, sizeof( szLargeString ),
			"%s%s (%s)\t"COL_GREEN"%s\t$%s%s\t%s%s%%\n",
			szLargeString,
			g_stockMarketData[ s ] [ E_NAME ],
			g_stockMarketData[ s ] [ E_SYMBOL ],
			cash_format( current_price ),
			market_cap_billions > 1.0 ? number_format( market_cap_billions, .decimals = 2 ) : number_format( market_cap_millions, .decimals = 2 ),
			market_cap_billions > 1.0 ? ( "B" ) : ( "M" ),
			price_difference >= 0.0 ? ( COL_GREEN ) : ( COL_RED ),
			number_format( price_difference, .decimals = 2 )
		);
	}

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
			g_stockMarketPriceData[ stockid ] [ r ] [ E_CURRENT_PRICE ] = 0;
			g_stockMarketPriceData[ stockid ] [ r ] [ E_CURRENT_EARNINGS ] = 0;
			g_stockMarketPriceData[ stockid ] [ r ] [ E_PREVIOUS_EARNINGS ] = 0;
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
	new old_earnings = g_stockMarketPriceData[ stockid ] [ 0 ] [ E_CURRENT_EARNINGS ];
	new old_price = g_stockMarketPriceData[ stockid ] [ 0 ] [ E_CURRENT_PRICE ];

	// store temporary stock info
	new temp_stock_price_data[ MAX_STOCKS ] [ STOCK_REPORTING_PERIODS ] [ E_STOCK_MARKET_PRICE_DATA ];
	temp_stock_price_data = g_stockMarketPriceData;

	// shift all earnings by one
	for ( new r = 0; r < sizeof( g_stockMarketPriceData[ ] ) - 2; r ++ ) {

		g_stockMarketPriceData[ stockid ] [ r + 1 ] [ E_CURRENT_PRICE ] = temp_stock_price_data[ stockid ] [ r ] [ E_CURRENT_PRICE ];
		g_stockMarketPriceData[ stockid ] [ r + 1 ] [ E_CURRENT_EARNINGS ] = temp_stock_price_data[ stockid ] [ r ] [ E_CURRENT_EARNINGS ];
		g_stockMarketPriceData[ stockid ] [ r + 1 ] [ E_PREVIOUS_EARNINGS ] = temp_stock_price_data[ stockid ] [ r ] [ E_PREVIOUS_EARNINGS ];
	}

	// price difference
	new Float: price_change = float( g_stockMarketPriceData[ stockid ] [ 0 ] [ E_CURRENT_EARNINGS ] ) / float( old_earnings );

	// circuit breaker ... max 20% loss
	if ( price_change < 0.8 ) {
		price_change = 0.8;
	}

	new new_price = floatround( float( old_price ) * price_change );

	// minimum stock price should be $10
	if ( new_price < 1 ) {
		new_price = 1;
	}

	// set information
	g_stockMarketPriceData[ stockid ] [ 0 ] [ E_CURRENT_PRICE ] = new_price;
	g_stockMarketPriceData[ stockid ] [ 0 ] [ E_CURRENT_EARNINGS ] = 0; // set to 0
	g_stockMarketPriceData[ stockid ] [ 0 ] [ E_PREVIOUS_EARNINGS ] = old_earnings;

	// insert to database


	//
	erase(szLargeString);
	// shift all earnings by one
	for ( new r = 0; r < sizeof( g_stockMarketPriceData[ ] ); r ++ ) {
		format( szLargeString, 1024, "%s{%d,%d,%d}, ", szLargeString, g_stockMarketPriceData[ stockid ] [ r ] [ E_CURRENT_PRICE ], g_stockMarketPriceData[ stockid ] [ r ] [ E_CURRENT_EARNINGS ], g_stockMarketPriceData[ stockid ] [ r ] [ E_PREVIOUS_EARNINGS ] );
	}

	printf("%s\n",szLargeString);
	return 1;
}

stock StockMarket_GetCurrentPrice( stockid ) {
	return g_stockMarketPriceData[ stockid ] [ 0 ] [ E_CURRENT_PRICE ];
}

/*

	CREATE TABLE IF NOT EXISTS `STOCK_REPORTS` (
		`STOCK_ID` int(11),
		`CURRENT_PRICE` int(11),
		`CURRENT_EARNINGS` int(11),
		`PREVIOUS_EARNINGS` int(11),
		`REPORTING_TIME` TIMESTAMP default CURRENT_TIMESTAMP
	);

 */
