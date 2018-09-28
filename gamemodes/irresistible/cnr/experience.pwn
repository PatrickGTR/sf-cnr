/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\experience.pwn
 * Purpose: player experience system 2.0
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define DIALOG_VIEW_LEVEL			5943

/* ** Macros ** */
#define IsDoubleXP() 				( GetGVarInt( "doublexp" ) )

/* ** Constants ** */
enum E_LEVELS {
	E_POLICE,
	E_ROBBERY,
	E_DEATHMATCH,

	/*E_FIREMAN,
	E_PARAMEDIC,
	E_HITMAN,
	E_BURGLAR,
	E_TERRORIST,
	E_CAR_JACKER,
	E_DRUG_PRODUCTION,
	E_MINING,
	E_TRANSPORT*/
};

enum E_LEVEL_DATA {
	E_NAME[ 16 ],				Float: E_MAX_UNITS,				Float: E_XP_DILATION
};

static const
	Float: EXP_MAX_PLAYER_LEVEL 	= 100.0;

static const
	g_levelData 					[ ] [ E_LEVEL_DATA ] =
	{
		// Level Name 			Level 100 Req.		XP Dilation (just to confuse user)
		{ "Police",				7500.0, 			20.0 }, 	// 7.5k arrests
		{ "Robbery", 			30000.0,			15.0 }, 	// 30K robberies
		{ "Deathmatch", 		75000.0,			10.0 } 		// 75K kills
/*
		{ "Fireman",			10000.0,			9.0 },		// 10k fires
		{ "Hitman",				1500.0,				4.5 },		// 1.5k contracts
		{ "Burglar",			2000.0,				7.5 },		// 2K burglaries
		{ "Terrorist",			15000.0,			6.0 },		// 15k blown entities
		{ "Car Jacker",			10000.0,			6.0 },		// 10k cars jacked
		{ "Drug Production",	10000.0,			6.0	},		// 10k exports drug related
		{ "Mining",				1500.0,				3.0 }		// 1,500 mining ores
*/
	}
;

/* ** Variables ** */
static stock
	Float: g_playerExperience		[ MAX_PLAYERS ] [ E_LEVELS ]
;

/* ** Important ** */
stock Float: GetPlayerLevel( playerid, E_LEVELS: level ) {
	return floatsqroot( g_playerExperience[ playerid ] [ level ] / ( ( g_levelData[ _: level ] [ E_MAX_UNITS ] * g_levelData[ _: level ] [ E_XP_DILATION ] ) / ( EXP_MAX_PLAYER_LEVEL * EXP_MAX_PLAYER_LEVEL ) ) );
}

stock Float: GetPlayerTotalExperience( playerid ) {
	new
		Float: experience = 0.0;

	for ( new l = 0; l < sizeof ( g_levelData ); l ++ ) {
		experience += g_playerExperience[ playerid ] [ E_LEVELS: l ];
	}
	return experience;
}

/* ** Hooks ** */
hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_VIEW_LEVEL && response ) {
		return cmd_level( playerid, sprintf( "%d", GetPVarInt( playerid, "experience_watchingid" ) ) ), 1;
	}
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	if ( IsPlayerLoggedIn( playerid ) )
	{
		new
			Float: total_experience = GetPlayerTotalExperience( playerid );

		PlayerTextDrawSetString( playerid, p_ExperienceTD[ playerid ], sprintf( "%08.0f", total_experience ) );
	}
	return 1;
}

hook OnPlayerLogin( playerid )
{
	mysql_tquery( dbHandle, sprintf( "SELECT * FROM `USER_LEVELS` WHERE `USER_ID` = %d", GetPlayerAccountID( playerid ) ), "Experience_OnLoad", "d", playerid );
	return 1;
}

hook OnPlayerDisconnect( playerid, reason ) {
	for ( new l = 0; l < sizeof ( g_levelData ); l ++ ) {
		g_playerExperience[ playerid ] [ E_LEVELS: l ] = 0;
	}
	return 1;
}

/* ** Commands ** */
CMD:experience( playerid, params[ ] ) return cmd_level( playerid, params );
CMD:levels( playerid, params[ ] ) return cmd_level( playerid, params );
CMD:xp( playerid, params[ ] ) return cmd_level( playerid, params );
CMD:level( playerid, params[ ] )
{
	new
	 	watchingid;

	if ( sscanf( params, "u", watchingid ) )
		watchingid = playerid;

	if ( !IsPlayerConnected( watchingid ) )
		watchingid = playerid;

	new
		player_total_lvl = 0;

	szLargeString = ""COL_GREY"Skill\t"COL_GREY"Current Level\t"COL_GREY"XP Till Next Level\n";

	for ( new level_id; level_id < sizeof( g_levelData ); level_id ++ )
	{
		new Float: current_rank = GetPlayerLevel( watchingid, E_LEVELS: level_id );
		new Float: next_rank = floatround( current_rank, floatround_floor ) + 1.0;
		new Float: next_rank_xp = ( g_levelData[ level_id ] [ E_MAX_UNITS ] * g_levelData[ level_id ] [ E_XP_DILATION ] ) / ( EXP_MAX_PLAYER_LEVEL * EXP_MAX_PLAYER_LEVEL ) * ( next_rank * next_rank );

		player_total_lvl += floatround( current_rank, floatround_floor );
		format( szLargeString, sizeof( szLargeString ), "%s%s Level\t%s%0.0f / %0.0f\t"COL_PURPLE"%0.0f XP\n", szLargeString, g_levelData[ level_id ] [ E_NAME ], current_rank >= 100.0 ? ( COL_GREEN ) : ( COL_GREY ), current_rank, EXP_MAX_PLAYER_LEVEL, next_rank_xp - g_playerExperience[ watchingid ] [ E_LEVELS: level_id ] );
	}

	SetPVarInt( playerid, "experience_watchingid", watchingid );
	return ShowPlayerDialog( playerid, DIALOG_VIEW_LEVEL, DIALOG_STYLE_TABLIST_HEADERS, sprintf( "{FFFFFF}%s's Level - Total Level %d", ReturnPlayerName( watchingid ), player_total_lvl ), szLargeString, "Refresh", "Close" );
}

