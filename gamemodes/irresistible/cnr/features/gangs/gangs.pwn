/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: gangs.inc
 * Purpose: gang system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_GANGS                   ( MAX_PLAYERS ) // safest is MAX_PLAYERS
#define INVALID_GANG_ID 			( -1 )

#define MAX_COLEADERS				( 3 )

/* ** Macros ** */
#define IsGangPrivate(%0)			( g_gangData[ %0 ] [ E_INVITE_ONLY ] )
#define GetGangSqlID(%0)			( g_gangData[ %0 ] [ E_SQL_ID ] )
#define GetPlayerGang(%0) 			( p_GangID[ %0 ] )
#define IsValidGangID(%0)			( 0 <= %0 < MAX_GANGS && Iter_Contains( gangs, %0 ) )
#define IsPlayerInPlayerGang(%0,%1)	( p_Class[ %0 ] == p_Class[ %1 ] && p_Class[ %0 ] == CLASS_CIVILIAN && p_GangID[ %0 ] == p_GangID[ %1 ] && p_GangID[ %0 ] != INVALID_GANG_ID )

/* ** Variables ** */
enum e_gang_data
{
	E_SQL_ID, 						E_NAME[ 30 ], 					E_LEADER,
	E_COLOR,						E_SOFT_DELETE_TS,

	E_BANK, 						E_KILLS, 						E_DEATHS,
	E_SCORE, 						E_RESPECT,

	E_COLEADER[ MAX_COLEADERS ], 	bool: E_INVITE_ONLY, 			E_JOIN_MSG[ 96 ],

	bool: E_HAS_FACILITY
};

enum E_GANG_LEAVE_REASON
{
	GANG_LEAVE_QUIT,
	GANG_LEAVE_KICK,
	GANG_LEAVE_UNKNOWN
};

new
	g_gangColors[ ] = { 0x99FF00FF, 0x00CC00FF, 0x009999FF, 0x0033CCFF, 0x330099FF, 0x660099FF, 0xCC0099FF },

	g_gangData						[ MAX_GANGS ] [ e_gang_data ],
	g_sortedGangData 				[ MAX_GANGS ] [ e_gang_data ], // used for sorting only
	p_GangID                        [ MAX_PLAYERS ],

	bool: p_gangInvited           	[ MAX_PLAYERS ] [ MAX_GANGS ],
	p_gangInviteTick                [ MAX_PLAYERS ],

	Iterator:gangs<MAX_GANGS>
;

/* ** Forwards ** */
forward OnPlayerLeaveGang( playerid, gangid, reason );
forward ZoneTimer( );

/* ** Hooks ** */
/*hook OnGameModeInit( )
{
	#if !defined DEBUG_MODE
		// Remove inactive gang members
		// mysql_single_query( "UPDATE `USERS` SET `GANG_ID`=-1 WHERE UNIX_TIMESTAMP()-`USERS`.`LASTLOGGED` > 1209600" );

		// Remove gangs with a non existant gang leader / unmatched player gang id to gang leader id (***broken query***)
		// mysql_single_query( "DELETE g FROM GANGS g LEFT JOIN USERS u ON g.LEADER = u.ID WHERE (u.GANG_ID != g.ID OR u.ID IS NULL) AND g.LEADER >= 0" );
	#endif
	return 1;
}*/

