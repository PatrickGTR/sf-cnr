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
	if ( ! IsPlayerNPC( playerid ) ) {

	}
	return Y_HOOKS_CONTINUE_RETURN_1;
}

/* ** Functions ** */
