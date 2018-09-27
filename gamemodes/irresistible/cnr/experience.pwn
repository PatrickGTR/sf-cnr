/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define EXP_MAX_PLAYER_LEVEL 		( 100 )

/* ** Constants ** */
enum E_LEVELS {
	E_LAW_ENFORCEMENT,
	E_DEATHMATCH,
	E_ROBBERY,
	// E_FIREMAN,
	// E_HITMAN,
	// E_BURGLAR,
	// E_TERRORIST,
	// E_CAR_JACKER,
	// E_DRUG_PRODUCTION
};

enum E_LEVEL_DATA {
	E_LEVELS: E_LEVEL, 	Float: E_MAX_UNITS
};

static const
	g_levelData[ ] [ E_LEVEL_DATA ] =
	{
		// Level					Requirement For Level 100
		{ E_LAW_ENFORCEMENT, 		25000.0 },
		{ E_DEATHMATCH, 			200000.0 },
		{ E_ROBBERY,				100000.0 }
	}
;

/* ** Variables ** */
new
	Float: g_playerExperience		[ MAX_PLAYERS ] [ E_LEVELS ]
;

/* ** Important ** */
stock Float: GetPlayerLevel( playerid, E_LEVELS: level ) {
	return floatsqroot( g_playerExperience[ playerid ] [ level ] / ( g_levelData[ _: level ] [ E_MAX_UNITS ] / ( EXP_MAX_PLAYER_LEVEL * EXP_MAX_PLAYER_LEVEL ) ) );
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
hook OnPlayerDisconnect( playerid, reason ) {
	for ( new l = 0; l < sizeof ( g_levelData ); l ++ ) {
		g_playerExperience[ playerid ] [ E_LEVELS: l ] = 0;
	}
	return 1;
}

hook OnPlayerLogin( playerid )
{
	mysql_tquery( dbHandle, sprintf( "SELECT * FROM `USER_LEVELS` WHERE `USER_ID` = %d", GetPlayerAccountID( playerid ) ), "Experience_OnLoad", "d", playerid );
	return 1;
}

/* ** Functions ** */
stock GivePlayerExperience( playerid, E_LEVELS: level, Float: experience = 1.0 )
{
	if ( ( g_playerExperience[ playerid ] [ level ] += experience ) > g_levelData[ _: level ] [ E_MAX_UNITS ] ) {
		g_playerExperience[ playerid ] [ level ] = g_levelData[ _: level ] [ E_MAX_UNITS ];
	}

	// save to database
	mysql_format(
		dbHandle, szBigString, sizeof( szBigString ),
		"INSERT INTO `USER_LEVELS` (`USER_ID`,`LEVEL_ID`,`EXPERIENCE`) VALUES(%d,%d,%d) ON DUPLICATE KEY UPDATE `EXPERIENCE`=%d",
		GetPlayerAccountID( playerid ), _: level, g_playerExperience[ playerid ] [ level ], g_playerExperience[ playerid ] [ level ]
	);
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

/* ** Migrations ** */
/*
	CREATE TABLE IF NOT EXISTS USER_LEVELS (
		`USER_ID` int(11),
		`LEVEL_ID` int(11),
		`EXPERIENCE` float,
		PRIMARY KEY (USER_ID, LEVEL_ID),
		FOREIGN KEY (USER_ID) REFERENCES USERS (ID) ON DELETE CASCADE
	);
 */