hook OnServerUpdate( )
{
	// Soft delete gang
	foreach (new gangid : gangs) if ( g_gangData[ gangid ] [ E_SOFT_DELETE_TS ] != 0 && g_iTime > g_gangData[ gangid ] [ E_SOFT_DELETE_TS ] )
	{
		new
			members = GetOnlineGangMembers( gangid );

		if ( members <= 0 )
		{
			new
				cur = gangid;

			printf("Removed Gang From Cache Gang Id %d Since No Ppl", g_gangData[ gangid ] [ E_SQL_ID ] );
			DestroyGang( gangid, true, .iter_remove = false );
			Iter_SafeRemove( gangs, cur, gangid );
		}
		else g_gangData[ gangid ] [ E_SOFT_DELETE_TS ] = 0;
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_GANG_COLOR && response )
	{
	    if ( listitem != 0 )
	    {
	        listitem -= 1; // So it starts from 0...
			g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ] = g_gangColors[ listitem ];
			SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has changed the gang color to %s", ReturnPlayerName( playerid ), playerid, ReturnGangNameColor( listitem ) );
	      	SetGangColorsToGang( p_GangID[ playerid ] );
		}
		else {
			if ( p_VIPLevel[ playerid ] < VIP_REGULAR ) return SendError( playerid, "You are not a V.I.P, to become one visit "COL_GREY"donate.sfcnr.com" );
			ShowPlayerDialog( playerid, DIALOG_GANG_COLOR_INPUT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Colors", "{FFFFFF}Write a hexidecimal color within the textbox", "Submit", "Cancel" );
		}
	}
	else if ( dialogid == DIALOG_GANG_COLOR_INPUT && response )
	{
		if ( !strlen( inputtext ) || !isHex( inputtext ) )
		    return ShowPlayerDialog( playerid, DIALOG_GANG_COLOR_INPUT, DIALOG_STYLE_INPUT, "{FFFFFF}Gang Colors", "{FFFFFF}Write a hexidecimal color within the textbox\n\n{ff0000}Invalid HEX color.", "Submit", "Cancel" );

		new gangid = p_GangID[ playerid ];
		new hex_to_int = HexToInt( inputtext );

		g_gangData[ gangid ] [ E_COLOR ] = setAlpha( hex_to_int, 0xFF );

		SendClientMessageToGang( gangid, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has changed the gang color to %06x", ReturnPlayerName( playerid ), playerid, hex_to_int >>> 8 );
	 	SetGangColorsToGang( gangid );
	}
	else if ( dialogid == DIALOG_GANG_LIST && response )
	{
		new
			x = 0;

		for ( new g = 0; g < sizeof( g_sortedGangData ); g ++ ) if ( g_sortedGangData[ g ] [ E_SQL_ID ] != 0 )
		{
	       	if ( x == listitem )
	      	{
	      		new curr_gang = p_GangID[ playerid ];
	      		new curr_gang_sql = 0;

	      		if ( Iter_Contains( gangs, curr_gang ) )
	      			curr_gang_sql = g_gangData[ curr_gang ] [ E_SQL_ID ];

	      		SetPVarInt( playerid, "viewing_gang_sql", g_sortedGangData[ g ] [ E_SQL_ID ] );
	      		ShowPlayerDialog( playerid, DIALOG_GANG_LIST_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Gang Options", sprintf( "%sJoin Gang\nView Statistics\nView Gang Members", curr_gang_sql != g_sortedGangData[ g ] [ E_SQL_ID ] && ! g_sortedGangData[ g ] [ E_INVITE_ONLY ] ? ( COL_WHITE ) : ( COL_BLACK ) ), "Select", "Back" );
				break;
	   		}
	      	x ++;
		}
	}
	else if ( dialogid == DIALOG_GANG_LIST_OPTIONS )
	{
		if ( !response )
			return cmd_gangs( playerid, "" );

		new gang_sql = GetPVarInt( playerid, "viewing_gang_sql" );
		new g;

		// search sql, just incase someone searchs the gangs and doesnt find what they want
		foreach (g : gangs) if ( g_gangData[ g ] [ E_SQL_ID ] == gang_sql ) {
			break;
		}

		if ( ! ( 0 <= g < MAX_GANGS ) || ! Iter_Contains( gangs, g ) )
			return SendError( playerid, "Unable to discover gang information as it no longer is loaded, please try again. (0x7D)" );

		switch( listitem )
		{
			case 0: // Join gang
			{
				if ( p_Class[ playerid ] != CLASS_CIVILIAN ) {
					SendError( playerid, "You must be a civilian to switch gangs." );
				} else if ( p_GangID[ playerid ] == g ) {
					SendError( playerid, "You are already in this gang." );
				} else if ( IsGangPrivate( g ) ) {
					SendError( playerid, "You can no longer join this gang as it is private." );
				} else if ( ! SetPlayerGang( playerid, g ) ) {
					SendError( playerid, "You can no longer join this gang." );
				}
				ShowPlayerDialog( playerid, DIALOG_GANG_LIST_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Gang Options", sprintf( "%sJoin Gang\nView Statistics\nView Gang Members", p_GangID[ playerid ] != g && ! g_gangData[ g ] [ E_INVITE_ONLY ] ? ( COL_WHITE ) : ( COL_BLACK ) ), "Select", "Back" );
			}

			case 1: // View statistics
			{
				new iPlayers = GetOnlineGangMembers( g );
				SetPVarInt( playerid, "gang_members_id", g );
				format( szLargeString, 350, ""COL_GREY"Gang ID:"COL_WHITE" %d\n"COL_GREY"Online Members:"COL_WHITE" %d\n"COL_GREY"Score:"COL_WHITE" %d\n"COL_GREY"Kills:"COL_WHITE" %d\n"COL_GREY"Deaths:"COL_WHITE" %d\n"COL_GREY"K/D Ratio:"COL_WHITE" %0.2f\n", g_gangData[ g ] [ E_SQL_ID ], iPlayers, g_gangData[ g ] [ E_SCORE ], g_gangData[ g ] [ E_KILLS ], g_gangData[ g ] [ E_DEATHS ], floatdiv( g_gangData[ g ] [ E_KILLS ], g_gangData[ g ] [ E_DEATHS ] ) );
				format( szLargeString, 350, "%s"COL_GREY"Bank:"COL_WHITE" %s\n"COL_GREY"Zones Captured:"COL_WHITE" %d", szLargeString, cash_format( g_gangData[ g ] [ E_BANK ] ), GetGangCapturedTurfs( g ) );
				ShowPlayerDialog( playerid, DIALOG_GANG_LIST_RESPONSE, DIALOG_STYLE_MSGBOX, "{FFFFFF}Gang Statistics", szLargeString, "Close", "Back" );
			}

			case 2:
			{
				// View gang members
				mysql_tquery( dbHandle,
					sprintf( "SELECT `NAME`,`ONLINE` FROM `USERS` WHERE `GANG_ID`=%d ORDER BY `ONLINE` DESC LIMIT 20 OFFSET 0", g_gangData[ g ] [ E_SQL_ID ] ),
					"OnListGangMembers", "ddd", playerid, g, 0
				);
			}
		}
		return 1;
	}
	else if ( dialogid == DIALOG_GANG_LIST_RESPONSE )
	{
		new g = GetPVarInt( playerid, "gang_members_id" );

		if ( ! Iter_Contains( gangs, g ) )
			return SendError( playerid, "Could not find gang. Try again." );

		return ShowPlayerDialog( playerid, DIALOG_GANG_LIST_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Gang Options", sprintf( "%sJoin Gang\nView Statistics\nView Gang Members", p_GangID[ playerid ] != g && ! g_gangData[ g ] [ E_INVITE_ONLY ] ? ( COL_WHITE ) : ( COL_BLACK ) ), "Select", "Back" );
	}
	else if ( dialogid == DIALOG_GANG_LIST_MEMBERS )
	{
		new g = GetPVarInt( playerid, "gang_members_id" );
		new members_shown = GetPVarInt( playerid, "gang_members_results" );
		new page = GetPVarInt( playerid, "gang_members_page" );

		if ( ! Iter_Contains( gangs, g ) )
			return SendError( playerid, "Could not find gang. Try again." );

		if ( ! response && page == 0 )
			return ShowPlayerDialog( playerid, DIALOG_GANG_LIST_OPTIONS, DIALOG_STYLE_LIST, "{FFFFFF}Gang Options", sprintf( "%sJoin Gang\nView Statistics\nView Gang Members", p_GangID[ playerid ] != g && ! g_gangData[ g ] [ E_INVITE_ONLY ] ? ( COL_WHITE ) : ( COL_BLACK ) ), "Select", "Back" );

		if ( members_shown < 20 && response )
			return 1;

		// if response, add a page, otherwise previous
		page += response ? 1 : -1;

		// find page result
		mysql_tquery( dbHandle,
			sprintf( "SELECT `NAME`,`ONLINE` FROM `USERS` WHERE `GANG_ID`=%d ORDER BY `ONLINE` DESC LIMIT 20 OFFSET %d", g_gangData[ g ] [ E_SQL_ID ], page * 20 ),
			"OnListGangMembers", "ddd", playerid, g, page
		);
		return 1;
	}
	return 1;
}

/* ** Callbacks ** */
public OnPlayerLeaveGang( playerid, gangid, reason )
{
	switch( reason )
	{
	    case GANG_LEAVE_KICK:
	    	SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has left the gang (KICKED)", ReturnPlayerName( playerid ), playerid );

	    case GANG_LEAVE_QUIT:
	    	SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has left the gang (LEFT)", ReturnPlayerName( playerid ), playerid );

	    case GANG_LEAVE_UNKNOWN:
	    	SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has left the gang (UNKNOWN)", ReturnPlayerName( playerid ), playerid );
	}
	return 1;
}

/* ** Commands ** */
CMD:clans( playerid, params[ ] )
{
	mysql_function_query( dbHandle, "SELECT * FROM `GANGS` WHERE `CLAN_TAG` IS NOT NULL ORDER BY `SCORE` DESC", true, "OnListClans", "d", playerid );
	return 1;
}

CMD:gangs( playerid, params[ ] )
{
	if ( !Iter_Count(gangs) )
		return SendError( playerid, "There are no gangs to list." );

	// store current sort into gangs & sort by respect
	g_sortedGangData = g_gangData;
	SortDeepArray( g_sortedGangData, E_RESPECT, .order = SORT_DESC );

	// create dialog
	szHugeString = ""COL_WHITE"Gang\t"COL_WHITE"Respect\n";

	for ( new g = 0; g < sizeof( g_sortedGangData ); g ++ ) if ( g_sortedGangData[ g ] [ E_SQL_ID ] != 0 ) {
		format( szHugeString, sizeof( szHugeString ), "%s{%06x}%s\t%d\n", szHugeString, g_sortedGangData[ g ] [ E_COLOR ] >>> 8, g_sortedGangData[ g ] [ E_NAME ], g_sortedGangData[ g ] [ E_RESPECT ] );
	}
	return ShowPlayerDialog( playerid, DIALOG_GANG_LIST, DIALOG_STYLE_TABLIST_HEADERS, "Gangs List", szHugeString, "Select", "Cancel" );
}

CMD:getgang( playerid, params[ ] )
{
	new
		pID
	;

	if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/getgang [PLAYER_ID]" );
	else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
	else if ( p_PlayerLogged{ pID } == false ) return SendError( playerid, "This player is not logged in." );
	else
	{
		if (p_GangID[ pID ] == INVALID_GANG_ID) {
			SendServerMessage( playerid, ""COL_GREY"%s(%d) is not in a gang.", ReturnPlayerName( pID ), pID );
		}
		else {
			SendServerMessage( playerid, ""COL_GREY"%s(%d) is in {%06x}%s", ReturnPlayerName( pID ), pID, g_gangData[ p_GangID[ pID ] ] [ E_COLOR ] >>> 8, g_gangData[ p_GangID[ pID ] ][ E_NAME ] );
		}
	}
	return 1;
}

CMD:gang( playerid, params[ ] )
{
	if ( p_Class[ playerid ] != CLASS_CIVILIAN )
		return SendError( playerid, "This is restricted to civilians only." );

	if ( ! strcmp( params, "ranks", false, 5 ) )
	{
		if ( p_GangID[ playerid ] == INVALID_GANG_ID )
			return SendError( playerid, "You are not inside a gang." );

		Ranks_ShowPlayerRanks( playerid );
		return 1;
	}
	else if ( ! strcmp( params, "addrank", false, 7 ) )
	{
		if ( p_GangID[ playerid ] == INVALID_GANG_ID )
			return SendError( playerid, "You are not inside a gang." );

		if ( ! IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) )
			return SendError( playerid, "You are not the gang leader." );

		new
			rank[ 32 ];

		if ( p_GangID[ playerid ] == INVALID_GANG_ID )
			return SendError( playerid, "You are not inside a gang." );

		if ( ! IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) )
			return SendError( playerid, "You are not the gang leader." );

		if ( sscanf( params[ 8 ], "s[32]", rank ) )
			return SendUsage( playerid, "/gang addrank [RANK_NAME]" );

		if ( ! Ranks_IsNameAlreadyUsed( rank ) )
			return SendError( playerid, "This rank name is already been created." );

		format( szLargeString, sizeof( szLargeString ), "INSERT INTO `GANG_RANKS` (`GANG_ID`,`RANK_NAME`,`COLOR`) VALUE (%d,'%s',-1061109505)", g_gangData[ p_GangID[ playerid ] ][ E_SQL_ID ], mysql_escape( rank ) );
		mysql_query( dbHandle, szLargeString );

		SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has created a new rank \"%s\".", ReturnPlayerName( playerid ), playerid, rank );
		return 1;
	}
	else if ( ! strcmp( params, "setrank", false, 7 ) )
	{
		new
		    pID
		;

		if ( p_GangID[ playerid ] == INVALID_GANG_ID )
			return SendError( playerid, "You are not inside a gang." );

		if ( ! IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) )
			return SendError( playerid, "You are not the gang leader." );

		if ( sscanf( params[ 8 ], "u", pID ) )
			return SendUsage( playerid, "/gang setrank [PLAYER_ID]" );

		if ( ! IsPlayerConnected( pID ) || IsPlayerNPC( pID ) )
			return SendError( playerid, "Invalid Player ID." );

		if ( p_GangID[ pID ] != p_GangID[ playerid ] )
			return SendError( playerid, "This player isn't in your gang." );

		SetPVarInt( playerid, "otherid_rank", pID );

		Ranks_ShowPlayerRanks( playerid, true );
		return 1;
	}
	else if ( ! strcmp( params, "offlinekick", false, 11 ) )
	{
		new
			iGang = p_GangID[ playerid ],
			p_Name[ MAX_PLAYER_NAME ];

		if ( ! IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) )
			return SendError( playerid, "You are not the gang leader." );

		if ( sscanf( params[ 12 ], "s[24]", p_Name ) )
			return SendUsage( playerid, "/gang offlinekick [PLAYER_NAME]" );

		trimString( p_Name );

		mysql_format( dbHandle, szNormalString, 128, "SELECT `ID`, `NAME`, `GANG_ID` FROM `USERS` WHERE `NAME`='%e' AND `GANG_ID`=%d", p_Name, g_gangData[ iGang ][ E_SQL_ID ] );
		mysql_tquery( dbHandle, szNormalString, "OnGangKickOffline", "dd", playerid, g_gangData[ iGang ][ E_SQL_ID ] );
		return 1;
	}
	else if ( !strcmp( params, "turfs", false, 5 ) )
	{
		return Turf_ShowGangOwners( playerid );
	}
	else if ( !strcmp( params, "leader", false, 6 ) )
	{
		new
		    pID
		;
	    if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside a gang." );
		else if ( !IsPlayerGangLeader( playerid, p_GangID[ playerid ], .only_leader = 1 ) ) return SendError( playerid, "You are not the gang leader." );
		else if ( sscanf( params[ 7 ], "u", pID ) ) return SendUsage( playerid, "/gang leader [PLAYER_ID]" );
		else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
		else if ( pID == playerid ) return SendError( playerid, "You cannot apply this action to yourself." );
		else if ( p_GangID[ pID ] != p_GangID[ playerid ] ) return SendError( playerid, "This player isn't in your gang." );
		else
		{
	        g_gangData[ p_GangID[ playerid ] ] [ E_LEADER ] = p_AccountID[ pID ];
			SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) is the new gang leader.", ReturnPlayerName( pID ), pID );
            SaveGangData( p_GangID[ playerid ] );
		}
		return 1;
	}
	else if ( !strcmp( params, "coleader", false, 8 ) )
	{
		new
			gangid = p_GangID[ playerid ], pID;

	    if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside a gang." );
		else if ( !IsPlayerGangLeader( playerid, p_GangID[ playerid ], .only_leader = 1 ) ) return SendError( playerid, "You are not the gang leader." );
		else if ( sscanf( params[ 9 ], "u", pID ) ) return SendUsage( playerid, "/gang coleader [PLAYER_ID]" );
		else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
		else if ( pID == playerid ) return SendError( playerid, "You cannot apply this action to yourself." );
		else if ( p_GangID[ pID ] != p_GangID[ playerid ] ) return SendError( playerid, "This player isn't in your gang." );
		else
		{
			new
				slotid = -1;

			for ( new i = 0; i < MAX_COLEADERS; i ++ )
			{
				// check for dupes
				if ( g_gangData[ gangid ] [ E_COLEADER ] [ i ] == p_AccountID[ pID ] )
					return SendError( playerid, "This player is already a coleader of your gang." );

				// find slot
				if ( ! g_gangData[ gangid ] [ E_COLEADER ] [ i ] ) {
					slotid = i;
					break;
				}
			}

			if ( slotid != -1 )
			{
		        g_gangData[ gangid ] [ E_COLEADER ] [ slotid ] = p_AccountID[ pID ];
				SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) is the #%d co-leader.", ReturnPlayerName( pID ), pID, slotid + 1 );
				mysql_single_query( sprintf( "INSERT INTO `GANG_COLEADERS` (`GANG_ID`,`USER_ID`) VALUES (%d, %d)", g_gangData[ gangid ] [ E_SQL_ID ], p_AccountID[ pID ] ) );
			}
			else SendError( playerid, "There can only be a maximum of %d gang co-leaders. Kick one of them first.", MAX_COLEADERS );
		}
		return 1;
	}
	else if ( !strcmp( params, "kick", false, 4 ) )
	{
		new
		    pID
		;

		if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside a gang." );
		else if ( !IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) ) return SendError( playerid, "You are not the gang leader." );
		else if ( sscanf( params[ 5 ], "u", pID ) ) return SendUsage( playerid, "/gang kick [PLAYER_ID]" );
		else if ( !IsPlayerConnected( pID ) || IsPlayerNPC( pID ) ) return SendError( playerid, "Invalid Player ID." );
		else if ( p_GangID[ pID ] != p_GangID[ playerid ] ) return SendError( playerid, "This player isn't in your gang." );
		else if ( IsPlayerGangLeader( pID, p_GangID[ playerid ], .only_leader = 1 ) ) return SendError( playerid, "This person is the gang leader." );
		else
		{
			RemovePlayerFromGang( pID, GANG_LEAVE_KICK, playerid );
		}
		return 1;
	}
	else if ( !strcmp( params, "name", false, 4 ) )
	{
		new
		    szName[ 30 ]
		;

		if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside a gang." );
		else if ( !IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) ) return SendError( playerid, "You are not the gang leader." );
		else if ( sscanf( params[ 5 ], "s[30]", szName ) ) return SendUsage( playerid, "/gang name [GANG_NAME]" );
		else if ( textContainsIP( szName ) || textContainsBadTextdrawLetters( szName ) ) return SendError( playerid, "Invalid Gang Name." );
		else if ( gangNameExists( szName ) ) return SendError( playerid, "This gang already exists, try another name." );
		else
		{
			trimString( szName );
			format( g_gangData[ p_GangID[ playerid ] ] [ E_NAME ], 30, "%s", szName );
			SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has changed the gang's name to {%06x}%s"COL_WHITE".", ReturnPlayerName( playerid ), playerid, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ] >>> 8, szName );
            SaveGangData( p_GangID[ playerid ] );
		}
		return 1;
	}
	else if ( !strcmp( params, "color", false, 5 ) )
	{
		if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside a gang." );
		if ( !IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) ) return SendError( playerid, "You are not the gang leader." );

		return ShowPlayerDialog( playerid, DIALOG_GANG_COLOR, DIALOG_STYLE_LIST, "Gang Colors", ""COL_GREY"Custom Hex Code "COL_GOLD"[V.I.P]\n{99FF00}Yellow Green\n{00CC00}Green\n{009999}Blue Green\n{0033CC}Blue\n{330099}Blue Violet\n{660099}Violet\n{CC0099}Red Violet", "Select", "Cancel" );
	}
	else if ( !strcmp( params, "create", false, 5 ) )
	{
		new
		    szName[ 30 ]
		;

		if ( sscanf( params[ 6 ], "s[30]", szName ) ) return SendUsage( playerid, "/gang create [GANG_NAME]" );
		else if ( p_GangID[ playerid ] != INVALID_GANG_ID ) return SendError( playerid, "To make a gang, you must leave your current gang with /gang leave" );
		else if ( textContainsIP( szName ) || textContainsBadTextdrawLetters( szName ) ) return SendError( playerid, "Invalid Gang Name." );
		else if ( gangNameExists( szName ) ) return SendError( playerid, "This gang already exists, try another name." );
		else
		{
			new
				handle = CreateGang( .gang_name = szName, .leader = p_AccountID[ playerid ], .gang_color = g_gangColors[ random( sizeof( g_gangColors ) ) ] );

			if ( handle != INVALID_GANG_ID )
			{
			    p_GangID[ playerid ] = handle; // set it anyway here just incase of cache taking a bit

			    if ( p_WantedLevel[ playerid ] == 0 && p_AdminOnDuty{ playerid } == false )
			    	SetPlayerColor( playerid, g_gangData[ handle ] [ E_COLOR ] );

				mysql_single_query( sprintf( "UPDATE `USERS` SET `GANG_ID`=%d WHERE `ID`=%d", g_gangData[ handle ] [ E_SQL_ID ], p_AccountID[ playerid ] ) );
			    SendClientMessageToGang( handle, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} You have created the gang: %s (%d)", szName, g_gangData[ handle ] [ E_SQL_ID ] );
			}
			else SendError( playerid, "There are no available slots to create a gang." );
		}
		return 1;
	}
	else if ( !strcmp( params, "joinmsg", false, 7 ) )
	{
		new
			gangid = p_GangID[ playerid ];

		if ( gangid == INVALID_GANG_ID ) return SendError( playerid, "You are not inside any gang." );
		if ( !IsPlayerGangLeader( playerid, gangid ) ) return SendError( playerid, "You are not the gang leader." );

		if ( sscanf( params[ 8 ], "s[96]", g_gangData[ gangid ] [ E_JOIN_MSG ] ) )
		{
			mysql_single_query( sprintf( "UPDATE `GANGS` SET `JOIN_MSG`=NULL WHERE `ID`=%d", g_gangData[ gangid ] [ E_SQL_ID ] ) );
			SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) removed the gang's join message.", ReturnPlayerName( playerid ), playerid );
		}
		else
		{
			format( szBigString, sizeof( szBigString ), "UPDATE `GANGS` SET `JOIN_MSG`='%s' WHERE `ID`=%d", mysql_escape( g_gangData[ gangid ] [ E_JOIN_MSG ] ), g_gangData[ gangid ] [ E_SQL_ID ] );
			mysql_single_query( szBigString );

			SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) set the gang's join message:", ReturnPlayerName( playerid ), playerid );
			SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]"COL_GREY" %s", g_gangData[ gangid ] [ E_JOIN_MSG ] );
		}
		return 1;
	}
	else if ( !strcmp( params, "join", false, 4 ) )
	{
		new
		    gID
		;
		if ( sscanf( params[ 5 ], "d", gID ) ) return SendUsage( playerid, "/gang join [GANG_ID]" );
		else if ( gID < 0 || gID >= MAX_GANGS ) return SendError( playerid, "Invalid Gang ID." );
		else if ( !Iter_Contains( gangs, gID ) ) return SendError( playerid, "Invalid Gang ID." );
		else if ( p_gangInvited[ playerid ] [ gID ] == false ) return SendError( playerid, "You haven't been invited to this gang." );
		else if ( g_iTime > p_gangInviteTick[ playerid ] ) return p_gangInvited[ playerid ] [ gID ] = false, SendError( playerid, "This invite has expired, each invite only lasts for 2 minutes." );
		else if ( p_GangID[ playerid ] != INVALID_GANG_ID ) return SendError( playerid, "You are already inside a gang." );
		else
		{
		    p_gangInvited[ playerid ] [ gID ] = false;
		    SetPlayerGang( playerid, gID );
		}
		return 1;
	}
	else if ( !strcmp( params, "invite", false, 6 ) )
	{
		new
		    pID
		;

		if ( sscanf( params[ 7 ], "u", pID ) ) return SendUsage( playerid, "/gang invite [PLAYER_ID]" );
		else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "This player is not connected." );
		else if ( p_Class[ pID ] != CLASS_CIVILIAN ) return SendError( playerid, "You cannot invite people from non-civilian classes." );
		else if ( IsPlayerSettingToggled( pID, SETTING_GANG_INVITES ) ) return SendError( playerid, "This player has disabled gang invites." );
		else if ( pID == playerid ) return SendError( playerid, "You cannot use this on yourself." );
		else if ( p_GangID[ pID ] != INVALID_GANG_ID ) return SendError( playerid, "This player is already inside a gang." );
		else if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not inside any gang." );
		else if ( p_GangID[ pID ] == p_GangID[ playerid ] ) return SendError( playerid, "This player is in your gang." );
		else
		{
			if ( g_gangData[ p_GangID[ playerid ] ] [ E_INVITE_ONLY ] && !IsPlayerGangLeader( playerid, p_GangID[ playerid ] ) )
				return SendError( playerid, "You are not the gang leader." );

		    p_gangInvited[ pID ] [ p_GangID[ playerid ] ] = true;
		    p_gangInviteTick[ pID ] = g_iTime + 120;
			GameTextForPlayer( pID, sprintf( "~n~~y~~h~/gang join %d", p_GangID[ playerid ] ), 2000, 4 );
		    format( szNormalString, sizeof( szNormalString ), "[GANG]{FFFFFF} %s(%d) has invited you to join %s, to join type \"/gang join %d\"", ReturnPlayerName( playerid ), playerid, g_gangData[ p_GangID[ playerid ] ] [ E_NAME ], p_GangID[ playerid ] );
			SendClientMessage( pID, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], szNormalString );
			format( szNormalString, sizeof( szNormalString ), "[GANG]{FFFFFF} You have invited %s(%d) to join your gang.", ReturnPlayerName( pID ), pID );
			SendClientMessage( playerid, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], szNormalString );
		}
		return 1;
	}
	else if ( !strcmp( params, "leave", false, 5 ) )
	{
		if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not in any gang." );
		RemovePlayerFromGang( playerid, GANG_LEAVE_QUIT );
		return SendServerMessage( playerid, "You have left your previous gang." );
	}
	else if ( !strcmp( params, "splitprofit", false, 11 ) )
	{
		new
			fProfitSplit;

		if ( sscanf( params[ 12 ], "d", fProfitSplit ) ) SendUsage( playerid, "/gang splitprofit [PERCENTAGE]" );
		else if ( p_GangID[ playerid ] == INVALID_GANG_ID ) SendError( playerid, "You are not inside any gang." );
		else if ( fProfitSplit == 0 && p_GangSplitProfits[ playerid ] == 0 ) SendError( playerid, "You are already not splitting any profit among your gang bank." );
		else if ( fProfitSplit == 0 )
		{
			p_GangSplitProfits[ playerid ] = 0;
			SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has decided to no longer split his profits to the gang.", ReturnPlayerName( playerid ), playerid );
		}
		else if ( fProfitSplit == p_GangSplitProfits[ playerid ] && fProfitSplit != 0 ) SendError( playerid, "Your current profit split is the same as the percentage you specified." );
		else if ( 0 < fProfitSplit > 100 ) SendError( playerid, "Choose a percentage between 0 and 100." );
		else if ( fProfitSplit > 99999999 || fProfitSplit < 0 ) SendError( playerid, "Choose a percentage between 0 and 100." ); // Going over billions
		else
		{
			p_GangSplitProfits[ playerid ] = fProfitSplit;
			SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has decided to split %d%s of his profit into the gang bank.", ReturnPlayerName( playerid ), playerid, fProfitSplit, "%%" );
		}
		return 1;
	}
	else if ( !strcmp( params, "private", false, 6 ) )
	{
		new
			gangid = p_GangID[ playerid ];

		if ( gangid == INVALID_GANG_ID ) return SendError( playerid, "You are not inside any gang." );
		else if ( ! IsPlayerGangLeader( playerid, gangid ) ) return SendError( playerid, "You are not a gang leader." );
		else
		{
			// Reset all gang invites
			for( new i = 0; i < MAX_PLAYERS; i++ ) {
				p_gangInvited[ i ] [ gangid ] = false;
			}

			// Update private status
			mysql_single_query( sprintf( "UPDATE `GANGS` SET `INVITE_ONLY`=%d WHERE `ID`=%d", ( g_gangData[ gangid ] [ E_INVITE_ONLY ] = !g_gangData[ gangid ] [ E_INVITE_ONLY ] ), g_gangData[ gangid ] [ E_SQL_ID ] ) );
			SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) %s made the gang private.", ReturnPlayerName( playerid ), playerid, g_gangData[ gangid ] [ E_INVITE_ONLY ] ? ( "has" ) : ( "has not" ) );
		}
		return 1;
	}
	return SendUsage( playerid, "/gang [CREATE/LEAVE/INVITE/JOIN/KICK/NAME/LEADER/COLEADER/COLOR/SPLITPROFIT/PRIVATE/JOINMSG]" );
}