/* ** SQL Threads ** */
thread Experience_OnLoad( playerid )
{
	new
		rows = cache_get_row_count( );

	if ( rows )
	{
		for ( new row = 0; row < rows; row ++ )
		{
			new
				level_id = cache_get_field_content_int( row, "LEVEL_ID" );

			// make sure we don't get any deprecated/invalid levels
			if ( level_id < sizeof ( g_levelData ) ) {
				g_playerExperience[ playerid ] [ E_LEVELS: level_id ] = cache_get_field_content_float( row, "EXPERIENCE" );
			}
		}
	}
	return 1;
}

/* ** Functions ** */
stock GivePlayerExperience( playerid, E_LEVELS: level, Float: default_xp = 1.0, bool: with_dilation = true )
{
	if ( ! IsPlayerLoggedIn( playerid ) || ! ( 0 <= _: level < sizeof( g_levelData ) ) )
		return 0;

	// dilation is there so people see +3 when they arrest ... could trigger dopamine levels instead of constantly +1 lol
	new Float: xp_earned = default_xp * ( IsDoubleXP( ) ? 2.0 : 1.0 ) * ( with_dilation ? ( g_levelData[ _: level ] [ E_XP_DILATION ] ) : 1.0 );

	// when a player ranks up
	new next_rank = floatround( GetPlayerLevel( playerid, level ), floatround_floor ) + 1;
	new Float: next_rank_xp = ( g_levelData[ _: level ] [ E_MAX_UNITS ] * g_levelData[ _: level ] [ E_XP_DILATION ] ) / ( EXP_MAX_PLAYER_LEVEL * EXP_MAX_PLAYER_LEVEL ) * float( next_rank * next_rank );

	if ( g_playerExperience[ playerid ] [ level ] + xp_earned >= next_rank_xp ) {
		ShowPlayerHelpDialog( playerid, 10000, "~p~Congratulations %s!~n~~n~~w~Your %s Level is now ~p~%d.", ReturnPlayerName( playerid ), g_levelData[ _: level ] [ E_NAME ], next_rank );
		if ( !IsPlayerUsingRadio( playerid ) ) PlayAudioStreamForPlayer( playerid, "http://files.sfcnr.com/game_sounds/levelup.mp3" );
	}

	// check if its over 100 anyway
	if ( ( g_playerExperience[ playerid ] [ level ] += xp_earned ) > g_levelData[ _: level ] [ E_MAX_UNITS ] * g_levelData[ _: level ] [ E_XP_DILATION ] ) {
		g_playerExperience[ playerid ] [ level ] = g_levelData[ _: level ] [ E_MAX_UNITS ] * g_levelData[ _: level ] [ E_XP_DILATION ];
	}

	// alert user
    PlayerTextDrawSetString( playerid, p_ExperienceAwardTD[ playerid ], sprintf( "+%0.0f XP", xp_earned ) );
    PlayerTextDrawShow( playerid, p_ExperienceAwardTD[ playerid ] );
	SetTimerEx( "Experience_HideIncrementTD", 3500, false, "d", playerid );

	// save to database
	format(
		szBigString, sizeof( szBigString ),
		"INSERT INTO `USER_LEVELS` (`USER_ID`,`LEVEL_ID`,`EXPERIENCE`) VALUES(%d,%d,%f) ON DUPLICATE KEY UPDATE `EXPERIENCE`=%f",
		GetPlayerAccountID( playerid ), _: level, g_playerExperience[ playerid ] [ level ], g_playerExperience[ playerid ] [ level ]
	);
	return mysql_single_query( szBigString ), 1;
}

function Experience_HideIncrementTD( playerid ) {
	return PlayerTextDrawHide( playerid, p_ExperienceAwardTD[ playerid ] );
}

/*stock GetPlayerTotalLevel( playerid, &level = 0 ) {
	for ( new l = 0; l < sizeof ( g_levelData ); l ++ ) {
		level += floatround( GetPlayerLevel( playerid, E_LEVELS: l ), floatround_floor );
	}
	return level;
}*/

/* ** Migrations ** */
/*
	CREATE TABLE IF NOT EXISTS USER_LEVELS (
		`USER_ID` int(11),
		`LEVEL_ID` int(11),
		`EXPERIENCE` float,
		PRIMARY KEY (USER_ID, LEVEL_ID),
		FOREIGN KEY (USER_ID) REFERENCES USERS (ID) ON DELETE CASCADE
	);

	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 0 as LEVEL_ID, ARRESTS * 20.0 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 1 as LEVEL_ID, ROBBERIES * 15.0 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 2 as LEVEL_ID, KILLS * 10.0 AS EXPERIENCE FROM USERS);
	DELETE FROM USER_LEVELS WHERE EXPERIENCE = 0;


	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 3 as LEVEL_ID, FIRES * 9.0 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 4 as LEVEL_ID, CONTRACTS * 4.5 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 5 as LEVEL_ID, BURGLARIES * 7.5 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 6 as LEVEL_ID, (BLEW_JAILS + BLEW_VAULT) * 6.0 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 7 as LEVEL_ID, VEHICLES_JACKED * 6.0 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 8 as LEVEL_ID, (METH_YIELDED + (TRUCKED*0.33)) * 6.0 AS EXPERIENCE FROM USERS);
 */
