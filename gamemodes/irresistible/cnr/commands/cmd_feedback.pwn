/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\commands\cmd_feedback.pwn
 * Purpose: create /feedback (or /suggest) about the server
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Commands ** */
CMD:suggest( playerid, params[ ] ) return cmd_feedback( playerid, params );
CMD:feedback( playerid, params[ ] )
{
	return ShowPlayerDialog( playerid, DIALOG_FEEDBACK, DIALOG_STYLE_INPUT, ""COL_GOLD"Server Feedback", ""COL_WHITE"Let us know how you think we can make the server better to play! Impactful feedback is rewarded.\n\n    Be as serious and straight forward as you wish. You can rant if you need to. Be impactful.", "Submit", "Close" );
}

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( ( dialogid == DIALOG_FEEDBACK ) && response )
	{
		if ( ! ( 10 < strlen( inputtext ) <= 512 ) )
		{
			SendError( playerid, "Your feedback must be between 10 and 512 characters long." );
			return ShowPlayerDialog( playerid, DIALOG_FEEDBACK, DIALOG_STYLE_INPUT, ""COL_GOLD"Server Feedback", ""COL_WHITE"Let us know how you think we can make the server better to play! Impactful feedback is rewarded.\n\n    Be as serious and straight forward as you wish. You can rant if you need to. Be impactful.\n\n"COL_RED"Your feedback must be between 10 and 512 characters long.", "Submit", "Close" );
		}

		// insert into database
		mysql_format( dbHandle, szLargeString, sizeof( szLargeString ), "INSERT INTO `FEEDBACK` (`USER_ID`, `FEEDBACK`) VALUES (%d, '%e')", p_AccountID[ playerid ], inputtext );
		mysql_single_query( szLargeString );

		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, ""COL_GOLD"Server Feedback", ""COL_GOLD"Thank you for your feedback!"COL_WHITE" If it can make a positive impact on the server then you will be rewarded.\n\nYou can speak as freely as you want. Be vulgar, serious if you need to. It's okay as long as it's constructive.", "Close", "" );
	}
    return 1;
}