CMD:g( playerid, params[ ] )
{
	new
	    msg[ 90 ]
	;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "Civilians can use this command only." );
	else if ( p_GangID[ playerid ] == INVALID_GANG_ID ) return SendError( playerid, "You are not in any gang." );
    else if ( sscanf( params, "s[90]", msg ) ) return SendUsage( playerid, "/g [MESSAGE]" );
    else
	{
		SendClientMessageToGang( p_GangID[ playerid ], g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "<Gang Chat> %s(%d):{FFFFFF} %s", ReturnPlayerName( playerid ), playerid, msg );
	}
	return 1;
}

/* ** SQL Threads ** */
thread OnPlayerGangLoaded( playerid )
{
	new rows, fields;

	cache_get_data( rows, fields );

	if ( rows )
	{
		new gang_name[ 30 ], join_msg[ 96 ];
		new gang_sql_id = cache_get_field_content_int( 0, "ID" );

		// Check again if the gang exists
		foreach (new g : gangs) if ( gang_sql_id == g_gangData[ g ] [ E_SQL_ID ] ) {
			p_GangID[ playerid ] = g;
			printf( "[gang debug] found duplicate gang for gang id %d (User : %s)", g, ReturnPlayerName( playerid ) );
			return 1;
		}

		// reset name and join message appropriately
		cache_get_field_content( 0, "NAME", gang_name, dbHandle, sizeof( gang_name ) );
		cache_get_field_content( 0, "JOIN_MSG", join_msg, dbHandle, sizeof( join_msg ) );

		// create gang
		new handle = CreateGang( gang_name,
			cache_get_field_content_int( 0, "LEADER", dbHandle ),
			cache_get_field_content_int( 0, "COLOR", dbHandle ),
			cache_get_field_content_int( 0, "KILLS", dbHandle ),
			cache_get_field_content_int( 0, "DEATHS", dbHandle ),
			cache_get_field_content_int( 0, "BANK", dbHandle ),
			cache_get_field_content_int( 0, "SCORE", dbHandle ),
			cache_get_field_content_int( 0, "RESPECT", dbHandle ),
			!! cache_get_field_content_int( 0, "INVITE_ONLY", dbHandle ),
			join_msg, false, gang_sql_id
		);

		// message player
		if ( handle != ITER_NONE )
		{
			p_GangID[ playerid ] = handle;
			InformGangConnectMessage( playerid, handle );
			printf("[%s] Added gangid %d as gang slot %d", ReturnPlayerName( playerid ), gang_sql_id, handle );
		}
		else
		{
			p_GangID[ playerid ] = -1;
			SendServerMessage( playerid, "Had an issue loading your gang. Contact Lorenc (0x92F)." );
			printf("[GANG] [ERROR] Had an issue loading a gang row id %d", gang_sql_id );
		}
	}
	else
	{
		p_GangID[ playerid ] = -1;
	}
	return 1;
}

