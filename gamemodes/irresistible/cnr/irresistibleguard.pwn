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

hook OnPlayerLogin( playerid )
{
	format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `EMAILS` WHERE `USER_ID`=%d", GetPlayerAccountID( playerid ) );
	mysql_function_query( dbHandle, szNormalString, true, "OnEmailLoad", "d", playerid );
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_ACC_GUARD && response )
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
				SetPlayerVipLevel( playerid, VIP_REGULAR, .interval = 259560, .credit_assets = false ); // 3 days of vip
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
	else if ( dialogid == DIALOG_ACC_GUARD_EMAIL && response )
	{
		new
			email[ 64 ];

		if ( sscanf( inputtext, "s[64]", email ) )
			return SendError( playerid, "Your email must be between 4 and 64 characters long." );

		if ( ! ( 3 < strlen( email ) < 64 ) )
			return SendError( playerid, "Your email must be between 4 and 64 characters long." );

		if ( ! regex_match( email, "[a-zA-Z0-9_\\.]+@([a-zA-Z0-9\\-]+\\.)+[a-zA-Z]{2,4}" ) )
			return SendError( playerid, "Your email must be valid (foo@example.com)." );

	    format( szBigString, sizeof( szBigString ), "INSERT INTO `EMAIL_VERIFY`(`USER_ID`, `EMAIL`) VALUES (%d, '%s') ON DUPLICATE KEY UPDATE `EMAIL`='%s',`DATE`=CURRENT_TIMESTAMP", p_AccountID[ playerid ], mysql_escape( email ), mysql_escape( email ) );
	    mysql_function_query( dbHandle, szBigString, true, "OnQueueEmailVerification", "ds", playerid, email );
		return 1;
	}
	return 1;
}

/* ** SQL Threads ** */
thread OnQueueEmailVerification( playerid, email[ ] )
{
	new
		verification_id = cache_insert_id( );

	// alert
	SendServerMessage( playerid, "An email has been sent to "COL_GREY"%s"COL_WHITE" with instructions to confirm your account.", email );

	// sending an email
	format( szLargeString, sizeof( szLargeString ), "<p>Hello %s, you are receiving this email because you want to add Irresistible Guard to your account.</p><p><a href='http://" # MAILING_URL "/email/verify/%d/%d'>Click here to verify your email</a></p>", ReturnPlayerName( playerid ), p_AccountID[ playerid ], verification_id );
	SendMail( email, ReturnPlayerName( playerid ), sprintf( "Verify your account, %s", ReturnPlayerName( playerid ) ), szLargeString );
	return 1;
}

thread OnAccountGuardVerify( playerid )
{
	new
	    rows, fields;

    cache_get_data( rows, fields );

	if ( rows )
	{
		new
			userConfirmedIpId = cache_get_field_content_int( 0, "ID", dbHandle );

		p_accountSecurityData[ playerid ] [ E_VERIFIED ] = true;
		mysql_single_query( sprintf( "UPDATE `USER_CONFIRMED_IPS` SET `CONFIRMED`=1 WHERE `ID`=%d", userConfirmedIpId ) );

		// alert
		SendServerMessage( playerid, "You have confirmed your IP address. Thank you!" );
	}
	else
	{
		SendError( playerid, "Incorrect verification code has been specified. Please try again." );
		ShowPlayerAccountVerification( playerid );
	}
	return 1;
}

thread OnAccountEmailVerify( playerid, login_force )
{
	new
	    rows, fields, timestamp;

    cache_get_data( rows, fields );

	if ( rows )
	{
		new
			confirmed = cache_get_field_content_int( 0, "CONFIRMED", dbHandle );

		if ( confirmed )
		{
			// verify
	    	p_accountSecurityData[ playerid ] [ E_VERIFIED ] = true;

			// alert
			return SendServerMessage( playerid, "This account is protected by Irresistible Guard. "COL_GREEN"The IP you are playing with has been already verified." ), 1;
		}

		// assign last time
		timestamp = cache_get_field_content_int( 0, "DATE", dbHandle );
	}

	// No point making a disabled user validate
	if ( login_force && p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_DISABLED )
		return 1;

	// No point forcing a mild mode user to validate
	if ( login_force && p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_MILD )
		return SendError( playerid, "This account is protected by Irresistible Guard. "COL_RED"Please verify your IP through your email to transact in-game." );

	if ( g_iTime - timestamp >= 300 )
	{
		new
			iRandom = RandomEx( 10000000, 99999999 );

		// insert into database
		format( szBigString, sizeof( szBigString ), "INSERT INTO `USER_CONFIRMED_IPS`(`USER_ID`,`IP`,`TOKEN`,`CONFIRMED`) VALUES (%d,'%s','%d',0) ON DUPLICATE KEY UPDATE `TOKEN`='%d',`DATE`=CURRENT_TIMESTAMP", p_AccountID[ playerid ], ReturnPlayerIP( playerid ), iRandom, iRandom );
		mysql_single_query( szBigString );

		// email
		format( szLargeString, sizeof( szLargeString ), "<p>Hey %s, you are receiving this email because an unauthorized IP is accessing your account.</p>"\
														"<p>IP: %s<br>Country: %s (may be inaccurate)</p>"\
														"<p>Your verification token is <strong>%d</strong> - keep this only to yourself!</p>"\
														"<p style='color: red'>If you did not authorize this, change your password in-game or contact an administrator!</p>",
														ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ), GetPlayerCountryName( playerid ), iRandom );

		SendMail( p_accountSecurityData[ playerid ] [ E_EMAIL ], ReturnPlayerName( playerid ), sprintf( "Someones accessing your account, %s", ReturnPlayerName( playerid ) ), szLargeString );
	}
	else
	{
		SendServerMessage( playerid, "Please check your email for another token. A new code can be generated in %s.", secondstotime( 300 - ( g_iTime - timestamp ) ) );
	}

	// force verification
	ShowPlayerAccountVerification( playerid );

	// alert
	if ( p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_PARANOID ) {
		SendError( playerid, "This account is protected by Irresistible Guard. "COL_RED"Please verify your IP through your email to play." );
	} else if ( p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_MILD ) {
		SendError( playerid, "This account is protected by Irresistible Guard. "COL_RED"Please verify your IP through your email to transact in-game." );
	}
	return 1;
}

