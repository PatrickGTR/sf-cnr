/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\crowdfund.pwn
 * Purpose: off-ucp crowdfunding feature (all done in-game)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_CROWDFUNDS 				10 		// dont bother editing

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_CROWDFUNDS && response )
	{
		new crowdfund_ids_string[ MAX_CROWDFUNDS * 3 ];
		new crowdfunds_ids[ MAX_CROWDFUNDS ];

    	GetPVarString( playerid, "crowdfunds_shown", crowdfund_ids_string, sizeof( crowdfund_ids_string ) );

		if ( sscanf( crowdfund_ids_string, "a<i>[" # MAX_CROWDFUNDS "]", crowdfunds_ids ) ) {
			return SendError( playerid, "There was an error reading the crowdfunds, try again later." );
		}

		for ( new i = 0, x = 0; i < sizeof( crowdfunds_ids ); i ++ ) if ( crowdfunds_ids[ i ] != 0 )
		{
			if ( x == listitem )
			{
				SetPVarInt( playerid, "viewing_crowdfund", crowdfunds_ids[ i ] );
				break;
			}
			x ++;
		}
		return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_OPTIONS, DIALOG_STYLE_LIST, ""COL_GOLD"Feature Crowdfunding", "View Crowdfund Details\nView Crowdfund Patreons\n"COL_GOLD"Contribute To Crowdfund <3", "Select", "Close" );
	}
	else if ( dialogid == DIALOG_CROWDFUND_OPTIONS )
	{
		if ( ! response )
			return ShowPlayerCrowdfunds( playerid );

		new
			viewing_crowdfund = GetPVarInt( playerid, "viewing_crowdfund" );

		if ( ! viewing_crowdfund ) {
			return SendError( playerid, "There was an error. Please attempt to contribute to the crowdfund again." );
		}

		switch ( listitem )
		{
			case 0:
			{
				mysql_tquery(
					dbHandle,
					sprintf( "SELECT CROWDFUND_PACKAGES.*, CROWDFUNDS.DESCRIPTION AS CF_DESCRIPTION FROM CROWDFUND_PACKAGES INNER JOIN CROWDFUNDS ON CROWDFUNDS.ID = CROWDFUND_PACKAGES.CROWDFUND_ID WHERE CROWDFUND_ID = %d ORDER BY REQUIRED_AMOUNT DESC", viewing_crowdfund ),
					"OnDisplayCrowdfundInfo", "ii", playerid, viewing_crowdfund
				);
			}
			case 1:
			{
				mysql_tquery(
					dbHandle,
					sprintf( "SELECT USERS.NAME, SUM(AMOUNT) AS TOTAL FROM CROWDFUND_PATREONS INNER JOIN USERS ON USERS.ID = CROWDFUND_PATREONS.USER_ID WHERE CROWDFUND_PATREONS.CROWDFUND_ID = %d GROUP BY CROWDFUND_PATREONS.USER_ID ORDER BY TOTAL DESC", viewing_crowdfund ),
					"OnDisplayCrowdfundPatreons", "ii", playerid, viewing_crowdfund
				);
			}
			case 2:
			{
				return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_DONATE, DIALOG_STYLE_INPUT, ""COL_GOLD"Feature Crowdfunding", ""COL_WHITE"Please specify the amount of IC you wish to contribute:\n\n"COL_ORANGE"Warning: There is no confirmation dialog.", "Contribute", "Back" );
			}
		}
	}
	else if ( dialogid == DIALOG_CROWDFUND_INFO && ! response ) {
		return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_OPTIONS, DIALOG_STYLE_LIST, ""COL_GOLD"Feature Crowdfunding", "View Crowdfund Details\nView Crowdfund Patreons\n"COL_GOLD"Contribute To Crowdfund <3", "Select", "Close" );
	}
	else if ( dialogid == DIALOG_CROWDFUND_DONATE )
	{
		if ( ! response )
			return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_OPTIONS, DIALOG_STYLE_LIST, ""COL_GOLD"Feature Crowdfunding", "View Crowdfund Details\nView Crowdfund Patreons\n"COL_GOLD"Contribute To Crowdfund <3", "Select", "Close" );

		new
			viewing_crowdfund = GetPVarInt( playerid, "viewing_crowdfund" );

		if ( ! viewing_crowdfund ) {
			return SendError( playerid, "There was an error. Please attempt to contribute to the crowdfund again." );
		}

		new
			Float: amount;

		if ( sscanf( inputtext, "f", amount ) ) {
			return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_DONATE, DIALOG_STYLE_INPUT, ""COL_GOLD"Feature Crowdfunding", ""COL_WHITE"Please specify the amount of IC you wish to contribute:\n\n"COL_RED"Please specify a decimal number!", "Contribute", "Close" );
		} else if ( amount < 10.0 ) {
			return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_DONATE, DIALOG_STYLE_INPUT, ""COL_GOLD"Feature Crowdfunding", ""COL_WHITE"Please specify the amount of IC you wish to contribute:\n\n"COL_RED"The minimum amount you can contribute is 10.00 IC!", "Contribute", "Close" );
		} else if ( amount > GetPlayerIrresistibleCoins( playerid ) ) {
			return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_DONATE, DIALOG_STYLE_INPUT, ""COL_GOLD"Feature Crowdfunding", ""COL_WHITE"Please specify the amount of IC you wish to contribute:\n\n"COL_RED"You do not have this many coins in your account!", "Contribute", "Close" );
		} else {
			// check if expired/ended/valid before even submitting
			mysql_tquery( dbHandle, sprintf( "SELECT FEATURE, UNIX_TIMESTAMP(RELEASE_DATE) AS `RELEASE`, UNIX_TIMESTAMP(END_DATE) AS `END` FROM CROWDFUNDS WHERE ID = %d", viewing_crowdfund ), "OnPlayerCrowdfundContribute", "ddf", playerid, viewing_crowdfund, amount );
		}
		return 1;
	}
	return 1;
}