thread OnGangAdded( gangid )
{
	g_gangData[ gangid ] [ E_SQL_ID ] = cache_insert_id( );
	return 1;
}

thread OnGangColeaderLoad( gangid ) {

	new
		rows, fields;

	cache_get_data( rows, fields );

	if ( rows ) {
		for( new i = 0; i < rows; i ++ ) {
			if ( i >= MAX_COLEADERS ) break;
			g_gangData[ gangid ] [ E_COLEADER ] [ i ] = cache_get_field_content_int( i, "USER_ID", dbHandle );
		}
	}
}

thread OnListGangMembers( playerid, gangid, page )
{
	new
	    rows, i;

	cache_get_data( rows, tmpVariable );

	if ( rows )
	{
		static
			userName[ MAX_PLAYER_NAME ];

		for( i = 0, szLargeString[ 0 ] = '\0'; i < rows; i++ )
		{
			cache_get_field_content( i, "NAME", userName );
			format( szLargeString, sizeof( szLargeString ), "%s%s%s\n", szLargeString, cache_get_field_content_int( i, "ONLINE", dbHandle ) ? ( #COL_GREEN ) : ( #COL_WHITE ), userName );
		}

		SetPVarInt( playerid, "gang_members_id", gangid );
		SetPVarInt( playerid, "gang_members_results", rows );
		SetPVarInt( playerid, "gang_members_page", page );
		ShowPlayerDialog( playerid, DIALOG_GANG_LIST_MEMBERS, DIALOG_STYLE_LIST, sprintf( ""COL_WHITE"Gang Members - Page %d", page + 1 ), szLargeString, rows >= 20 ? ( "Next" ) : ( "Close" ), "Back" );
	}
	else
	{
		// Notify user
		SendError( playerid, "This gang no longer has any members." );
	}
	return 1;
}

thread OnListClans( playerid )
{
	new
	    rows, fields
	;
    cache_get_data( rows, fields );

    if ( rows )
    {
    	new
    		szTag[ 8 ],
    		szName[ 30 ],
    		iScore, iColor
    	;

    	szLargeString = ""COL_WHITE"Tag\t"COL_WHITE"Name\t"COL_WHITE"Score\n";

    	for( new i = 0; i < rows; i++ )
		{
			cache_get_field_content( i, "CLAN_TAG", szTag );
			cache_get_field_content( i, "NAME", szName );
			iScore = cache_get_field_content_int( i, "SCORE", dbHandle );
			iColor = cache_get_field_content_int( i, "COLOR", dbHandle );

			format( szLargeString, sizeof( szLargeString ), "%s[%s]\t{%06x}%s\t%d\n", szLargeString, szTag, iColor >>> 8, szName, iScore );
		}

		return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "Clan List", szLargeString, "Close", "" ), 1;
	}
	SendError( playerid, "There are no clans to show." );
	return 1;
}

thread OnGangKickOffline( playerid, gangid )
{
	new
		static_gangid = p_GangID[ playerid ],
		rows = cache_get_row_count( );

	if ( rows )
	{
		new player_name[ MAX_PLAYER_NAME ];
		new scan_name[ MAX_PLAYER_NAME ];

		cache_get_field_content( 0, "NAME", player_name );

		// scan if player is online
		new player_accid = cache_get_field_content_int( 0, "ID", dbHandle );

		foreach ( new scanid : Player ) {
			GetPlayerName( scanid, scan_name, sizeof( scan_name ) );

			if ( strmatch( player_name, scan_name ) ) {
				return SendError( playerid, "You cannot use this command on a online player." ), 1;
			}
		}

		// verify player is in gang
		new player_gangid = cache_get_field_content_int( 0, "GANG_ID", dbHandle );

		if ( IsPlayerGangLeader( playerid, player_gangid, .only_leader = 1 ) ) {
			return SendError( playerid, "You cannot kick this player from the gang." );
		}

		if ( player_gangid != gangid ) {
			return SendError( playerid, "This player is not in your gang." );
		}

		// remove as coleader
		mysql_single_query( sprintf( "DELETE FROM `GANG_COLEADERS` WHERE `USER_ID`=%d", player_accid ) );
 		mysql_single_query( sprintf( "UPDATE `USERS` SET `GANG_ID`=-1 WHERE `ID`=%d", player_accid ) );

		SendClientMessageToGang( static_gangid, g_gangData[ static_gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s has left the gang (KICKED)", player_name );
	}
	else
	{
		SendError( playerid, "It seems like this player isn't in your gang!" );
	}
	return 1;
}

/* ** Functions ** */
stock CreateGang( const gang_name[ 30 ], leader, gang_color, kills = 1, deaths = 1, bank = 0, score = 0, respect = 0, bool: invite_only = false, const join_message[ 96 ] = "NULL", bool: has_facility = false, sql_id = 0 )
{
	new handle = Iter_Free( gangs );

	if ( handle != ITER_NONE )
	{
		// Insert into iterator
	    Iter_Add( gangs, handle );

		// insert gang into database, if no sql found
		if ( ! sql_id )
		{
			// insert gang and fetch sql id
			mysql_format( dbHandle, szBigString, sizeof( szBigString ), "INSERT INTO `GANGS`(`NAME`,`LEADER`,`COLOR`) VALUES ('%e', %d, %d)", gang_name, leader, gang_color );
			mysql_function_query( dbHandle, szBigString, true, "OnGangAdded", "d", handle );

			// reset coleaders in this case
			for ( new i = 0; i < MAX_COLEADERS; i ++ ) {
				g_gangData[ handle ] [ E_COLEADER ] [ i ] = 0;
			}
		}
		else
		{
			// set gang sql id
			g_gangData[ handle ] [ E_SQL_ID ] = sql_id;

			// load coleaders
			format( szNormalString, sizeof( szNormalString ), "SELECT `USER_ID` FROM `GANG_COLEADERS` WHERE `GANG_ID`=%d LIMIT 0,%d", g_gangData[ handle ] [ E_SQL_ID ], MAX_COLEADERS );
			mysql_function_query( dbHandle, szNormalString, true, "OnGangColeaderLoad", "d", handle );
		}

		// Check for null join message
		if ( ismysqlnull( join_message ) ) g_gangData[ handle ] [ E_JOIN_MSG ] [ 0 ] = '\0';
		else format( g_gangData[ handle ] [ E_JOIN_MSG ], 96, "%s", join_message );

		// format name
		format( g_gangData[ handle ] [ E_NAME ], 30, "%s", gang_name );
		trimString( g_gangData[ handle ] [ E_NAME ] );

		// default variables
	    g_gangData[ handle ] [ E_LEADER ] 			= leader;
	    g_gangData[ handle ] [ E_KILLS ] 			= kills;
	    g_gangData[ handle ] [ E_DEATHS ] 			= deaths;
	    g_gangData[ handle ] [ E_SCORE ] 			= score;
	    g_gangData[ handle ] [ E_BANK ] 			= bank;
	    g_gangData[ handle ] [ E_COLOR ]        	= gang_color;
	    g_gangData[ handle ] [ E_RESPECT ] 			= respect;
		g_gangData[ handle ] [ E_INVITE_ONLY ] 		= invite_only;
		g_gangData[ handle ] [ E_HAS_FACILITY ] 	= has_facility;

		// callback
		CallLocalFunction( "OnGangLoad", "d", handle );
	}
	return handle;
}

stock DestroyGang( gangid, bool: soft_delete, bool: iter_remove = true )
{
	if ( !Iter_Contains( gangs, gangid ) )
		return;

	if ( ! soft_delete )
	{
	 	// Do SQL operations
	 	mysql_single_query( sprintf( "DELETE FROM `GANGS` WHERE `ID`=%d", g_gangData[ gangid ] [ E_SQL_ID ] ) );
	 	mysql_single_query( sprintf( "DELETE FROM `GANG_COLEADERS` WHERE `GANG_ID`=%d", g_gangData[ gangid ] [ E_SQL_ID ] ) );
	 	mysql_single_query( sprintf( "UPDATE `USERS` SET `GANG_ID`=-1 WHERE `GANG_ID`=%d", g_gangData[ gangid ] [ E_SQL_ID ] ) );
	}

 	// Disconnect current users
 	foreach(new i : Player) if ( p_GangID[ i ] == gangid ) {
 		p_GangID[ i ] = INVALID_GANG_ID;
 	}

 	// Callback
	CallLocalFunction( "OnGangUnload", "dd", gangid, ! soft_delete );

	// Reset gang data
	g_gangData[ gangid ] [ E_SQL_ID ] 			= 0;
    g_gangData[ gangid ] [ E_LEADER ] 			= 0;
	g_gangData[ gangid ] [ E_SOFT_DELETE_TS ] 	= 0;
 	g_gangData[ gangid ] [ E_COLOR ]       	 	= g_gangColors[ random( sizeof( g_gangColors ) ) ];
 	g_gangData[ gangid ] [ E_NAME ] [ 0 ]   	= '\0';
 	g_gangData[ gangid ] [ E_BANK ] 			= 0;
 	g_gangData[ gangid ] [ E_RESPECT ] 			= 0;
	g_gangData[ gangid ] [ E_INVITE_ONLY ] 		= false;
	g_gangData[ gangid ] [ E_JOIN_MSG ] [ 0 ] 	= '\0';

	// Reset coleaders
	for ( new i = 0; i < MAX_COLEADERS; i ++ )
		g_gangData[ gangid ] [ E_COLEADER ] [ i ] = 0;

 	// Free iterator id
 	if ( iter_remove ) {
 		Iter_Remove( gangs, gangid );
 	}

 	// Empty out the turfs
 	Turf_ResetGangTurfs( gangid );
}

stock SaveGangData( gangid )
{
	if ( gangid == INVALID_GANG_ID )
		return;

	mysql_format( dbHandle, szLargeString, sizeof( szLargeString ), "UPDATE `GANGS` SET `NAME`='%e',`LEADER`=%d,`COLOR`=%d,`KILLS`=%d,`DEATHS`=%d,`SCORE`=%d,`BANK`=%d,`RESPECT`=%d WHERE `ID`=%d",
		g_gangData[ gangid ] [ E_NAME ], g_gangData[ gangid ] [ E_LEADER ], g_gangData[ gangid ] [ E_COLOR ], g_gangData[ gangid ] [ E_KILLS ], g_gangData[ gangid ] [ E_DEATHS ], g_gangData[ gangid ] [ E_SCORE ], g_gangData[ gangid ] [ E_BANK ], g_gangData[ gangid ] [ E_RESPECT ], g_gangData[ gangid ] [ E_SQL_ID ] );

	mysql_single_query( szLargeString );
}

stock SetPlayerFindOrCreateGang( playerid, gang_sql )
{
	new bool: foundGang = false;

	// Reset gang id just incase
	p_GangID[ playerid ] = INVALID_GANG_ID;

	// Search all gangs for the SQL
	printf("[%s] Reading gang id %d", ReturnPlayerName( playerid ), gang_sql );
	if ( gang_sql ) {
		foreach (new g : gangs) if( gang_sql == g_gangData[ g ] [ E_SQL_ID ] ) {
			p_GangID[ playerid ] = g, foundGang = true;
			break;
		}
	}

	printf("[%s] Found gang ? %s , id %d, gangid %d", ReturnPlayerName( playerid ), foundGang ? ("YES") : ("NO"), p_GangID[ playerid ], gang_sql );

	if ( ! foundGang ) {
		format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `GANGS` WHERE `LEADER`=%d OR `ID`=%d LIMIT 0,1", p_AccountID[ playerid ], gang_sql );
		mysql_function_query( dbHandle, szNormalString, true, "OnPlayerGangLoaded", "d", playerid );
	}

	// Send gang join message
	if ( p_GangID[ playerid ] != INVALID_GANG_ID && strlen( g_gangData[ p_GangID[ playerid ] ] [ E_JOIN_MSG ] ) ) {
		SendClientMessageFormatted( playerid, g_gangData[ p_GangID[ playerid ] ] [ E_COLOR ], "[GANG]"COL_GREY" %s", g_gangData[ p_GangID[ playerid ] ] [ E_JOIN_MSG ] );
	}
}

stock InformGangConnectMessage( playerid, gangid )
{
	if ( ! strlen( g_gangData[ gangid ] [ E_JOIN_MSG ] ) ) {
  		SendClientMessageFormatted( playerid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]"COL_GREY" %s has been loaded into the server.", g_gangData[ gangid ] [ E_NAME ] );
	} else {
  		SendClientMessageFormatted( playerid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]"COL_GREY" %s", g_gangData[ gangid ] [ E_JOIN_MSG ] );
	}
	return 1;
}

stock IsPlayerGangLeader( playerid, gangid, only_leader = 0 ) {

	if ( g_gangData[ gangid ] [ E_LEADER ] == p_AccountID[ playerid ] )
		return true;

	// Reset coleaders
	if ( only_leader == 0 ) {
		for ( new i = 0; i < MAX_COLEADERS; i ++ ) {
			if ( g_gangData[ gangid ] [ E_COLEADER ] [ i ] == p_AccountID[ playerid ] )
				return true;
		}
	}
	return false;
}

stock DisconnectFromGang( playerid )
{
	new
		gangid = p_GangID[ playerid ];

	if ( gangid == INVALID_GANG_ID )
		return 0;

	p_GangID[ playerid ] = INVALID_GANG_ID;

	if ( ! Iter_Contains( gangs, gangid ) )
		return 0;

	if ( g_gangData[ gangid ] [ E_HAS_FACILITY ] ) // we will not soft delete gangs with facilities
		return 1;

	new
		members = GetOnlineGangMembers( gangid );

	printf("Gang id %d has currently %d members online", g_gangData[ gangid ] [ E_SQL_ID ], members );
	if ( members <= 0 ) {
		g_gangData[ gangid ] [ E_SOFT_DELETE_TS ] = g_iTime + 60;
		printf("[GANG DEBUG] Begin soft delete Id %d Since No Ppl", g_gangData[ gangid ] [ E_SQL_ID ] );
	}
	return 1;
}

stock RemovePlayerFromGang( playerid, E_GANG_LEAVE_REASON: reason = GANG_LEAVE_UNKNOWN, otherid = INVALID_PLAYER_ID )
{
	new
		gangid = p_GangID[ playerid ];

 	p_GangID[ playerid ] = INVALID_GANG_ID;

	if ( !Iter_Contains( gangs, gangid ) )
		return 0;

	SetPlayerColorToTeam( playerid );

 	if ( g_gangData[ gangid ] [ E_LEADER ] == p_AccountID[ playerid ] )
 	{
 		new
 			selected_coleader = -1;

 		for ( new i = 0; i < MAX_COLEADERS; i ++ ) if ( g_gangData[ gangid ] [ E_COLEADER ] [ i ] ) {
 			selected_coleader = i;
 			break;
 		}

 		// Coleader exists?
 		if ( selected_coleader != -1 )
 		{
	 		g_gangData[ gangid ] [ E_LEADER ] = g_gangData[ gangid ] [ E_COLEADER ] [ selected_coleader ];
	 		g_gangData[ gangid ] [ E_COLEADER ] [ selected_coleader ] = 0;
			SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} The co-leader of the gang has been selected as the gang leader (acc id %d).", selected_coleader );
 		}
 		else
 		{
			// Set invalid player to allow for check
	 		g_gangData[ gangid ] [ E_LEADER ] = -1;

	 		// Look for leader substitute
		 	foreach(new memberid : Player)
		 	{
				if ( p_GangID[ memberid ] == gangid )
				{
					// Update color gang
					SetGangColorsToGang( gangid );
				    g_gangData[ gangid ] [ E_LEADER ] = p_AccountID[ memberid ];
					SendClientMessageToGang( gangid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has been selected as the gang leader.", ReturnPlayerName( memberid ), memberid );
					break;
				}
		 	}

		 	// Cannot find any leader, so destroy
		 	if ( g_gangData[ gangid ] [ E_LEADER ] == -1 )
		 	{
		 		// Warn gang owner about gang
		 	    SendClientMessage( playerid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} There was nobody online that could be a leader for this gang therefore it has been deleted from the server." );

		 		// Destroy gang internally
		 		DestroyGang( gangid, false );
		 		return 1;
		 	}
 		}
	}

	// reset the coleader
	for ( new i = 0; i < MAX_COLEADERS; i++ ) if ( g_gangData[ gangid ] [ E_COLEADER ] [ i ] == p_AccountID[ playerid ] ) {
 		g_gangData[ gangid ] [ E_COLEADER ] [ i ] = 0;
 	}

 	// wouldn't make sense to keep the coleader in any gang
 	mysql_single_query( sprintf( "DELETE FROM `GANG_COLEADERS` WHERE `USER_ID`=%d", p_AccountID[ playerid ] ) );
 	mysql_single_query( sprintf( "UPDATE `USERS` SET `GANG_ID`=-1 WHERE `ID`=%d", p_AccountID[ playerid ] ) );

 	printf("[%s] Gang ID after leaving is %d", ReturnPlayerName( playerid ), p_GangID[ playerid ] );

	// Alter the gang & players
	if ( Iter_Contains( gangs, gangid ) )
	{
		SaveGangData( gangid );
		CallLocalFunction( "OnPlayerLeaveGang", "ddd", playerid, gangid, _: reason );

		switch( reason )
		{
		    case GANG_LEAVE_KICK:
		    	SendClientMessageFormatted( playerid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has been kicked from the gang by %s(%d)!", ReturnPlayerName( playerid ), playerid, ReturnPlayerName( otherid ), otherid );

		    case GANG_LEAVE_UNKNOWN, GANG_LEAVE_QUIT:
		    	SendClientMessageFormatted( playerid, g_gangData[ gangid ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has left the gang!", ReturnPlayerName( playerid ), playerid );
		}
	}
	return 1;
}

stock SetPlayerGang( playerid, joining_gang )
{
	if ( ! Iter_Contains( gangs, joining_gang ) )
		return 0;

	// remove from existing gang
	if ( p_GangID[ playerid ] != INVALID_GANG_ID ) {
		RemovePlayerFromGang( playerid, GANG_LEAVE_QUIT );
	}

	p_GangID[ playerid ] = joining_gang;
    if ( GetPlayerWantedLevel( playerid ) < 1 ) SetPlayerColor( playerid, g_gangData[ joining_gang ] [ E_COLOR ] );
	mysql_single_query( sprintf( "UPDATE `USERS` SET `GANG_ID`=%d WHERE `ID`=%d", g_gangData[ joining_gang ] [ E_SQL_ID ], GetPlayerAccountID( playerid ) ) );
	SendClientMessageToGang( joining_gang, g_gangData[ joining_gang ] [ E_COLOR ], "[GANG]{FFFFFF} %s(%d) has joined the gang.", ReturnPlayerName( playerid ), playerid );
	CallLocalFunction( "OnPlayerJoinGang", "dd", playerid, joining_gang );
	return 1;
}

stock GetGangCash( gangid ) return g_gangData[ gangid ] [ E_BANK ];
stock GiveGangCash( gangid, cash ) {
	g_gangData[ gangid ] [ E_BANK ] += cash;
}

stock gangNameExists( szName[ ] )
{
	foreach(new i : gangs)
	{
	    if ( strmatch( g_gangData[ i ] [ E_NAME ], szName ) ) return true;
	}
	return false;
}

stock SetGangColorsToGang( gangid )
{
	foreach ( new i : Player )
	{
		// refresh player turfs
		Turf_RedrawPlayerGangZones( i );

		// set new colour of player
	    if ( p_GangID[ i ] == gangid && p_WantedLevel[ i ] <= 0 && p_Class[ i ] == CLASS_CIVILIAN ) {
	        SetPlayerColor( i, g_gangData[ gangid ] [ E_COLOR ] );
	    }
	}
}

stock ReturnGangName( i )
{
	new
		szGang[ 30 ] = "Unknown";

	if ( IsValidGangID( i ) ) {
		format( szGang, sizeof( szGang ), "%s", g_gangData[ i ] [ E_NAME ] );
	}
	return szGang;
}

stock SplitPlayerCashForGang( playerid, Float: cashRobbed )
{
	new
		bGangProfitSplit = ( p_GangID[ playerid ] != INVALID_GANG_ID && p_GangSplitProfits[ playerid ] ), Float: cashBanked = 0;

	if ( bGangProfitSplit )
	{
		new
			Float: keepOnHand = cashRobbed;

		cashRobbed = ( keepOnHand * float( 100 - p_GangSplitProfits[ playerid ] ) ) / 100.0;
		cashBanked = ( keepOnHand * float( p_GangSplitProfits[ playerid ] ) ) / 100.0;

		new
			iRoundedBanked = floatround( cashBanked, floatround_floor );

		SendServerMessage( playerid, "You've split %s (%d%s) towards your gang's bank balance.", cash_format( iRoundedBanked ), p_GangSplitProfits[ playerid ], "%%" );

		/*if ( -1 < iRoundedBanked > 50000 )
		{
			printf( "[EXPLOIT] [0xC1] %s has tried to store %s to gang %d", ReturnPlayerName( playerid ), cash_format( iRoundedBanked ), p_GangID[ playerid ] );
			return SendError( playerid, "An exploit (0xC2) had occured, therefore this robbery was denied. Please report this to Lorenc!" );
		}*/

		g_gangData[ p_GangID[ playerid ] ] [ E_BANK ] += iRoundedBanked;
	}

	new
		iRoundedRobbed = floatround( cashRobbed, floatround_floor );

	if ( iRoundedRobbed != 0 )
	{
		/*if ( -1 < iRoundedRobbed > 50000 )
		{
			printf( "[EXPLOIT] [0xC1] %s has robbed %s", ReturnPlayerName( playerid ), cash_format( iRoundedRobbed ) );
			return SendError( playerid, "An exploit (0xC1) had occured, therefore this robbery was denied. Please report this to Lorenc!" );
		}*/

		GivePlayerCash( playerid, iRoundedRobbed );
	}
	return 1;
}

stock GetOnlineGangMembers( gangid, &afk_members = 0 )
{
	if ( gangid == INVALID_GANG_ID )
		return 0;

	new
		iPlayers = 0;

	foreach ( new playerid : Player ) if ( p_GangID[ playerid ] == gangid ) {
		if ( IsPlayerAFK( playerid ) ) afk_members ++;
		iPlayers ++;
	}
	return iPlayers;
}