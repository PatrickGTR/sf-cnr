/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: irresistible\cnr\features\player\bank.pwn
 * Purpose: banking system for players
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Macros ** */
#define GetPlayerTotalCash(%0)  	( GetPlayerBankMoney( %0 ) + GetPlayerCash( %0 ) ) // Bank Money and Money

/* ** Variables ** */
static stock p_BankMoney            [ MAX_PLAYERS ];

/* ** Forwards ** */
forward OnPlayerBankMoneyChanged    ( playerid, amount );

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
    if ( dialogid == DIALOG_BANK_MENU && response )
	{
	    if ( IsPlayerJailed( playerid ) )
	    	return SendError( playerid, "You cannot use this while you're in jail." );

        switch( listitem )
		{
            case 0:
            {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to withdraw from your bank account.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", szBigString, "Withdraw", "Back" );
            }
            case 1:
            {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to deposit into your bank account below.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", szBigString, "Deposit", "Back" );
            }
            case 2:
            {
                format( szBigString, sizeof( szBigString ), ""COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( GetPlayerBankMoney( playerid ) ), cash_format( GetPlayerCash( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Personal Account", szBigString, "Ok", "Back" );
            }
            // ... cases 3, 4, 5 handled in cnr\features\gangs\gbank.pwn
        }
        return 1;
    }
    else if ( dialogid == DIALOG_BANK_WITHDRAW )
	{
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this while you're in jail." );
        if ( ! response ) return ShowPlayerBankMenuDialog( playerid );

        new
            money_withdraw[ 24 ];

        format( money_withdraw, sizeof( money_withdraw ), "%s", inputtext );

        if ( strmatch( money_withdraw, "MAX" ) || strmatch( money_withdraw, "ALL" ) ) {
            format( money_withdraw, sizeof( money_withdraw ), "%d", GetPlayerBankMoney( playerid ) );
        }

        if ( ! strlen( money_withdraw ) )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to withdraw from your bank account.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", szBigString, "Withdraw", "Back" );
        }
        else if ( ! IsNumeric( money_withdraw ) ) {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to withdraw from your bank account.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", szBigString, "Withdraw", "Back" );
        }
        else if ( strval( money_withdraw ) > 99999999 || strval( money_withdraw ) <= 0 )
        {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to withdraw from your bank account.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", szBigString, "Withdraw", "Back" );
        }
        else if ( strval( money_withdraw ) > GetPlayerBankMoney( playerid ) ) {
            format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to withdraw from your bank account.\n\n"COL_RED"Insufficient balance, therefore withdrawal failed.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", szBigString, "Withdraw", "Back" );
        }
        else
        {
            new iWithdraw = strval( money_withdraw );
            GivePlayerBankMoney( playerid, -iWithdraw );
            GivePlayerCash( playerid, iWithdraw );
            format( szBigString, sizeof( szBigString ), ""COL_GREY"Amount Withdrawn:"COL_WHITE" %s\n"COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( iWithdraw ), cash_format( GetPlayerBankMoney( playerid ) ), cash_format( GetPlayerCash( playerid ) ) );
            ShowPlayerDialog( playerid, DIALOG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Personal Account", szBigString, "Ok", "Back" );
        }
        return 1;
    }
    else if ( dialogid == DIALOG_BANK_DEPOSIT )
	{
	    if ( IsPlayerJailed( playerid ) ) return SendError( playerid, "You cannot use this while you're in jail." );

        if ( response )
        {
        	new
        		money_deposit[ 24 ];

        	format( money_deposit, sizeof( money_deposit ), "%s", inputtext );

            // quick deposite feature
        	if ( strmatch( money_deposit, "MAX" ) || strmatch( money_deposit, "ALL" ) ) {
                format( money_deposit, sizeof( money_deposit ), "%d", GetPlayerCash( playerid ) );
            }

            // validate amount
            if ( !strlen( money_deposit ) ) {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to deposit into your bank account below.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", szBigString, "Deposit", "Back" );
            }
            else if ( ! IsNumeric( money_deposit ) ) {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to deposit into your bank account below.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", szBigString, "Deposit", "Back" );
            }
            else if ( strval( money_deposit ) > GetPlayerCash( playerid ) ) {
                format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to deposit into your bank account below.\n\n"COL_RED"Insufficient balance, therefore deposition failed.\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", szBigString, "Deposit", "Back" );
            }
            else if ( strval( money_deposit ) > 99999999 || strval( money_deposit ) <= 0 )
            {
            	format( szBigString, sizeof( szBigString ), "{FFFFFF}Enter the amount that you are willing to deposit into your bank account below.\n\n"COL_RED"Invalid amount entered!\n\n"COL_GREY"Current Balance:"COL_WHITE" %s", cash_format( GetPlayerBankMoney( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "{FFFFFF}Personal Account", szBigString, "Deposit", "Back" );
            }
            else
            {
                new iDeposit = strval( money_deposit );
                GivePlayerBankMoney( playerid, iDeposit );
                GivePlayerCash( playerid, -iDeposit );
                format( szBigString, sizeof( szBigString ), ""COL_GREY"Amount Deposited:"COL_WHITE" %s\n"COL_GREY"Current Balance:"COL_WHITE" %s\n"COL_GREY"Current Money:{FFFFFF} %s", cash_format( iDeposit ), cash_format( GetPlayerBankMoney( playerid ) ), cash_format( GetPlayerCash( playerid ) ) );
                ShowPlayerDialog( playerid, DIALOG_BANK_INFO, DIALOG_STYLE_MSGBOX, "{FFFFFF}Personal Account", szBigString, "Ok", "Back" );
            }
        }
        else ShowPlayerBankMenuDialog( playerid );
    }
    else if ( ( dialogid == DIALOG_BANK_INFO || dialogid == DIALOG_GANG_BANK_INFO ) && !response )
    {
	    if ( IsPlayerJailed( playerid ) )
	    	return SendError( playerid, "You cannot use this while you're in jail." );

  		return ShowPlayerBankMenuDialog( playerid );
    }
    return 1;
}

hook OnPlayerDisconnect( playerid, reason ) {
    p_BankMoney[ playerid ] = 0;
    return 1;
}

/* ** Callbacks ** */
public OnPlayerBankMoneyChanged( playerid, amount )
{
    // save player bank money on each monetary movement
    if ( IsPlayerLoggedIn( playerid ) )
    {
        mysql_single_query( sprintf( "UPDATE `USERS` SET `BANKMONEY` = %d WHERE `ID` = %d", GetPlayerBankMoney( playerid ), GetPlayerAccountID( playerid ) ) );
    }
    return 1;
}

/* ** Functions ** */
stock GetPlayerBankMoney( playerid ) {
    return p_BankMoney[ playerid ];
}

stock SetPlayerBankMoney( playerid, money ) {
	p_BankMoney[ playerid ] = money;
}

stock GivePlayerBankMoney( playerid, money ) {
	p_BankMoney[ playerid ] += money;
    CallRemoteFunction( "OnPlayerBankMoneyChanged", "dd", playerid, money );
}

stock ShowPlayerBankMenuDialog( playerid )
{
	if ( ! ShowPlayerGangBankMenuDialog( playerid ) ) {
	    return ShowPlayerDialog( playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "{FFFFFF}Account", "Withdraw\nDeposit\nAccount Information", "Select", "Cancel" );
    } else {
        return 1;
    }
}