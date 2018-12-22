/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\auth\login.pwn
 * Purpose: module associated with login componenets
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */

/* ** Variables ** */

/* ** Hooks ** */
hook OnPlayerText( playerid, text[ ] )
{
	if ( GetPlayerScore( playerid ) < 10 )
		return SendServerMessage( playerid, "You need at least 10 score to talk. "COL_GREY"Use /ask or /report to talk to an admin in the meanwhile." ), Y_HOOKS_BREAK_RETURN_1;

	if ( ! IsPlayerLoggedIn( playerid ) )
		return SendError( playerid, "You must be logged in to talk." ), Y_HOOKS_BREAK_RETURN_1;

	return Y_HOOKS_CONTINUE_RETURN_1;
}

/* ** Functions ** */
