/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\vip\player_note.pwn
 * Purpose: player note system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Hooks ** */
hook OnPlayerLogin( playerid ) {
    if ( GetPlayerVIPLevel( playerid ) ) {
        format( szBigString, 192, "SELECT `ID` FROM `NOTES` WHERE (`NOTE` LIKE '{FFDC2E}%%' OR `NOTE` LIKE '{CD7F32}%%') AND `USER_ID`=%d AND `DELETED` IS NULL", GetPlayerAccountID( playerid ) );
        mysql_tquery( dbHandle, szBigString, "checkforvipnotes", "d", playerid );
    }
    return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_VIP_NOTE && response )
	{
		SendClientMessageToAdmins( -1, ""COL_PINK"[DONOR NEEDS HELP]"COL_GREY" %s(%d) is requesting help with their VIP asset(s). (/viewnotes)", ReturnPlayerName( playerid ), playerid );
		SendServerMessage( playerid, "All admins online have been informed of your request." );
	}
    return 1;
}

/* ** Player Commands ** */
CMD:notes( playerid, params[ ] ) return cmd_mynotes( playerid, params );
CMD:myvipnotes( playerid, params[ ] ) return cmd_mynotes( playerid, params );
CMD:vipnotes( playerid, params[ ] ) return cmd_mynotes( playerid, params );
CMD:mynotes( playerid, params[ ] )
{
	format( szBigString, 192, "SELECT `NOTE`,`TIME` FROM `NOTES` WHERE (`NOTE` LIKE '{FFDC2E}%%' OR `NOTE` LIKE '{CD7F32}%%') AND `USER_ID`=%d AND `DELETED` IS NULL", p_AccountID[ playerid ] );
	mysql_tquery( dbHandle, szBigString, "readplayervipnotes", "d", playerid );
	return 1;
}

