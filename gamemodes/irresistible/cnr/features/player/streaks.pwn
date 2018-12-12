/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\player\streaks.pwn
 * Purpose: streak counting system for players
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_STREAKS 				( 3 ) // Changing order will require change in UCP seasonal page.

/* ** Variables ** */
enum
{
	STREAK_ROBBERY,
	STREAK_ARREST,
	STREAK_KILL
};

enum E_STREAK_DATA
{
	E_STREAK, 					E_BEST_STREAK
};

static stock
	g_streaksTypes 					[ MAX_STREAKS ] [ 8 ] = { "robbery", "arrest", "kill" },
	p_streakData 					[ MAX_PLAYERS ] [ MAX_STREAKS ] [ E_STREAK_DATA ]
;

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	for ( new i = 0; i < MAX_STREAKS; i ++ ) {
		p_streakData[ playerid ] [ i ] [ E_BEST_STREAK ] = 0;
		p_streakData[ playerid ] [ i ] [ E_STREAK ] = 0;
	}
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	for ( new i = 0; i < MAX_STREAKS; i ++ ) {
		p_streakData[ playerid ] [ i ] [ E_STREAK ] = 0;
	}
	return 1;
}

hook OnPlayerLogin( playerid )
{
	format( szNormalString, sizeof( szNormalString ), "SELECT * FROM `STREAKS` WHERE `USER_ID`=%d", GetPlayerAccountID( playerid ) );
	mysql_function_query( dbHandle, szNormalString, true, "OnStreaksLoad", "d", playerid );
	return 1;
}

/* ** Commands ** */
CMD:streaks( playerid, params[ ] ) {
	return Streak_ShowPlayer( playerid );
}

/* ** SQL Threads ** */
thread OnStreaksLoad( playerid )
{
	if ( ! IsPlayerConnected( playerid ) )
		return 0;

	new
		rows, fields, i = -1,
		streakid, streak
	;

	cache_get_data( rows, fields );
	if ( rows ) {
		while( ++i < rows ) {
			// Assign streak
			streakid = cache_get_field_content_int( i, "STREAK_ID", dbHandle );
			streak = cache_get_field_content_int( i, "STREAK", dbHandle );

			// Check if streak is valid and then insert
			if ( streakid < MAX_STREAKS )
				p_streakData[ playerid ] [ streakid ] [ E_BEST_STREAK ] = streak;
		}
	}
	return 1;
}

/* ** Functions ** */
stock Streak_ShowPlayer( playerid, dialogid = DIALOG_NULL, szSecondButton[ ] = "", forid = INVALID_PLAYER_ID ) {

	szLargeString = ""COL_WHITE"Streak\t"COL_WHITE"Best Streak\t"COL_WHITE"Current Streak\n";

	for( new streakid = 0, szStreak[ 8 ]; streakid < MAX_STREAKS; streakid++ ) {
		szStreak = g_streaksTypes[ streakid ];
		szStreak[ 0 ] = toupper( szStreak[ 0 ] );

		format( szLargeString, 512, "%s%s\t%d\t%d\n", szLargeString, szStreak, p_streakData[ playerid ] [ streakid ] [ E_BEST_STREAK ], p_streakData[ playerid ] [ streakid ] [ E_STREAK ] );
	}

	if ( !IsPlayerConnected( forid ) )
		forid = playerid;

	return ShowPlayerDialog( forid, dialogid, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Best Streaks", szLargeString, "Okay", szSecondButton );
}

stock Streak_IncrementPlayerStreak( playerid, streakid ) {

	if ( ++p_streakData[ playerid ] [ streakid ] [ E_STREAK ] > p_streakData[ playerid ] [ streakid ] [ E_BEST_STREAK ] ) {
		p_streakData[ playerid ] [ streakid ] [ E_BEST_STREAK ] = p_streakData[ playerid ] [ streakid ] [ E_STREAK ];

		format( szBigString, 196, "INSERT INTO `STREAKS` (`USER_ID`,`STREAK_ID`,`STREAK`) VALUES(%d,%d,%d) ON DUPLICATE KEY UPDATE `STREAK`=%d;", p_AccountID[ playerid ], streakid, p_streakData[ playerid ] [ streakid ] [ E_BEST_STREAK ], p_streakData[ playerid ] [ streakid ] [ E_BEST_STREAK ] );
		mysql_single_query( szBigString );

		// Notify oneself
		SendServerMessage( playerid, "You are currently on your best "COL_GOLD"%s streak"COL_WHITE" of %d!", g_streaksTypes[ streakid ], p_streakData[ playerid ] [ streakid ] [ E_BEST_STREAK ] );

		// Beep
		Beep( playerid );
	}

	// Notify whole chat
	new
		iModulus = 10;

	if ( p_streakData[ playerid ] [ streakid ] [ E_STREAK ] > 50 )
		iModulus = 1;

	else if ( p_streakData[ playerid ] [ streakid ] [ E_STREAK ] > 20 )
		iModulus = 5;

	if ( p_streakData[ playerid ] [ streakid ] [ E_STREAK ] % iModulus == 0 ) {
		if ( p_streakData[ playerid ] [ streakid ] [ E_STREAK ] == p_streakData[ playerid ] [ streakid ] [ E_BEST_STREAK ] ) {
			SendGlobalMessage( -1, ""COL_GOLD"[STREAK]{FFFFFF} %s(%d) is currently on their best "COL_GOLD"%s streak"COL_WHITE" of %d!", ReturnPlayerName( playerid ), playerid, g_streaksTypes[ streakid ], p_streakData[ playerid ] [ streakid ] [ E_BEST_STREAK ] );
		} else {
			SendGlobalMessage( -1, ""COL_GOLD"[STREAK]{FFFFFF} %s(%d) is currently on a "COL_GOLD"%s streak"COL_WHITE" of %d!", ReturnPlayerName( playerid ), playerid, g_streaksTypes[ streakid ], p_streakData[ playerid ] [ streakid ] [ E_STREAK ] );
		}
	}
}
