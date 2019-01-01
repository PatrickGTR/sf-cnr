/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\tax.pwn
 * Purpose: system for globally taxing player assets
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Hooks ** */
hook OnScriptInit( )
{
	AddServerVariable( "taxtime", "0", GLOBAL_VARTYPE_INT );
	AddServerVariable( "taxrate", "1.0", GLOBAL_VARTYPE_FLOAT );
	AddServerVariable( "taxprofit", "0.0", GLOBAL_VARTYPE_FLOAT );
	AddServerVariable( "taxprofit_prev", "0.0", GLOBAL_VARTYPE_FLOAT );
    return 1;
}

hook OnServerUpdate( )
{
    new
        server_time = GetServerTime( );

	// Time For Tax?
	if ( server_time >= GetGVarInt( "taxtime" ) ) {
		UpdateServerVariable( "taxtime", server_time + 86400, 0.0, "", GLOBAL_VARTYPE_INT );
		BeginEconomyTax( );
	}
    return 1;
}

/* ** Commands ** */
CMD:gettaxrate( playerid, params[ ] ) return cmd_tax( playerid, params );
CMD:getmytax( playerid, params[ ] ) return cmd_tax( playerid, params );
CMD:tax( playerid, params[ ] )
{
	new Float: tax_discount = p_VIPLevel[ playerid ] >= VIP_DIAMOND ? 0.5 : 1.0;
	new Float: tax_rate = GetGVarFloat( "taxrate" ) * tax_discount;
	new player_tax = floatround( float( GetPlayerTotalCash( playerid ) ) * ( tax_rate / 100.0 ) );
	if ( player_tax < 0 ) player_tax = 0;
	if ( tax_discount != 1.0 ) {
		SendServerMessage( playerid, "Your tax is "COL_GOLD"%s"COL_WHITE" at %0.2f%s in %s. "COL_GOLD"(50%s Reduced)", cash_format( player_tax ), tax_rate, "%%", secondstotime( GetGVarInt( "taxtime" ) - g_iTime ), "%%" );
	} else {
		SendServerMessage( playerid, "Your tax is "COL_GOLD"%s"COL_WHITE" at %0.2f%s in %s.", cash_format( player_tax ), tax_rate, "%%", secondstotime( GetGVarInt( "taxtime" ) - g_iTime ) );
	}
	return 1;
}

CMD:gettotalcash( playerid, params[ ] )
{
	mysql_function_query( dbHandle, "SELECT USER_CASH, BIZ_CASH, GANG_CASH FROM (SELECT (SUM(BANKMONEY)+SUM(CASH)) USER_CASH FROM USERS) A CROSS JOIN (SELECT SUM(BANK) BIZ_CASH FROM BUSINESSES) B CROSS JOIN (SELECT SUM(BANK) GANG_CASH FROM GANGS) C", true, "gettotalcash", "i", playerid );
	return 1;
}

