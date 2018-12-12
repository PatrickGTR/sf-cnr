/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\player\weapon_stats.pwn
 * Purpose: kill counting system for player weapon kills
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock
	p_WeaponKills					[ MAX_PLAYERS ] [ MAX_WEAPONS ];

/* ** Commands ** */
CMD:weaponstats( playerid, params[ ] ) {
	return WeaponStats_ShowPlayer( playerid );
}

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	for ( new i = 0; i < MAX_WEAPONS; i ++ ) {
		p_WeaponKills[ playerid ] [ i ] = 0;
	}
	return 1;
}

hook OnPlayerLogin( playerid )
{
	format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `WEAPON_STATS` WHERE `USER_ID`=%d", GetPlayerAccountID( playerid ) );
	mysql_function_query( dbHandle, szNormalString, true, "OnWeaponStatsLoad", "d", playerid );
	return 1;
}

/* ** SQL Threads ** */
thread OnWeaponStatsLoad( playerid )
{
	if ( ! IsPlayerConnected( playerid ) )
		return 0;

	new
		rows, fields, i = -1, weaponid;

	cache_get_data( rows, fields );

	if ( rows ) {
		while( ++i < rows ) {
			// Assign streak
			weaponid = cache_get_field_content_int( i, "WEAPON_ID", dbHandle );

			// Check if streak is valid and then insert
			if ( weaponid < sizeof( p_WeaponKills[ ] ) )
				p_WeaponKills[ playerid ] [ weaponid ] = cache_get_field_content_int( i, "KILLS", dbHandle );
		}
	}
	return 1;
}

thread OnShowWeaponStats( playerid, dialogid, back_option, forid )
{
	new
		rows;

    cache_get_data( rows, tmpVariable );

	if ( rows )
	{
		szLargeString = ""COL_WHITE"Weapon\t"COL_WHITE"Kills\n";

    	for( new i = 0; i < rows; i++ )
		{
			new
				weaponid = cache_get_field_content_int( i, "WEAPON_ID" ),
				streak = cache_get_field_content_int( i, "KILLS" );

			format( szLargeString, sizeof( szLargeString ), "%s%s\t%d\n", szLargeString, ReturnWeaponName( weaponid ), streak );
		}
		return ShowPlayerDialog( forid, DIALOG_NULL, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Weapon Statistics", szLargeString, "Okay", back_option ? ( "Back" ) : ( "" ) );
	}
	else
	{
		return SendError( forid, "Kill someone with anything to display a statistic!" );
	}
}

/* ** Functions ** */
stock WeaponStats_IncrementKill( playerid, weaponid, increment = 1 )
{
	if ( 0 <= weaponid < MAX_WEAPONS )
	{
		p_WeaponKills[ playerid ] [ weaponid ] += increment;

		format( szBigString, 196, "INSERT INTO `WEAPON_STATS` (`USER_ID`,`WEAPON_ID`,`KILLS`) VALUES(%d,%d,%d) ON DUPLICATE KEY UPDATE `KILLS`=%d;", p_AccountID[ playerid ], weaponid, p_WeaponKills[ playerid ] [ weaponid ], p_WeaponKills[ playerid ] [ weaponid ] );
		mysql_single_query( szBigString );
	}
}

stock WeaponStats_ShowPlayer( playerid, dialogid = DIALOG_NULL, bool: back_option = false, forid = INVALID_PLAYER_ID )
{
	if ( ! IsPlayerConnected( forid ) ) {
		forid = playerid;
	}
	format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `WEAPON_STATS` WHERE `USER_ID`=%d ORDER BY `KILLS` DESC", p_AccountID[ playerid ] );
	return mysql_function_query( dbHandle, szNormalString, true, "OnShowWeaponStats", "dddd", playerid, dialogid, back_option, forid );
}
