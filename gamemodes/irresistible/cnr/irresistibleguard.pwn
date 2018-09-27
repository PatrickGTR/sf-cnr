/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\irresistibleguard.pwn
 * Purpose: provides account protection in the form of email securing
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define SECURITY_MODE_MILD					( 0 )
#define SECURITY_MODE_PARANOID				( 1 )
#define SECURITY_MODE_DISABLED				( 2 )

/* ** Variables ** */
enum E_IRRESISTIBLE_GUARD
{
	E_ID,						E_EMAIL[ 64 ],					E_MODE,
	bool: E_VERIFIED,			E_LAST_DISABLED
};

new
	p_accountSecurityData		[ MAX_PLAYERS ] [ E_IRRESISTIBLE_GUARD ]
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	p_accountSecurityData[ playerid ] [ E_VERIFIED ] = false;
	p_accountSecurityData[ playerid ] [ E_ID ] = 0;
	p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = 0;
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( ( dialogid == DIALOG_ACC_GUARD ) && response )
	{
		if ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED )
			return SendError( playerid, "You must be verified to use this feature." );

		switch ( listitem )
		{
			case 0:
			{
				if ( p_accountSecurityData[ playerid ] [ E_ID ] )
					return SendError( playerid, "Your email is already confirmed!" ), ShowPlayerAccountGuard( playerid ), 1;

				format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `EMAILS` WHERE `USER_ID`=%d", p_AccountID[ playerid ] );
	    		mysql_function_query( dbHandle, szNormalString, true, "OnEmailConfirm", "d", playerid );
			}
			case 1: ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_MODE, DIALOG_STYLE_TABLIST, "{FFFFFF}Irresistible Guard - Mode", "Mild\t"COL_GREY"Must verify IP before making transactions\nParanoid\t"COL_GREY"Must verify IP after logging in\nDisable\t"COL_GREY"No form of verification", "Select", "Back" );
			case 2:
			{
				format( szBigString, sizeof( szBigString ), "SELECT * FROM `EMAILS` WHERE `ID`=%d", p_accountSecurityData[ playerid ] [ E_ID ] );
				mysql_function_query( dbHandle, szBigString, true, "OnAccountGuardDelete", "d", playerid );
			}
			case 3:
			{
				if ( p_AddedEmail{ playerid } )
					return SendError( playerid, "You already added an email to your account before." );

				if ( GetPlayerScore( playerid ) < 1000 )
					return SendServerMessage( playerid, "Get at least 1000 score, then use this feature." );

				Beep( playerid );
				p_AddedEmail{ playerid } = true;
				SetPlayerVipLevel( playerid, VIP_REGULAR, .interval = 259560 ); // 3 days of vip
				mysql_single_query( sprintf( "UPDATE `USERS` SET `USED_EMAIL`=1 WHERE `ID`=%d", p_AccountID[ playerid ] ) );
				SendGlobalMessage( COLOR_GOLD, "[EMAIL CONFIRMED]"COL_GREY" %s(%d) has confirmed their "COL_GOLD"/email"COL_GREY" and received 3 days of V.I.P!", ReturnPlayerName( playerid ), playerid );
 				return 1;
			}
		}
		return 1;
	}
	else if ( dialogid == DIALOG_ACC_GUARD_CONFIRM )
	{
		if ( ! response )
		{
			if ( p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_PARANOID ) {
				return Kick( playerid );
			}

			// allow other modes
			return 1;
		}

		static
			szInput[ 10 ];

		format( szInput, sizeof( szInput ), "%s", inputtext );
		trimString( szInput ); // gotta take out the whitespace

		if ( strlen( szInput ) != 8 )
			return SendError( playerid, "The verification code must be 8 characters." ), ShowPlayerAccountVerification( playerid );

		mysql_format( dbHandle, szBigString, sizeof( szBigString ), "SELECT * FROM `USER_CONFIRMED_IPS` WHERE `USER_ID`=%d AND `IP`='%e' AND `TOKEN`='%e'", p_AccountID[ playerid ], ReturnPlayerIP( playerid ), szInput );
		mysql_function_query( dbHandle, szBigString, true, "OnAccountGuardVerify", "d", playerid );
		return 1;
	}
	else if ( dialogid == DIALOG_ACC_GUARD_DEL_CANCEL )
	{
		if ( !response )
			return ShowPlayerAccountGuard( playerid );

		p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = 0;
		mysql_single_query( sprintf( "UPDATE `EMAILS` SET `LAST_CHANGED`=%d,`LAST_DISABLED`=0 WHERE `ID`=%d", g_iTime, p_accountSecurityData[ playerid ] [ E_ID ] ) );
		return SendServerMessage( playerid, "You have cancelled the process to removing Irresistible Guard." );
	}
	else if ( dialogid == DIALOG_ACC_GUARD_MODE )
	{
		if ( !response )
			return ShowPlayerAccountGuard( playerid );

		if ( ! p_accountSecurityData[ playerid ] [ E_ID ] )
			return SendError( playerid, "You need to assign an email to your account." );

		p_accountSecurityData[ playerid ] [ E_MODE ] = listitem;
		mysql_single_query( sprintf( "UPDATE `EMAILS` SET `MODE`=%d WHERE `ID`=%d", listitem, p_accountSecurityData[ playerid ] [ E_ID ] ) );
		SendServerMessage( playerid, "Your Irresistible Guard mode is now set to "COL_GREY"%s"COL_WHITE".", SecurityModeToString( listitem ) );
		return ShowPlayerAccountGuard( playerid );
	}
	return 1;
}

/* ** Functions ** */
stock IsPlayerSecurityVerified( playerid ) {
	return ! ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED );
}
