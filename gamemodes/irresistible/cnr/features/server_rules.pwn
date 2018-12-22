/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\server_rules.pwn
 * Purpose: server rules implementation (/rules) that scans URL
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

#if defined SERVER_RULES_URL

	/* ** Variables ** */
	static stock szRules				[ 3300 ];

	/* ** Forwards ** */
	public OnRulesHTTPResponse( index, response_code, data[ ] );

	/* ** Hooks ** */
	hook OnScriptInit( ) {
		HTTP( 0, HTTP_GET, SERVER_RULES_URL, "", "OnRulesHTTPResponse" );
		return 1;
	}

	/* ** Functions ** */
	public OnRulesHTTPResponse( index, response_code, data[ ] ) {
		if ( response_code == 200 ) {
			printf( "[RULES] Rules have been updated! Character Size: %d", strlen( data ) );
			strcpy( szRules, data );
		}
		return 1;
	}

	/* ** Commands ** */
	CMD:rules( playerid, params[ ] ) {
		return ShowPlayerRules( playerid );
	}

#endif

/* ** Functions ** */
stock ShowPlayerRules( playerid )
{
	#if !defined SERVER_RULES_URL
		#pragma unused playerid
		return 1;
	#else
		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Rules", szRules, "Okay", "" ), 1;
	#endif
}