/* ** Commands ** */
CMD:crowdfund( playerid, params[ ] ) return cmd_crowdfunds( playerid, params );
CMD:crowdfunds( playerid, params[ ] ) return ShowPlayerCrowdfunds( playerid );

/* ** Functions ** */
stock ShowPlayerCrowdfunds( playerid ) {
	return mysql_tquery( dbHandle,
		"SELECT CROWDFUNDS.ID, CROWDFUNDS.FEATURE, CROWDFUNDS.FUND_TARGET, SUM(CROWDFUND_PATREONS.AMOUNT) AS RAISED, UNIX_TIMESTAMP(RELEASE_DATE) AS RELEASE_TS, UNIX_TIMESTAMP(END_DATE) AS END_TS FROM CROWDFUNDS " \
		"LEFT JOIN CROWDFUND_PATREONS on CROWDFUNDS.ID = CROWDFUND_PATREONS.CROWDFUND_ID " \
		"GROUP BY CROWDFUNDS.ID ORDER BY CROWDFUNDS.ID DESC LIMIT " # MAX_CROWDFUNDS,
		"OnDisplayCrowdfunds", "i", playerid
	), 1;
}

thread OnPlayerCrowdfundContribute( playerid, crowdfund_id, Float: amount )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		new feature[ 64 ];
		new curr_timestamp = gettime( );
		new release_timestamp = cache_get_field_content_int( 0, "RELEASE", dbHandle );
		new end_timestamp = cache_get_field_content_int( 0, "END", dbHandle );

		// check if released or ended
		if ( ( curr_timestamp > release_timestamp && release_timestamp != 0 ) || ( curr_timestamp > end_timestamp ) ) {
			SendError( playerid, "You can no longer contribute to this crowdfund as it is released or ended." );
			return ShowPlayerCrowdfunds( playerid );
		}

		// double check valid amounts again
		if ( amount < 10.0 || amount > GetPlayerIrresistibleCoins( playerid ) ) {
			SendError( playerid, "You can no longer contribute to this crowdfund as the contribution amount is invalid." );
			return ShowPlayerCrowdfunds( playerid );
		}

		// get feature name
		cache_get_field_content( 0, "FEATURE", feature );

		// notify and deduct ic
		GivePlayerIrresistibleCoins( playerid, -amount );
		SendClientMessageToAllFormatted( -1, ""COL_GOLD"[CROWDFUND]"COL_WHITE" %s(%d) has donated %s IC to the %s Crowdfund! <3", ReturnPlayerName( playerid ), playerid, number_format( amount, .prefix = '\0', .decimals = 2 ), feature );
		SavePlayerData( playerid ); // force save just incase

		// insert into database
		mysql_format(
			dbHandle, szBigString, sizeof( szBigString ),
			"INSERT INTO CROWDFUND_PATREONS (USER_ID, CROWDFUND_ID, AMOUNT) VALUES (%d, %d, %f)",
			GetPlayerAccountID( playerid ), crowdfund_id, amount
		);
		mysql_single_query( szBigString );
		return 1;
	}
	else
	{
		return SendError( playerid, "The crowdfund you are attempting to contribute to no longer exists." );
	}
}

thread OnDisplayCrowdfundPatreons( playerid, crowdfund_id )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_INFO, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Feature Crowdfunding", ""COL_GREY"Contributor\t"COL_GREY"Amount (IC)\n"COL_RED"No-One\t"COL_RED"N/A", "Close", "Back" ), 1;
	}

	new patreon[ MAX_PLAYER_NAME ];

	szHugeString = ""COL_GREY"Contributor\t"COL_GREY"Amount (IC)\n";

	for ( new row = 0; row < rows; row ++ )
	{
		cache_get_field_content( row, "NAME", patreon );

		new Float: contribution = cache_get_field_content_float( row, "TOTAL", dbHandle );

		format( szHugeString, sizeof( szHugeString ), "%s%s\t%s IC\n", szHugeString, patreon, number_format( contribution, .prefix = '\0', .decimals = 2 ) );
	}
	return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_INFO, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Feature Crowdfunding", szHugeString, "Close", "Back" ), 1;
}