thread OnEmailLoad( playerid )
{
	new
	    rows, fields;

    cache_get_data( rows, fields );

    if ( rows )
    {
    	p_accountSecurityData[ playerid ] [ E_VERIFIED ] = false;
    	p_accountSecurityData[ playerid ] [ E_ID ] = cache_get_field_content_int( 0, "ID", dbHandle );
    	p_accountSecurityData[ playerid ] [ E_MODE ] = cache_get_field_content_int( 0, "MODE", dbHandle );
    	p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = cache_get_field_content_int( 0, "LAST_DISABLED", dbHandle );
    	cache_get_field_content( 0, "EMAIL", p_accountSecurityData[ playerid ] [ E_EMAIL ], dbHandle, 64 );

    	// IP Check
		format( szBigString, 196, "SELECT `CONFIRMED`,UNIX_TIMESTAMP(`DATE`) as `DATE` FROM `USER_CONFIRMED_IPS` WHERE `USER_ID`=%d AND `IP`='%s'", p_AccountID[ playerid ], mysql_escape( ReturnPlayerIP( playerid ) ) );
		mysql_function_query( dbHandle, szBigString, true, "OnAccountEmailVerify", "dd", playerid, 1 );
    }
}

thread OnEmailConfirm( playerid )
{
	new
	    rows, fields;

    cache_get_data( rows, fields );

    if ( rows )
    {
    	// fill data
    	p_accountSecurityData[ playerid ] [ E_VERIFIED ] = true;
    	p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = 0;
    	p_accountSecurityData[ playerid ] [ E_ID ] = cache_get_field_content_int( 0, "ID", dbHandle );
    	p_accountSecurityData[ playerid ] [ E_MODE ] = cache_get_field_content_int( 0, "MODE", dbHandle );
    	cache_get_field_content( 0, "EMAIL", p_accountSecurityData[ playerid ] [ E_EMAIL ], dbHandle, 64 );

    	// log ip and alert
    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `USER_CONFIRMED_IPS`(`USER_ID`,`IP`,`CONFIRMED`) VALUES (%d,'%s',1)", p_AccountID[ playerid ], ReturnPlayerIP( playerid ) );
    	mysql_single_query( szNormalString );

    	// alert
    	SendServerMessage( playerid, "Your email has been confirmed, %s.", ReturnPlayerName( playerid ) );
    }
    else
    {
		format( szNormalString, sizeof( szNormalString ), "SELECT `EMAIL`,UNIX_TIMESTAMP(`DATE`) as `DATE` FROM `EMAIL_VERIFY` WHERE `USER_ID`=%d", p_AccountID[ playerid ] );
		mysql_function_query( dbHandle, szNormalString, true, "OnEmailVerifying", "d", playerid );
    }
	return 1;
}