/* ** SQL Threads ** */
thread OnTaxEconomy( starting )
{
	new
		rows = cache_get_row_count( );

    if ( ! rows ) {
        return 1;
    }

	new user_cash = cache_get_field_content_int( 0, "USER_CASH", dbHandle );
	new biz_cash = cache_get_field_content_int( 0, "BIZ_CASH", dbHandle );
	new gang_cash = cache_get_field_content_int( 0, "GANG_CASH", dbHandle );

	// total_thousands
	new Float: total_thousands = float( user_cash + biz_cash + gang_cash ) / 1000000.0;

	// step
	if ( starting == 1 )
	{
		new Float: tax_rate = GetGVarFloat( "taxrate" ) / 100.0; // 1%

		// players
		foreach ( new playerid : Player ) {
			new Float: tax_discount = p_VIPLevel[ playerid ] >= VIP_DIAMOND ? 0.5 : 1.0;
			new player_tax = floatround( float( GetPlayerTotalCash( playerid ) ) * tax_rate * tax_discount );

			if ( player_tax > 0 ) {
				ShowPlayerHelpDialog( playerid, 5000, sprintf( "~w~You have paid ~r~%s~w~ in tax", cash_format( player_tax ) ) );
				GivePlayerCash( playerid, -player_tax );
			}
		}

		// businesses
		foreach ( new businessid : business ) {
			new business_tax = floatround( float( g_businessData[ businessid ] [ E_BANK ] ) * tax_rate );
			if ( business_tax > 0 ) g_businessData[ businessid ] [ E_BANK ] -= business_tax;
		}

		// gangs
		foreach ( new gangid : gangs ) {
			new gang_tax = floatround( float( g_gangData[ gangid ] [ E_BANK ] ) * tax_rate );
			if ( gang_tax > 0 ) g_gangData[ gangid ] [ E_BANK ] -= gang_tax;
		}

		// queries
		mysql_single_query( sprintf( "UPDATE `USERS` SET `CASH`=`CASH`*IF(`VIP_PACKAGE`>=3,%f,%f),`BANKMONEY`=`BANKMONEY`*IF(`VIP_PACKAGE`>=5,%f,%f) WHERE `ONLINE`=0 AND (`BANKMONEY`+`CASH`)>0", 1.0 - tax_rate / 2.0, 1.0 - tax_rate, 1.0 - tax_rate / 2.0, 1.0 - tax_rate ) );
		mysql_single_query( sprintf( "UPDATE `BUSINESSES` SET `BANK`=`BANK`*%f WHERE `BANK`>0", 1.0 - tax_rate ) );
		mysql_single_query( sprintf( "UPDATE `GANGS` SET `BANK`=`BANK`*%f WHERE `BANK`>0", 1.0 - tax_rate ) );

		// set current economy money
		SetGVarFloat( "before_tax", total_thousands );
		printf("[SERVER ECONOMY TAX] $%0.3fM before tax.", total_thousands );
		BeginEconomyTax( .starting = 0 );
	}
	else
	{
		new Float: profit = GetGVarFloat( "before_tax" ) - total_thousands; // millions

		// eventbank donate
		new eventbank = floatround( profit * 100000.0 ); // 10%
		UpdateServerVariable( "eventbank", GetGVarInt( "eventbank" ) + eventbank, 0.0, "", GLOBAL_VARTYPE_INT );

		// hitman budget
		new hitman_budget = floatround( profit * 100000.0 ); // 10%
		RandomHits_IncreaseHitPool( hitman_budget );

		// add to server vars
		UpdateServerVariable( "taxprofit_prev", 0, GetGVarFloat( "taxprofit" ), "", GLOBAL_VARTYPE_FLOAT );
		UpdateServerVariable( "taxprofit", 0, GetGVarFloat( "taxprofit" ) + profit, "", GLOBAL_VARTYPE_FLOAT );
		printf( "[SERVER ECONOMY TAX] The server economy has been successfully taxed for a profit of $%0.3fM.", profit );
	}
	return 1;
}

thread gettotalcash( playerid )
{
	new
		rows;

    cache_get_data( rows, tmpVariable );
	if ( rows )
	{
		new tax_profit = floatround( ( GetGVarFloat( "taxprofit" ) - GetGVarFloat( "taxprofit_prev" ) ) * 1000000.0 );
		new user_cash = cache_get_field_content_int( 0, "USER_CASH", dbHandle );
		new biz_cash = cache_get_field_content_int( 0, "BIZ_CASH", dbHandle );
		new gang_cash = cache_get_field_content_int( 0, "GANG_CASH", dbHandle );
		new total_cash = user_cash + biz_cash + gang_cash;

		format( szLargeString, 512, "Total User Cash\t"COL_GREY"%s\nTotal Gang Cash\t"COL_GREY"%s\nTotal Business Cash\t"COL_GREY"%s\nTotal Server Cash\t"COL_GOLD"%s\nTotal Tax Profit (Day)\t"COL_GOLD"%s",
				cash_format( user_cash ), cash_format( gang_cash ), cash_format( biz_cash ), cash_format( total_cash ), cash_format( tax_profit ) );

		// SendServerMessage( playerid, "Total: "COL_GOLD"%s"COL_WHITE", Tax Rate: "COL_GOLD"%s"COL_WHITE" per 24 mins.", cash_format( total_cash ), cash_format( tax_rate ) );
  		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST, "{FFFFFF}SF-CNR Economy", szLargeString, "Close", "" );
	}
	else SendError( playerid, "An error has occurred, try again later." );
	return 1;
}

/* ** Functions ** */
stock BeginEconomyTax( starting = 1 ) {
	mysql_function_query( dbHandle, "SELECT USER_CASH, BIZ_CASH, GANG_CASH FROM (SELECT (SUM(BANKMONEY)+SUM(CASH)) USER_CASH FROM USERS) A CROSS JOIN (SELECT SUM(BANK) BIZ_CASH FROM BUSINESSES) B CROSS JOIN (SELECT SUM(BANK) GANG_CASH FROM GANGS) C", true, "OnTaxEconomy", "i", starting );
}