thread OnDisplayCrowdfundInfo( playerid, crowdfund_id )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "There is no crowdfund information to show. Try again later." );
	}

	new cf_description[ 100 ];
	new description[ 100 ];
	new title[ 48 ];

	cache_get_field_content( 0, "CF_DESCRIPTION", cf_description );

	if ( strlen( cf_description ) < sizeof( cf_description ) - 1 ) {
		format( szHugeString, sizeof( szHugeString ), ""COL_WHITE"%s\n\n", cf_description );
	} else {
		format( szHugeString, sizeof( szHugeString ), ""COL_WHITE"%s"COL_GREY"... (read more on sfcnr.com)\n\n", cf_description );
	}

	for ( new row = 0; row < rows; row ++ )
	{
		cache_get_field_content( row, "TITLE", title );
		cache_get_field_content( row, "DESCRIPTION", description );

		new Float: req_amount = cache_get_field_content_float( row, "REQUIRED_AMOUNT", dbHandle );

		if ( strlen( description ) < sizeof( description ) - 1 ) {
			format( szHugeString, sizeof( szHugeString ), "%s"COL_GOLD"%s (%s IC+)"COL_WHITE"\n%s\n\n", szHugeString, title, number_format( req_amount, .prefix = '\0', .decimals = 2 ), description );
		} else {
			format( szHugeString, sizeof( szHugeString ), "%s"COL_GOLD"%s (%s IC+)"COL_WHITE"\n%s"COL_GREY"... (read more on sfcnr.com)\n\n", szHugeString, title, number_format( req_amount, .prefix = '\0', .decimals = 2 ), description );
		}
	}
	return ShowPlayerDialog( playerid, DIALOG_CROWDFUND_INFO, DIALOG_STYLE_MSGBOX, ""COL_GOLD"Feature Crowdfunding", szHugeString, "Close", "Back" ), 1;
}

thread OnDisplayCrowdfunds( playerid )
{
	new
		rows = cache_get_row_count( );

	if ( ! rows ) {
		return SendError( playerid, "There is no crowdfund to show. Try again later." );
	}

	new feature[ 64 ];
	new crowdfund_ids[ MAX_CROWDFUNDS * 3 ];

	// header
	szLargeString = ""COL_WHITE"Feature\t"COL_WHITE"Raised (IC)\t"COL_WHITE"Goal (IC)\t"COL_WHITE"Completion (%)\n";

	for ( new row = 0; row < MAX_CROWDFUNDS; row ++ )
	{
		new
			id = 0;

		if ( row < rows )
		{
			id = cache_get_field_content_int( row, "ID" );
			cache_get_field_content( row, "FEATURE", feature );

			new Float: amount_raised = cache_get_field_content_float( row, "RAISED", dbHandle );
			new Float: target_amount = cache_get_field_content_float( row, "FUND_TARGET", dbHandle );
			new Float: percent_raised = ( amount_raised / target_amount ) * 100.0;

			new curr_timestamp = gettime( );
			new release_timestamp = cache_get_field_content_int( row, "RELEASE_TS", dbHandle );
			new end_timestamp = cache_get_field_content_int( row, "END_TS", dbHandle );

			// inactive
			if ( ( curr_timestamp > release_timestamp && release_timestamp != 0 ) || ( curr_timestamp > end_timestamp ) )
			{
				format( szLargeString, sizeof( szLargeString ),
					"%s{333333}%s\t{333333}%s IC\t{333333}%s IC\t%s%0.1f%\n",
					szLargeString, feature,
					number_format( amount_raised, .prefix = '\0', .decimals = 1 ),
					number_format( target_amount, .prefix = '\0', .decimals = 1 ),
					percent_raised >= 100.0 ? ( COL_GREEN ) : ( COL_WHITE ), percent_raised
				);
			}
			else
			{
				format( szLargeString, sizeof( szLargeString ),
					"%s%s\t%s IC\t%s IC\t%s%0.1f%\n",
					szLargeString, feature,
					number_format( amount_raised, .prefix = '\0', .decimals = 1 ),
					number_format( target_amount, .prefix = '\0', .decimals = 1 ),
					percent_raised >= 100.0 ? ( COL_GREEN ) : ( COL_WHITE ), percent_raised
				);
			}
		}
		format( crowdfund_ids, sizeof( crowdfund_ids ), "%s%d ", crowdfund_ids, id );
	}

	// save ids for response
	SetPVarString( playerid, "crowdfunds_shown", crowdfund_ids );
	return ShowPlayerDialog( playerid, DIALOG_CROWDFUNDS, DIALOG_STYLE_TABLIST_HEADERS, ""COL_GOLD"Feature Crowdfunding", szLargeString, "Select", "Close" ), 1;
}
