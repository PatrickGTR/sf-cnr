/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\vip\redeem_code.pwn
 * Purpose: code redemption system for newly donating donors
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined __cnr__irresistiblecoins
	#endinput
#endif

/* ** Definitions ** */
#define szRedemptionSalt 			"7resta#ecacakumedeM=yespawr!d@et"

/* ** Variables ** */
enum E_DONATION_DATA
{
	E_TRANSACTION_ID[ 17 ],
	E_NAME[ 24 ],
	E_AMOUNT[ 11 ],
	E_PURPOSE[ 64 ],
	E_DATE
};

static stock g_redeemVipWait 		= 0;
static stock g_TopDonorWall 		= INVALID_OBJECT_ID;
stock Text: g_TopDonorTD            = Text: INVALID_TEXT_DRAW;

/* ** Forwards ** */
forward OnDonationRedemptionResponse( index, response_code, data[ ] );

/* ** Hooks ** */
hook OnScriptInit( )
{
	// Wall of Donors
	SetDynamicObjectMaterialText( CreateDynamicObject( 3074, -1574.3559, 885.1296, 28.4690, 0.0000, 0.0000, -0.0156 ), 0, "Thx Monthly Donors", 130, "Times New Roman", 64, 1, -65536, 0, 1 );
	SetDynamicObjectMaterialText( ( g_TopDonorWall = CreateDynamicObject( 3074, -1574.3559, 885.1296, 14.0153, 0.0000, 0.0000, -0.0156 ) ), 0, "Nobody donated :(", 130, "Arial", 48, 0, -65536, 0, 1 );

    // Latest Donor TD
	g_TopDonorTD = TextDrawCreate(320.000000, 2.000000, "Top Donor Lorenc - $0.00, ~w~~h~~h~Latest Donor Lorenc - $0.00");
	TextDrawAlignment(g_TopDonorTD, 2);
	TextDrawBackgroundColor(g_TopDonorTD, 0);
	TextDrawFont(g_TopDonorTD, 1);
	TextDrawLetterSize(g_TopDonorTD, 0.139999, 0.799999);
	TextDrawColor(g_TopDonorTD, -2347265);
	TextDrawSetOutline(g_TopDonorTD, 1);
	TextDrawSetProportional(g_TopDonorTD, 1);

	/* ** Update Donation TD ** */
	UpdateGlobalDonated( );
    return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_VIP && response )
	{
		if ( strlen( inputtext ) != 16 )
		{
			cmd_donated( playerid, "" );
			return SendError( playerid, "The transaction ID you entered is invalid." );
		}

		if ( g_redeemVipWait > g_iTime )
		{
			cmd_donated( playerid, "" );
			return SendServerMessage( playerid, "Our anti-exploit system requires you to wait another %d seconds before redeeming.", g_redeemVipWait - g_iTime );
		}

		HTTP( playerid, HTTP_GET, sprintf( "donate.sfcnr.com/validate_code/%s", inputtext ), "", "OnDonationRedemptionResponse" );
		SendServerMessage( playerid, "We're now looking up this transaction. Please wait." );
        return 1;
	}
	else if ( dialogid == DIALOG_DONATED )
	{
		szLargeString[ 0 ] = '\0';
		strcat( szLargeString,	""COL_WHITE"Thank you a lot for donating! :D In return for your dignity, you have received Irresistible Coins.\n\n"\
								""COL_GREY" * What do I do with Irresistible Coins?"COL_WHITE" You can claim the V.I.P of your choice via "COL_GREY"/irresistiblecoins market"COL_WHITE".\n" );
		strcat( szLargeString,	""COL_GREY" * How many do I have?"COL_WHITE" You can see how many Irresistible Coins you have via "COL_GREY"/irresistiblecoins"COL_WHITE".\n" \
								""COL_GREY" * I'm unsure, help?"COL_WHITE" If you have any questions, please /ask otherwise enquire Lorenc via the forums!\n\nThank you once again for your contribution to our community! :P"  );
		return ShowPlayerDialog( playerid, DIALOG_FINISHED_DONATING, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", szLargeString, "Got it!", "" );
	}
	else if ( dialogid == DIALOG_FINISHED_DONATING )
    {
		return ShowPlayerDialog( playerid, DIALOG_LATEST_DONOR, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"Would you like to be shown as the latest donor?", "Yes", "No" );
	}
	else if ( dialogid == DIALOG_LATEST_DONOR )
    {
		if ( GetPVarType( playerid, "just_donated" ) != PLAYER_VARTYPE_FLOAT )
			return SendError( playerid, "Seems to be an issue where we couldn't find how much you donated. Report to Lorenc." );

		new
			Float: fAmount = GetPVarFloat( playerid, "just_donated" );

		DeletePVar( playerid, "just_donated" );
		return UpdateGlobalDonated( playerid, fAmount, !response );
	}
    return 1;
}

