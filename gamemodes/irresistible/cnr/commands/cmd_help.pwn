/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\commands\cmd_help.pwn
 * Purpose: help system for the server (requires threads to be made via UCP)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Error Checking ** */
#if !defined SERVER_HELP_API_URL
    #endinput
#endif

/* ** Forwards ** */
forward OnHelpHTTPResponse( index, response_code, data[ ] );

/* ** Commands ** */
CMD:help( playerid, params[ ] ) {
	return ShowPlayerDialog( playerid, DIALOG_HELP, DIALOG_STYLE_LIST, "{FFFFFF}Help", "Server Information\nFeatures\nHelp\nF.A.Q.\nGuides\nTips n' Tricks", "Okay", "" ), 1;
}

CMD:features( playerid, params[ ] ) {
	return DisplayFeatures( playerid );
}

stock DisplayFeatures( playerid )
{
	SetPVarInt( playerid, "help_category", 1 );
    mysql_function_query( dbHandle, "SELECT `SUBJECT`,`ID`,`CATEGORY` FROM `HELP` WHERE `CATEGORY`=1 ORDER BY `SUBJECT` ASC", true, "OnFetchCategoryResponse", "dd", playerid, 1 );
	return 1;
}

CMD:faq( playerid, params[ ] ) {
	SetPVarInt( playerid, "help_category", 3 );
    mysql_function_query( dbHandle, "SELECT `SUBJECT`,`ID`,`CATEGORY` FROM `HELP` WHERE `CATEGORY`=3 ORDER BY `SUBJECT` ASC", true, "OnFetchCategoryResponse", "dd", playerid, 3 );
   	return 1;
}

CMD:tips( playerid, params[ ] ) {
	SetPVarInt( playerid, "help_category", 5 );
    mysql_function_query( dbHandle, "SELECT `SUBJECT`,`ID`,`CATEGORY` FROM `HELP` WHERE `CATEGORY`=5 ORDER BY `SUBJECT` ASC", true, "OnFetchCategoryResponse", "dd", playerid, 5 );
   	return 1;
}

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_HELP && response )
	{
		SetPVarInt( playerid, "help_category", listitem );
	    mysql_function_query( dbHandle, sprintf( "SELECT `SUBJECT`,`ID`,`CATEGORY` FROM `HELP` WHERE `CATEGORY`=%d ORDER BY `SUBJECT` ASC", listitem ), true, "OnFetchCategoryResponse", "dd", playerid, listitem );
	}
	else if ( dialogid == DIALOG_HELP_CATEGORY )
    {
		if ( ! response )
			return cmd_help( playerid, "" );

		if ( listitem >= 64 )
			return SendError( playerid, "Unable to process request, contact Lorenc in regards to this." );

		new
			digits[ 64 ];

		GetPVarString( playerid, "help_ids", szBigString, sizeof( szBigString ) );
		sscanf( szBigString, "a<i>[64]", digits );

	    //format( szNormalString, 96, "SELECT * FROM `HELP` WHERE `CATEGORY`=%d AND `ID`=%d", GetPVarInt( playerid, "help_category" ), digits[ listitem ] );
	    //mysql_function_query( dbHandle, szNormalString, true, "OnFetchThreadData", "ddd", playerid, GetPVarInt( playerid, "help_category" ), digits[ listitem ] );

		HTTP( playerid, HTTP_GET, sprintf( SERVER_HELP_API_URL # "/%d", digits[ listitem ] ), "", "OnHelpHTTPResponse" );
	}
	else if ( dialogid == DIALOG_HELP_THREAD && ! response )
    {
	    mysql_function_query( dbHandle, sprintf( "SELECT `SUBJECT`,`ID`,`CATEGORY` FROM `HELP` WHERE `CATEGORY`=%d ORDER BY `SUBJECT` ASC", GetPVarInt( playerid, "help_category" ) ), true, "OnFetchCategoryResponse", "dd", playerid, GetPVarInt( playerid, "help_category" ) );
        return 1;
    }
	else if ( dialogid == DIALOG_HELP_BACK && !response )
    {
        return cmd_help( playerid, "" );
    }
    return 1;
}

/* ** SQL Threads ** */
thread OnFetchCategoryResponse( playerid, category )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		new
			szCategory[ 64 ];

		erase( szLargeString );
		erase( szBigString );

		for ( new i = 0; i < rows; i ++ )
		{
			cache_get_field_content( i, "SUBJECT", szCategory );
			format( szLargeString, sizeof( szLargeString ), "%s%s\n", szLargeString, szCategory );

			cache_get_field_content( i, "ID", szCategory );
			format( szBigString, sizeof( szBigString ), "%s %d", szBigString, strval( szCategory ) );
		}

		SetPVarString( playerid, "help_ids", szBigString );
		ShowPlayerDialog( playerid, DIALOG_HELP_CATEGORY, DIALOG_STYLE_LIST, "{FFFFFF}Help Topics", szLargeString, "Select", "Back" );
	}
	else
    {
        ShowPlayerDialog( playerid, DIALOG_HELP_BACK, DIALOG_STYLE_LIST, "{FFFFFF}Help Topics", "{FF0000}There are no threads available.", "Close", "Back" );
    }
	return 1;
}

/*thread OnFetchThreadData( playerid, category, thread )
{
	new
		rows, fields;

	cache_get_data( rows, fields );
	if ( rows )
	{
		static
	        RegEx: rCIP,
			szSubject[ 64 ],
			szContent[ 2048 ]
		;

		cache_get_field_content( 0, "CONTENT", szContent, dbHandle, sizeof( szContent ) );
		cache_get_field_content( 0, "SUBJECT", szSubject );

		strins( szSubject, "{FFFFFF}", 0 );
		strins( szContent, "{FFFFFF}", 0 );


	    if ( !rCIP )
	  		rCIP = regex_build( "(?i)<[^>]*>" );

		regex_replace_exid( szContent, rCIP, "&nbsp;", szContent, sizeof( szContent ) );
		strreplace( szContent, "&nbsp;", "" );
		strreplace( szContent, "&amp;", "" );
		strreplace( szContent, "&#39;", "" );

		ShowPlayerDialog( playerid, DIALOG_HELP_THREAD, DIALOG_STYLE_MSGBOX, szSubject, szContent, "Close", "Back" );
	}
	else ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_LIST, "{FFFFFF}Help Topics", "{FFFFFF}An error has occurred. Try again later.", "Okay", "" );
	return 1;
}*/

/* ** Callbacks ** */
public OnHelpHTTPResponse( index, response_code, data[ ] )
{
    if ( response_code == 200 ) {
		ShowPlayerDialog( index, DIALOG_HELP_THREAD, DIALOG_STYLE_MSGBOX, "{FFFFFF}Help Topics", data, "Close", "Back" );
    } else {
		ShowPlayerDialog( index, DIALOG_NULL, DIALOG_STYLE_LIST, "{FFFFFF}Help Topics", "{FFFFFF}An error has occurred. Try again later.", "Okay", "" );
    }
	return 1;
}