thread OnEmailVerifying( playerid )
{
	new
		rows, fields, email[ 64 ];

	cache_get_data( rows, fields );

	if ( rows )
	{
		new
			timestamp = cache_get_field_content_int( 0, "DATE", dbHandle );

		if ( g_iTime - timestamp < 300 )
		{
			cache_get_field_content( 0, "EMAIL", email );
			return SendError( playerid, "An email has been sent to "COL_GREY"%s"COL_WHITE", please verify it within %s.", email, secondstotime( 300 - ( g_iTime - timestamp ) ) ), 1;
		}
	}
	return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_EMAIL, DIALOG_STYLE_INPUT, "{FFFFFF}Irresistible Guard", ""COL_WHITE"Please type your email below. Your email may be used also to promote in-game and/or community associated events.\n\n"COL_ORANGE"This feature can only be used once every 5 minutes.", "Select", "Cancel" ), 1;
}

thread OnAccountGuardDelete( playerid )
{
	new
		rows, fields;

	cache_get_data( rows, fields );

	if ( !rows ) SendError( playerid, "It appears there is no email associated to your account." );
	else
	{
		new
			id = cache_get_field_content_int( 0, "ID", dbHandle ),
			last_disabled = cache_get_field_content_int( 0, "LAST_DISABLED", dbHandle ),
			last_changed = cache_get_field_content_int( 0, "LAST_CHANGED", dbHandle )
		;

		if ( id != p_accountSecurityData[ playerid ] [ E_ID ] )
			return SendError( playerid, "Something is wrong with your email. Talk to Lorenc." ), 1;

		if ( g_iTime - last_changed < 300 ) {
			return SendError( playerid, "You can use this feature in %s.", secondstotime( 300 - ( g_iTime - last_changed ) ) );
		}

		if ( ! last_disabled )
		{
			// first time disabling
			SendServerMessage( playerid, "You are now beginning to remove the email from your account. This will take 24 hours." );
			mysql_single_query( sprintf( "UPDATE `EMAILS` SET `LAST_DISABLED`=%d WHERE `ID`=%d", g_iTime + 86400, id ) );

			// email
			format( szLargeString, sizeof( szLargeString ), "<p>Hey %s, you are receiving this email because you are removing your Irresistible Guard.</p>"\
															"<p>IP: %s<br>Country: %s</p>"\
															"<p style='color: red'>If you did not authorize this, change your password in-game or contact an administrator!</p>",
															ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ), GetPlayerCountryName( playerid ) );

			SendMail( p_accountSecurityData[ playerid ] [ E_EMAIL ], ReturnPlayerName( playerid ), sprintf( "You are removing Irresistible Guard, %s", ReturnPlayerName( playerid ) ), szLargeString );

			// update variables
			p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = g_iTime + 86400;
		}
		else if ( g_iTime > last_disabled )
		{
			// under process of disabling
			mysql_single_query( sprintf( "DELETE FROM `EMAILS` WHERE `USER_ID`=%d", p_AccountID[ playerid ] ) );
			mysql_single_query( sprintf( "DELETE FROM `EMAIL_VERIFY` WHERE `USER_ID`=%d", p_AccountID[ playerid ] ) );
			mysql_single_query( sprintf( "DELETE FROM `USER_CONFIRMED_IPS` WHERE `USER_ID`=%d", p_AccountID[ playerid ] ) );

			// email
			format( szLargeString, sizeof( szLargeString ), "<p>Hey %s, you are receiving this email because Irresistible Guard is removed from your account.</p>"\
															"<p>IP: %s<br>Country: %s</p>"\
															"<p style='color: red'>If you did not authorize this, change your password in-game or contact an administrator!</p>",
															ReturnPlayerName( playerid ), ReturnPlayerIP( playerid ), GetPlayerCountryName( playerid ) );

			SendMail( p_accountSecurityData[ playerid ] [ E_EMAIL ], ReturnPlayerName( playerid ), sprintf( "Irresistible Guard is removed, %s", ReturnPlayerName( playerid ) ), szLargeString );

			// reset variables
			p_accountSecurityData[ playerid ] [ E_VERIFIED ] = false;
			p_accountSecurityData[ playerid ] [ E_ID ] = 0;
			p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = 0;

			// alert
			SendServerMessage( playerid, "You have successfully removed Irresistible Guard from your account." );
		}
		else
		{
			// update last disabled anyway
			p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] = last_disabled;

			// show dialog
			format( szNormalString, sizeof( szNormalString ), ""COL_WHITE"You must wait another %s until you can remove your email.\n\nDo you wish to stop this process?", secondstotime( last_disabled - g_iTime ) );
			ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_DEL_CANCEL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Irresistible Guard - Stop Deletion", szNormalString, "Yes", "No" );
		}
	}
	return 1;
}

/* ** Commands ** */
CMD:email( playerid, params[ ] ) {
	return ShowPlayerAccountGuard( playerid );
}