/* ** Callbacks ** */
public OnDonationRedemptionResponse( index, response_code, data[ ] )
{
    if ( response_code == 200 )
    {
		if ( strmatch( data, "{FFFFFF}Unable to identify transaction." ) ) ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", data, "Okay", "" );
		else
		{
			static aDonation[ E_DONATION_DATA ];
			sscanf( data, "p<|>e<s[17]s[24]s[11]s[64]d>", aDonation );

			// printf("donation {id:%s, name:%s, amount:%s, purpose:%s, date:%d}", aDonation[ E_TRANSACTION_ID ],aDonation[ E_NAME ],aDonation[ E_AMOUNT ],aDonation[ E_PURPOSE ],aDonation[ E_DATE ]);
			if ( strfind( aDonation[ E_PURPOSE ], "San Fierro: Cops And Robbers" ) == -1 ) {
				ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"This donation is not specifically for this server thus you are unable to retrieve anything.", "Okay", "" );
				return 0;
			}

			// SELECT * FROM `REDEEMED` WHERE `ID` = MD5('%s7resta#ecacakumedeM=yespawr!d@et') LIMIT 0,1
			mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "SELECT * FROM `REDEEMED` WHERE `ID` = MD5('%e%s') LIMIT 0,1", aDonation[ E_TRANSACTION_ID ], szRedemptionSalt );
	 		mysql_tquery( dbHandle, szNormalString, "OnCheckForRedeemedVIP", "is", index, data );
		}
	}
 	else
    {
        return ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"Unable to connect to the donation database. Please try again later.", "Okay", "" );
    }
    return 1;
}

/* ** SQL Threads ** */
thread OnCheckForRedeemedVIP( playerid, data[ ] )
{
	static
		aDonation[ E_DONATION_DATA ],
	    rows, fields
	;
    cache_get_data( rows, fields );

	if ( rows )
	{
		static
			szName[ MAX_PLAYER_NAME ];

		cache_get_field_content( 0, "REDEEMER", szName );
		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", sprintf( ""COL_WHITE"Sorry this transaction ID has already been redeemed by %s.", szName ), "Okay", "" );
	}
	else
	{
		g_redeemVipWait = g_iTime + 10;

		sscanf( data, "p<|>e<s[17]s[24]s[11]s[64]d>", aDonation );

		mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "INSERT INTO `REDEEMED`(`ID`, `REDEEMER`) VALUES (MD5('%e%s'), '%e')", aDonation[ E_TRANSACTION_ID ], szRedemptionSalt, ReturnPlayerName( playerid ) );
		mysql_single_query( szNormalString );

		//printf( "%s\n%s | %s | %f | %s | %d", data, aDonation[ E_TRANSACTION_ID ], aDonation[ E_EMAIL ], floatstr( aDonation[ E_AMOUNT ] ), aDonation[ E_PURPOSE ], aDonation[ E_DATE ]);

		new
			Float: fAmount = floatstr( aDonation[ E_AMOUNT ] ),
			Float: iCoins = fAmount * ( 1 + GetGVarFloat( "vip_bonus" ) ) * 100.0
		;

		if ( p_Uptime[ playerid ] > 604800 )
		{
			if ( fAmount < 1.99999 )
				return SendError( playerid, "Thanks for donating! As this donation was under $2.00 USD, no coin has been issued." );
		}
		else
		{
			if ( fAmount < 4.99999 )
				return SendError( playerid, "Thanks for donating! As this donation was under $5.00 USD, no coins have been issued." );
		}

		GivePlayerIrresistibleCoins( playerid, iCoins );
		SetPVarFloat( playerid, "just_donated", fAmount );

		SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[VIP PACKAGE]"COL_WHITE" You have received %0.0f Irresistible Coins! Thanks for donating %s!!! :D", iCoins, ReturnPlayerName( playerid ) );

		format( szBigString, 256, ""COL_GREY"Transaction ID:\t"COL_WHITE"%s\n"COL_GREY"Donor Name:\t"COL_WHITE"%s\n"COL_GREY"Amount:\t"COL_WHITE"$%0.2f\n"COL_GREY"Total Coins:\t"COL_WHITE"%0.0f\n"COL_GREY"Time Ago:\t"COL_WHITE"%s",
				aDonation[ E_TRANSACTION_ID ], aDonation[ E_NAME ], floatstr( aDonation[ E_AMOUNT ] ), iCoins, secondstotime( g_iTime - aDonation[ E_DATE ] ) );

		ShowPlayerDialog( playerid, DIALOG_DONATED, DIALOG_STYLE_MSGBOX, ""COL_GOLD"SF-CNR Donation", szBigString, "Continue", "" );
	}
	return 1;
}

