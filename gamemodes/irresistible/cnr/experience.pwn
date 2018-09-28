/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define EXP_MAX_PLAYER_LEVEL 		( 100.0 )

/* ** Double XP ** */
#define IsDoubleXP() 				( GetGVarInt( "doublexp" ) )

/* ** Constants ** */
enum E_LEVELS {
	E_LAW_ENFORCEMENT,
	E_DEATHMATCH,
	E_ROBBERY,
	E_FIREMAN,
	E_HITMAN,
	E_BURGLAR,
	E_TERRORIST,
	E_CAR_JACKER,
	E_DRUG_PRODUCTION
};

enum E_LEVEL_DATA {
	E_NAME[ 16 ],				Float: E_MAX_UNITS,				Float: E_XP_DILATION
};

static const
	g_levelData[ ] [ E_LEVEL_DATA ] =
	{
		// Level Name 			Level 100 Req.		XP Dilation (just to confuse user)
		{ "Law Enforcement",	10000.0, 			9.0 }, 		// 10K arrests
		{ "Robbery", 			50000.0,			6.0 }, 		// 100K robberies
		{ "Deathmatch", 		100000.0,			3.0 }, 		// 100K kills
		{ "Fireman",			10000.0,			9.0 },		// 10k fires
		{ "Hitman",				1500.0,				4.5 },		// 1.5k contracts
		{ "Burglar",			2000.0,				7.5 },		// 2K burglaries
		{ "Terrorist",			15000.0,			6.0 },		// 15k blown entities
		{ "Car Jacker",			10000.0,			6.0 },		// 10k cars jacked
		{ "Drug Production",	10000.0,			6.0	}		// 10k exports drug related
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
CMD:level( playerid, params[ ] )
{
	new
		player_total_lvl = 0;

	szLargeString = ""COL_GREY"Skill\t"COL_GREY"Current Level\t"COL_GREY"% To Next Level\n";

	for ( new level_id; level_id < sizeof( g_levelData ); level_id ++ )
	{
		new Float: current_rank = GetPlayerLevel( playerid, E_LEVELS: level_id );
		new Float: progress_to_next_level = floatfract( current_rank ) * 100.0;

		player_total_lvl += floatround( current_rank, floatround_floor );
		format( szLargeString, sizeof( szLargeString ), "%s%s Level\t%0.0f / %0.0f\t%0.1f%\n", szLargeString, g_levelData[ level_id ] [ E_NAME ], current_rank, EXP_MAX_PLAYER_LEVEL, progress_to_next_level );
	}
	return ShowPlayerDialog( playerid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, sprintf( "{FFFFFF}Player Level - Total Level %d", player_total_lvl ), szLargeString, "Close", "" );
}

CMD:givelevel( playerid, params[ ] ) {
	new rank, Float: xp;
	sscanf( params, "df", rank, xp );
	GivePlayerExperience( playerid, E_LEVELS: rank, xp );
	return 1;
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
stock GivePlayerExperience( playerid, E_LEVELS: level, Float: default_xp = 1.0 )
{
	if ( ! IsPlayerLoggedIn( playerid ) )
		return;

	// dilation is there so people see +3 when they arrest ... could trigger dopamine levels instead of constantly +1 lol
	new Float: xp_earned = ( default_xp * g_levelData[ _: level ] [ E_XP_DILATION ] ) * ( IsDoubleXP() ? 2.0 : 1.0 );

	// check if its over 100 anyway
	if ( ( g_playerExperience[ playerid ] [ level ] += xp_earned ) > g_levelData[ _: level ] [ E_MAX_UNITS ] * g_levelData[ _: level ] [ E_XP_DILATION ] ) {
		g_playerExperience[ playerid ] [ level ] = g_levelData[ _: level ] [ E_MAX_UNITS ] * g_levelData[ _: level ] [ E_XP_DILATION ];
	}

	// alert user
    PlayerTextDrawSetString( playerid, p_ExperienceAwardTD[ playerid ], sprintf( "+%0.0f", xp_earned ) );
    PlayerTextDrawShow( playerid, p_ExperienceAwardTD[ playerid ] );
	SetTimerEx( "Experience_HideIncrementTD", 3500, false, "d", playerid );

	// TODO: on level change

	// save to database
	mysql_format(
		dbHandle, szBigString, sizeof( szBigString ),
		"INSERT INTO `USER_LEVELS` (`USER_ID`,`LEVEL_ID`,`EXPERIENCE`) VALUES(%d,%d,%d) ON DUPLICATE KEY UPDATE `EXPERIENCE`=%d",
		GetPlayerAccountID( playerid ), _: level, g_playerExperience[ playerid ] [ level ], g_playerExperience[ playerid ] [ level ]
	);
}

function Experience_HideIncrementTD( playerid ) {
	return PlayerTextDrawHide( playerid, p_ExperienceAwardTD[ playerid ] );
}

stock GetPlayerTotalLevel( playerid, &level = 0 ) {
	for ( new l = 0; l < sizeof ( g_levelData ); l ++ ) {
		level += floatround( GetPlayerLevel( playerid, E_LEVELS: l ), floatround_floor );
	}
	return level;
}

/* ** Migrations ** */
/*
	CREATE TABLE IF NOT EXISTS USER_LEVELS (
		`USER_ID` int(11),
		`LEVEL_ID` int(11),
		`EXPERIENCE` float,
		PRIMARY KEY (USER_ID, LEVEL_ID),
		FOREIGN KEY (USER_ID) REFERENCES USERS (ID) ON DELETE CASCADE
	);

	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 0 as LEVEL_ID, ARRESTS * 9.0 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 1 as LEVEL_ID, ROBBERIES * 6.0 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 2 as LEVEL_ID, KILLS * 3.0 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 3 as LEVEL_ID, FIRES * 9.0 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 4 as LEVEL_ID, CONTRACTS * 4.5 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 5 as LEVEL_ID, BURGLARIES * 7.5 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 6 as LEVEL_ID, (BLEW_JAILS + BLEW_VAULT) * 6.0 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 7 as LEVEL_ID, VEHICLES_JACKED * 6.0 AS EXPERIENCE FROM USERS);
	INSERT INTO USER_LEVELS (USER_ID, LEVEL_ID, EXPERIENCE) (SELECT ID as USER_ID, 8 as LEVEL_ID, (METH_YIELDED + (TRUCKED*0.33)) * 6.0 AS EXPERIENCE FROM USERS);
	DELETE FROM USER_LEVELS WHERE EXPERIENCE = 0;
 */
