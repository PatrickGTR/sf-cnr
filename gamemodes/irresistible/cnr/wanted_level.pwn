/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc, Stev
 * Module: cnr\wanted_level.pwn
 * Purpose: server-sided wanted level system (hooks the natives)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_WANTED_LVL 				2048

/* ** Variables ** */
new stock
   	p_WantedLevel       			[ MAX_PLAYERS ];

/* ** Hooks ** */
hook OnPlayerConnect( playerid )
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
		}
	}
	else
	{
		PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
		Uncuff( playerid ); // player is not wanted, so auto uncuff
	}

	// regulate player color
	SetPlayerColorToTeam( playerid );

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
	if ( ! IsPlayerConnected( playerid ) || IsPlayerNPC( playerid ) || IsPlayerJailed( playerid ) || IsPlayerDueling( playerid ) || level == 0 )
	    return 0;
	
	new
		current_wanted = GetPlayerWantedLevel( playerid );

	SendClientMessageFormatted( playerid, -1, ""COL_GOLD"[CRIME]{FFFFFF} Your wanted level has been %s by %d! Wanted level: %d", current_wanted + level > current_wanted ? ( "increased" ) : ( "decreased" ), level, current_wanted + level );
	return SetPlayerWantedLevel( playerid, current_wanted + level );
}


stock ClearPlayerWantedLevel( playerid )
{
	PlayerTextDrawHide( playerid, p_WantedLevelTD[ playerid ] );
    p_WantedLevel[ playerid ] = 0;
	SetPlayerWantedLevel( playerid, 0 );
	SetPlayerColorToTeam( playerid );
}

stock IsWantedPlayerInVehicle( vehicleid )
{
	foreach ( new pID : Player )
	{
		if ( GetPlayerVehicleID( pID ) == vehicleid && GetPlayerWantedLevel( pID ) > 1 )
			return true;
	}
	return false;
}