CMD:verify( playerid, params[ ] )
{
	if ( ! p_accountSecurityData[ playerid ] [ E_ID ] )
		return SendError( playerid, "You do not have an email assigned to your account." );

	if ( p_accountSecurityData[ playerid ] [ E_VERIFIED ] )
		return SendError( playerid, "You are already verified." );

	if ( p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_DISABLED )
		return SendError( playerid, "Your security mode is set to disabled." );

	format( szBigString, 196, "SELECT `CONFIRMED`,UNIX_TIMESTAMP(`DATE`) as `DATE` FROM `USER_CONFIRMED_IPS` WHERE `USER_ID`=%d AND `IP`='%s'", p_AccountID[ playerid ], mysql_escape( ReturnPlayerIP( playerid ) ) );
	mysql_function_query( dbHandle, szBigString, true, "OnAccountEmailVerify", "dd", playerid, 0 );
	return 1;
}

/* ** Functions ** */
stock SecurityModeToString( modeid )
{
	static
		szMode[ 9 ];

	switch ( modeid )
	{
		case 0: szMode = "Mild";
		case 1: szMode = "Paranoid";
		case 2: szMode = "Disabled";
		default: szMode = "n/a";
	}
	return szMode;
}

stock ShowPlayerAccountGuard( playerid )
{
	if ( p_accountSecurityData[ playerid ] [ E_ID ] != 0 ) {
		if ( p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] && p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] < g_iTime ) {
			format( szBigString, sizeof( szBigString ), ""COL_WHITE"Your account email is "COL_GREEN"confirmed\t \nConfirm Email\t"COL_GREEN"%s\nSecurity Mode\t%s\n"COL_RED"Remove Irresistible Guard\t"COL_GREEN"Ready", CensoreString( p_accountSecurityData[ playerid ] [ E_EMAIL ] ), SecurityModeToString( p_accountSecurityData[ playerid ] [ E_MODE ] ) );
		} else if ( p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] ) {
			format( szBigString, sizeof( szBigString ), ""COL_WHITE"Your account email is "COL_GREEN"confirmed\t \nConfirm Email\t"COL_GREEN"%s\nSecurity Mode\t%s\n"COL_ORANGE"Stop Pending Removal\t"COL_ORANGE"%s", CensoreString( p_accountSecurityData[ playerid ] [ E_EMAIL ] ), SecurityModeToString( p_accountSecurityData[ playerid ] [ E_MODE ] ), secondstotime( p_accountSecurityData[ playerid ] [ E_LAST_DISABLED ] - g_iTime ) );
		} else {
			format( szBigString, sizeof( szBigString ), ""COL_WHITE"Your account email is "COL_GREEN"confirmed\t \nConfirm Email\t"COL_GREEN"%s\nSecurity Mode\t%s\n"COL_RED"Remove Irresistible Guard\t"COL_RED"approx. 24h", CensoreString( p_accountSecurityData[ playerid ] [ E_EMAIL ] ), SecurityModeToString( p_accountSecurityData[ playerid ] [ E_MODE ] ) );
		}

		// award user for adding their email
		if ( p_AddedEmail{ playerid } == false ) {
			strcat( szBigString, "\n"COL_GOLD"Claim Free 3 Days Of Regular VIP!\t"COL_GOLD">>>" );
		}
	} else {
		szBigString = ""COL_WHITE"Your account email is "COL_RED"unconfirmed\t \nConfirm Email\t"COL_GREY">>>";
	}
	return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Irresistible Guard", szBigString, "Select", "Close" );
}

stock ShowPlayerAccountVerification( playerid )
{
	if ( p_accountSecurityData[ playerid ] [ E_MODE ] == 1 ) {
		return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_CONFIRM, DIALOG_STYLE_INPUT, "{FFFFFF}Irresistible Guard", ""COL_WHITE"Please type the verification token that has been emailed to you.", "Confirm", "Quit" ), 1;
	} else {
		return ShowPlayerDialog( playerid, DIALOG_ACC_GUARD_CONFIRM, DIALOG_STYLE_INPUT, "{FFFFFF}Irresistible Guard", ""COL_WHITE"Please type the verification token that has been emailed to you.", "Confirm", "Close" ), 1;
	}
}

stock IsPlayerSecurityFullyVerified( playerid ) { // paranoid check
	return ! ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] == SECURITY_MODE_PARANOID );
}

stock IsPlayerSecurityVerified( playerid ) {
	return ! ( p_accountSecurityData[ playerid ] [ E_ID ] && ! p_accountSecurityData[ playerid ] [ E_VERIFIED ] && p_accountSecurityData[ playerid ] [ E_MODE ] != SECURITY_MODE_DISABLED );
}

stock IsPlayerEmailVerified( playerid ) {
	return p_accountSecurityData[ playerid ] [ E_ID ];
}
