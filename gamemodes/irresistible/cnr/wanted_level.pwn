/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module:
 * Purpose:
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */

/* ** Variables ** */
new
   	p_WantedLevel       			[ MAX_PLAYERS ];

/* ** Hooks ** */
hook OnPlayerConnect( playerid )
{
    ClearPlayerWantedLevel( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
    ClearPlayerWantedLevel( playerid );
	return 1;
}

/* ** Hooked Functions ** */
stock CNR_GetPlayerWantedLevel( playerid )
{
	return p_WantedLevel[ playerid ]; // force the variable
}

#if defined _ALS_GetPlayerWantedLevel
    #undef GetPlayerWantedLevel
#else
    #define _ALS_GetPlayerWantedLevel
#endif

#define GetPlayerWantedLevel CNR_GetPlayerWantedLevel

stock CNR_SetPlayerWantedLevel( playerid, level )
{
    if ( ( p_WantedLevel[ playerid ] = level ) < 0 ) // prevent negative wanted level
    	p_WantedLevel[ playerid ] = 0;

	if ( p_WantedLevel[ playerid ] > 0 )
	{
		if ( IsPlayerSpawned( playerid ) )
		{
			PlayerTextDrawSetString( playerid, p_WantedLevelTD[ playerid ], sprintf( "] %d ]", p_WantedLevel[ playerid ] ) );
			if ( ! IsPlayerMovieMode( playerid ) ) PlayerTextDrawShow( playerid, p_WantedLevelTD[ playerid ] );
			ResetPlayerPassiveMode( playerid, .passive_disabled = true ); // remove passive mode if the player is wanted
		}
	}
	else
	{
		PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
		Uncuff( playerid ); // player is not wanted, so auto uncuff
	}

	// regulate player color
	SetPlayerColorToTeam( playerid );

	/*if ( p_WantedLevel[ playerid ] > 2000 ) { // 8hska7082bmahu
		p_WantedLevel[ playerid ] = 2000;
		SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[WANTED LEVEL]{FFFFFF} Your wanted level has reached its maximum. Further wanted levels will not append.", wantedlevel, p_WantedLevel[ playerid ] );

		format( szBigString, 256, "[0xA1] %s(%d) :: %d :: %d\r\n", ReturnPlayerName( playerid ), playerid, p_WantedLevel[ playerid ], g_iTime );
	    AddFileLogLine( "security.txt", szBigString );
		return 1;
	}*/

	// set it to the variable value
	return SetPlayerWantedLevel( playerid, p_WantedLevel[ playerid ] );
}

#if defined _ALS_SetPlayerWantedLevel
    #undef SetPlayerWantedLevel
#else
    #define _ALS_SetPlayerWantedLevel
#endif

#define SetPlayerWantedLevel CNR_SetPlayerWantedLevel

/* ** Functions ** */
stock GivePlayerWantedLevel( playerid, level )
{
	if ( ! IsPlayerConnected( playerid ) || IsPlayerNPC( playerid ) || IsPlayerJailed( playerid ) || level == 0 )
	    return 0;

	new
		current_wanted = GetPlayerWantedLevel( playerid );

	SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[CRIME]{FFFFFF} Your wanted level has been %s by %d! Wanted level: %d", current_wanted + level > current_wanted ? ( "increased" ) : ( "decreased" ), level < 0 ? level * -1 : level, current_wanted );
	return SetPlayerWantedLevel( playerid, current_wanted + level );
}

stock ClearPlayerWantedLevel( playerid )
{
	PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
    p_WantedLevel[ playerid ] = 0;
	SetPlayerWantedLevel( playerid, 0 );
	SetPlayerColorToTeam( playerid );
}
