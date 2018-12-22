/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\commands\cmd_twitter.pwn
 * Purpose: twitter feed displayer (requires php script)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined SERVER_TWITTER_FEED_URL
    #endinput
#endif

/* ** Forwards ** */
forward OnTwitterHTTPResponse( index, response_code, data[ ] );

/* ** Commands ** */
CMD:tweets( playerid, params[ ] ) return cmd_twitter( playerid, params );
CMD:twitter( playerid, params[ ] )
{
    SendServerMessage( playerid, "Reading latest tweets from {00CCFF}www.twitter.com/IrresistibleDev{FFFFFF}, please wait!" );
	HTTP( playerid, HTTP_GET, SERVER_TWITTER_FEED_URL, "", "OnTwitterHTTPResponse" );
	return 1;
}

/* ** Callbacks ** */
public OnTwitterHTTPResponse( index, response_code, data[ ] )
{
    if ( response_code == 200 ) {
 		ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{00CCFF}@" # SERVER_TWITTER ""COL_WHITE" - Twitter", data, "Okay", "" );
    } else {
        ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{00CCFF}@" # SERVER_TWITTER ""COL_WHITE" - Twitter", ""COL_WHITE"An error has occurred, try again later.", "Okay", "" );
    }
	return 1;
}