/* ** Admin Commands ** */
CMD:viewnotes( playerid, params[ ] )
{
	new
		pID;

	if ( GetPlayerAdminLevel( playerid ) < 2 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/viewnotes [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else
	{
		format( szNormalString, 96, "SELECT `ID`,`TIME`,`NOTE`,`DELETED` FROM `NOTES` WHERE `USER_ID`=%d AND DELETED IS NULL", p_AccountID[ pID ] );
		mysql_tquery( dbHandle, szNormalString, "readplayernotes", "d", playerid );
	}
	return 1;
}

CMD:addnote( playerid, params[ ] )
{
	new
		pID,
		note[ 72 ]
	;

	if ( GetPlayerAdminLevel( playerid ) < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "us[72]", pID, note ) ) return SendUsage( playerid, "/addnote [PLAYER_ID] [NOTE]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( strlen( note ) < 3 ) return SendError( playerid, "Keep your note's character count within the range of 3 - 72." );
	else
	{
		AddPlayerNote( pID, playerid, note );
 		SendServerMessage( playerid, "You have added a note to %s (Account ID %d)."COL_RED" Do understand that what you add is logged.", ReturnPlayerName( pID ), pID, p_AccountID[ pID ] );
		AddAdminLogLineFormatted( "%s(%d) has added a note to %s(%d)", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( pID ), pID );
	}
	return 1;
}

CMD:removenote( playerid, params[ ] )
{
	new
		note
	;

	if ( GetPlayerAdminLevel( playerid ) < 4 ) return SendError( playerid, ADMIN_COMMAND_REJECT );
	else if ( sscanf( params, "d", note ) ) return SendUsage( playerid, "/removenote [NOTE_ID]" );
	else if ( note < 0 ) return SendError( playerid, "Invalid note ID." );
	else
	{
		if ( p_AdminLevel[ playerid ] > 4 )
		{
	 		format( szNormalString, 64, "SELECT `ID` FROM `NOTES` WHERE `ID`=%d AND `DELETED` IS NULL", note );
			mysql_tquery( dbHandle, szNormalString, "deleteplayernote", "dd", playerid, note );
		}
		else
		{
	 		format( szNormalString, 96, "SELECT `ID` FROM `NOTES` WHERE `ID`=%d AND `ADDED_BY`=%d AND `DELETED` IS NULL", note, p_AccountID[ playerid ] );
			mysql_tquery( dbHandle, szNormalString, "deleteplayernote", "dd", playerid, note );
		}
	}
	return 1;
}

/* ** SQL Threads ** */
thread readplayervipnotes( playerid )
{
	new
		rows = cache_get_row_count( );

    if ( rows )
    {
    	new
    		szDate[ 20 ], szNote[ 72 ];

    	erase( szLargeString );

    	for( new i = 0; i < rows; i++ )
		{
			cache_get_field_content( i, "NOTE", szNote );
			cache_get_field_content( i, "TIME", szDate );

			format( szLargeString, sizeof( szLargeString ), "%s%s\t%s\n", szLargeString, szNote, szDate );
		}

		return ShowPlayerDialog( playerid, DIALOG_VIP_NOTE, DIALOG_STYLE_TABLIST, ""COL_GOLD"My V.I.P Notes", szLargeString, "Call Admin", "Close" );
	}
	return SendError( playerid, "You do not have any V.I.P notes." );
}

thread checkforvipnotes( playerid )
{
	new
		rows = cache_get_row_count( );

	if ( rows ) {
		SendServerMessage( playerid, "You have currently %d V.I.P note(s) that you can redeem. Use "COL_GREY"/mynotes"COL_WHITE".", rows );
		SendClientMessageToAdmins( -1, ""COL_PINK"[VIP HAS NOTES]"COL_GREY" %s(%d) has logged in with %d pending VIP notes. (/viewnotes)", ReturnPlayerName( playerid ), playerid, rows );
	}
	return 1;
}

thread deleteplayernote( playerid, noteid )
{
	new
		rows = cache_get_row_count( );

	if ( rows ) {
		SaveToAdminLog( playerid, noteid, "removed note" );
 	    mysql_single_query( sprintf( "UPDATE `NOTES` SET `DELETED`=%d WHERE `ID`=%d", p_AccountID[ playerid ], noteid ) );
 		SendServerMessage( playerid, "You have removed note id %d. If there are any problems, contact Lorenc/Council.", noteid );
		AddAdminLogLineFormatted( "%s(%d) has deleted note id %d", ReturnPlayerName( playerid ), playerid, noteid );
 		return 1;
	}

 	SendError( playerid, "Couldn't remove note id %d due to it being already deleted or invalid permissions.", noteid );
	return 1;
}

thread readplayernotes( playerid )
{
	new
		rows = cache_get_row_count( );

    if ( rows )
    {
    	new
    		ID,
    		i = 0,
    		Field[ 30 ],
    		szNote[ 72 ]
    	;

    	szHugeString = ""COL_GREY"ID\tTime\t\t\tNote\n" #COL_WHITE;

		while( i < rows )
		{
			cache_get_field_content( i, "ID", Field ), 		 ID = strval( Field );
			cache_get_field_content( i, "NOTE", szNote );
			cache_get_field_content( i, "TIME", Field );

			format( szHugeString, sizeof( szHugeString ), "%s%05d\t%s\t%s\n", szHugeString, ID, Field, szNote );
			i++;
		}

		ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_MSGBOX, "{FFFFFF}Player Notes", szHugeString, "Okay", "" );
		return 1;
	}
	SendError( playerid, "This user does not have any notes." );
	return 1;
}

/* ** Functions ** */
stock AddPlayerNote( playerid, authorid, note[ ] ) {
	mysql_format( dbHandle, szBigString, sizeof( szBigString ), "INSERT INTO `NOTES`(`USER_ID`, `ADDED_BY`, `NOTE`) VALUES (%d,%d,'%e')", p_AccountID[ playerid ], IsPlayerConnected( authorid ) ? p_AccountID[ authorid ] : 1, note );
	mysql_single_query( szBigString );
}