thread OnGrabLatestDonor( hidden )
{
	new
		rows;

    cache_get_data( rows, tmpVariable );

	if ( rows )
	{
		static
			szName[ MAX_PLAYER_NAME ],
			Float: fAmount;


		cache_get_field_content( 0, "NAME", szName );
		fAmount = cache_get_field_content_float( 0, "LAST_AMOUNT", dbHandle );

		// Play song!
		GameTextForAll( sprintf( "~y~~h~~h~New Donor!~n~~w~%s", szName ), 6000, 3 );

		// Play sound
		foreach(new p : Player) if ( !IsPlayerUsingRadio( p ) ) {
			PlayAudioStreamForPlayer( p, "http://files.sfcnr.com/game_sounds/donated.mp3" );
		}

		TextDrawSetString( g_TopDonorTD, sprintf( "Le Latest Donor %s - $%0.2f", szName, fAmount ) );
	}
	else
	{
		TextDrawSetString( g_TopDonorTD, "Nobody Donated :(" );
	}
	return 1;
}

thread OnUpdateWallOfDonors( )
{
	new
		rows;

    cache_get_data( rows, tmpVariable );

	if( rows )
	{
		new
			szString[ 600 ],
			iLine = 1,
			iPosition = 0;

		for( new row = 0; row < rows; row++ )
		{
			new
				szName[ MAX_PLAYER_NAME ];

			cache_get_field_content( row, "NAME", szName );

			new
				iOldLength = strlen( szString ) + 4; // 4 is an offset

			if( iOldLength - iPosition > 24 ) {
				iPosition = iOldLength;
				strcat( szString, "\n" ), iLine ++;
			}

			// The wall of donors
			format( szString, sizeof( szString ), "%s%s, ", szString, szName );
		}

		// The wall of donors formatting
		new
			iLength = strlen( szString );

		strdel( szString, iLength - 2, iLength );

		// Develop a size and format
		SetDynamicObjectMaterialText( g_TopDonorWall, 0, szString, 130, "Arial", floatround( 48.0 * floatpower( 0.925, iLine - 1 ), floatround_ceil ), 0, -65536, 0, 1 );
	}
	else
	{
		SetDynamicObjectMaterialText( g_TopDonorWall, 0, "Nobody Donated :(", 130, "Arial", 48, 0, -65536, 0, 1 );
	}
	return 1;
}

/* ** Commands ** */
CMD:redeemvip( playerid, params[ ] ) return cmd_donated( playerid, params );
CMD:donated( playerid, params[ ] )
{
	ShowPlayerDialog( playerid, DIALOG_VIP, DIALOG_STYLE_INPUT, ""COL_GOLD"SF-CNR Donation", ""COL_WHITE"Enter the transaction ID of your donation below.\n\n"COL_GREY"See http://forum.sfcnr.com/showthread.php?10125 for details.", "Redeem", "Close" );
	return 1;
}

/* ** RCON Commands ** */
CMD:updatedonortd( playerid, params[ ] )
{
	new
		targetid, Float: amount, reset;

	if ( ! IsPlayerAdmin( playerid ) ) return 0;
	else if ( sscanf( params, "D(0)D(65535)F(0.0)", reset, targetid, amount ) ) return SendUsage( playerid, "/updatedonortd [RESET] [PLAYER_ID] [AMOUNT]" );
	else
	{
		// Reset the top donor
		if ( reset ) {
			TextDrawSetString( g_TopDonorTD, "Nobody Donated :(" );
		}

		// Update it incase
		UpdateGlobalDonated( targetid, amount );
		SendServerMessage( playerid, "Updating latest donor now (player id %d, amount %f)", targetid, amount );
	}
	return 1;
}

/* ** Functions ** */
static stock UpdateGlobalDonated( playerid = INVALID_PLAYER_ID, Float: amount = 0.0, hidden = 0 )
{
	if ( playerid != INVALID_PLAYER_ID && amount > 0.0 ) {
		format( szBigString, sizeof( szBigString ), "INSERT INTO `TOP_DONOR` (`USER_ID`,`AMOUNT`,`LAST_AMOUNT`,`TIME`,`HIDE`) VALUES(%d,%f,%f,%d,%d) ON DUPLICATE KEY UPDATE `AMOUNT`=`AMOUNT`+%f,`LAST_AMOUNT`=%f,`TIME`=%d,`HIDE`=%d;", p_AccountID[ playerid ], amount, amount, g_iTime, hidden, amount, amount, g_iTime, hidden );
		mysql_single_query( szBigString );
	}

	// top donor
	if ( ! hidden ) {
		mysql_tquery( dbHandle, "SELECT `NAME`,`LAST_AMOUNT` FROM `TOP_DONOR` INNER JOIN `USERS` ON `TOP_DONOR`.`USER_ID`=`USERS`.`ID` WHERE `LAST_AMOUNT` > 0 AND `HIDE` < 1 ORDER BY `TIME` DESC LIMIT 1", "OnGrabLatestDonor", "" );
	}

	// wall of donors
	mysql_tquery( dbHandle, "SELECT `USERS`.`NAME` FROM `TOP_DONOR` INNER JOIN `USERS` ON `TOP_DONOR`.`USER_ID`=`USERS`.`ID` WHERE `HIDE` < 1 ORDER BY `AMOUNT` DESC, `TIME` DESC", "OnUpdateWallOfDonors", "" );
	return 1;
}
