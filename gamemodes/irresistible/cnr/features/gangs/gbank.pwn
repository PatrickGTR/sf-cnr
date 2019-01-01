/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: irresistible\cnr\features\gangs\gbank.pwn
 * Purpose: banking system for gangs
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
    if ( dialogid == DIALOG_BANK_MENU && response )
	{
		new
			gangid = p_GangID[ playerid ];

	    if ( IsPlayerJailed( playerid ) )
	    	return SendError( playerid, "You cannot use this while you're in jail." );

		if ( gangid == INVALID_GANG_ID && listitem > 2 )
	    	return SendError( playerid, "You are not in any gang!" );

        switch( listitem )
		{
            case 3:
            {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to withdraw from your gang bank account.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
                ShowPlayerDialog( playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", szBigString, "Withdraw", "Back" );
            }
           	case 4:
            {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to deposit into your gang bank account below.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
                ShowPlayerDialog( playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", szBigString, "Deposit", "Back" );
            }
            case 5:
            {
                format( szBigString, sizeof( szBigString ), ""COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ), cash_format( GetPlayerCash( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_GANG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Gang Account", szBigString, "Ok", "Back" );
            }
        }
        return 1;
    }
	else if ( dialogid == DIALOG_GANG_BANK_WITHDRAW )
	{
		if ( !response )
			return ShowPlayerBankMenuDialog( playerid );

		new
			iWithdraw,
			gangid = p_GangID[ playerid ]
		;

		if ( gangid == INVALID_GANG_ID )
			return SendError( playerid, "You must be in a gang to use this feature." );

	    if ( IsPlayerJailed( playerid ) )
	    	return SendError( playerid, "You cannot use this while you're in jail." );

	    if ( ! IsPlayerGangLeader( playerid, gangid ) )
	    	return ShowPlayerBankMenuDialog( playerid ), SendError( playerid, "You must be the gang leader to use this feature." );

		if ( strmatch( inputtext, "MAX" ) || strmatch( inputtext, "ALL" ) )
		{
			iWithdraw = g_gangData[ gangid ] [ E_BANK ];
		}
	  	else if ( sscanf( inputtext, "d", iWithdraw ) )
	    {
		    format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to withdraw from your gang bank account.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            return ShowPlayerDialog( playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", szBigString, "Withdraw", "Back" );
	    }

	    // double check quantity
		if ( iWithdraw > 99999999 || iWithdraw <= 0 )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to withdraw from your gang bank account.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", szBigString, "Withdraw", "Back" );
        }
        else if ( iWithdraw > g_gangData[ gangid ] [ E_BANK ] )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to withdraw from your gang bank account.\n\n"COL_RED"Insufficient balance, therefore withdrawal failed.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", szBigString, "Withdraw", "Back" );
        }
        else
        {
            g_gangData[ gangid ] [ E_BANK ] -= iWithdraw;
            GivePlayerCash( playerid, iWithdraw );
            SaveGangData( gangid );

			// transaction
	    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `TRANSACTIONS` (`TO_ID`, `FROM_ID`, `CASH`, `NATURE`) VALUES (%d, %d, %d, 'gang withdraw')", p_AccountID[ playerid ], g_gangData[ gangid ] [ E_SQL_ID ], iWithdraw );
	     	mysql_single_query( szNormalString );

	     	// withdraw
            SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]"COL_GREY" %s(%d) has withdrawn %s from the gang bank account.", ReturnPlayerName( playerid ), playerid, cash_format( iWithdraw ), "%%" );
            format( szBigString, sizeof( szBigString ), ""COL_GREY"Amount Withdrawn:"COL_WHITE" %s\n"COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( iWithdraw ), cash_format( g_gangData[ gangid ] [ E_BANK ] ), cash_format( GetPlayerCash( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Gang Account", szBigString, "Ok", "Back" );
        }
        return 1;
    }
	else if ( dialogid == DIALOG_GANG_BANK_DEPOSIT )
	{
		if ( ! response )
			return ShowPlayerBankMenuDialog( playerid );

		if ( ! IsPlayerSecurityVerified( playerid ) )
			return SendError( playerid, "You must be verified in order to use this feature. "COL_YELLOW"(use /verify)" );

		new
			iDeposit,
			gangid = p_GangID[ playerid ]
		;

		if ( gangid == INVALID_GANG_ID )
			return SendError( playerid, "You must be in a gang to use this feature." );

	    if ( IsPlayerJailed( playerid ) )
	    	return SendError( playerid, "You cannot use this while you're in jail." );

		if ( strmatch( inputtext, "MAX" ) || strmatch( inputtext, "ALL" ) )
		{
			iDeposit = GetPlayerCash( playerid );
		}
        else if ( sscanf( inputtext, "d", iDeposit ) )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to deposit into your gang bank account below.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", szBigString, "Deposit", "Back" );
        }

	    // double check
     	if ( iDeposit > 99999999 || iDeposit < 1 )
        {
        	format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to deposit into your gang bank account below.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", szBigString, "Deposit", "Back" );
        }
        else if ( iDeposit > GetPlayerCash( playerid ) )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to deposit into your gang bank account below.\n\n"COL_RED"Insufficient balance, therefore deposition failed.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( g_gangData[ gangid ] [ E_BANK ] ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Account", szBigString, "Deposit", "Back" );
        }
        else
        {
            g_gangData[ gangid ] [ E_BANK ] += iDeposit;
            GivePlayerCash( playerid, -iDeposit );
            SaveGangData( gangid );

			// transaction
	    	format( szNormalString, sizeof( szNormalString ), "INSERT INTO `TRANSACTIONS` (`TO_ID`, `FROM_ID`, `CASH`, `NATURE`) VALUES (%d, %d, %d, 'gang deposit')", p_AccountID[ playerid ], g_gangData[ gangid ] [ E_SQL_ID ], iDeposit );
	     	mysql_single_query( szNormalString );

	     	// deposit
            SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]"COL_GREY" %s(%d) has deposited %s into the gang bank account.", ReturnPlayerName( playerid ), playerid, cash_format( iDeposit ) );
            format( szBigString, sizeof( szBigString ), ""COL_GREY"Amount Deposited:"COL_WHITE" %s\n"COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( iDeposit ), cash_format( g_gangData[ gangid ] [ E_BANK ] ), cash_format( GetPlayerCash( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_GANG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Gang Account", szBigString, "Ok", "Back" );
        }
        return 1;
    }
    return 1;
}

/* ** Functions ** */
stock ShowPlayerGangBankMenuDialog( playerid )
{
	new
		gangid = p_GangID[ playerid ];

	if ( gangid != -1 && Iter_Contains( gangs, gangid ) ) {
		format( szBigString, sizeof( szBigString ), "Withdraw\nDeposit\nAccount Information\n{%06x}Gang Bank Withdraw\n{%06x}Gang Bank Deposit\n{%06x}Gang Bank Balance", g_gangData[ gangid ] [ E_COLOR ] >>> 8, g_gangData[ gangid ] [ E_COLOR ] >>> 8, g_gangData[ gangid ] [ E_COLOR ] >>> 8 );
		return ShowPlayerDialog( playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "{FFFFFF}Account", szBigString, "Select", "Cancel" );
	} else {
        return 0;
    }
}
