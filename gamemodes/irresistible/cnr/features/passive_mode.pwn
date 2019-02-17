/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\passive_mode.pwn
 * Purpose: passive mode feature (and anti-spawn kill)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Variables ** */
static stock
	Text3D: p_SpawnKillLabel		[ MAX_PLAYERS ] = { Text3D: INVALID_3DTEXT_ID, ... },
	p_AntiSpawnKill                 [ MAX_PLAYERS ],
    bool: p_AntiSpawnKillEnabled	[ MAX_PLAYERS char ]
;

/* ** Hooks ** */
hook OnPlayerUpdateEx( playerid )
{
    // Remove Anti-Spawn Kill
    if ( p_AntiSpawnKillEnabled{ playerid } && g_iTime > p_AntiSpawnKill[ playerid ] ) {
        DisablePlayerSpawnProtection( playerid );
    }
	if ( GetPlayerWantedLevel( playerid ) > 0 )
	{
		if ( IsPassivePlayerInVehicle( GetPlayerVehicleID( playerid ) ) )
		{
			SyncObject( playerid );
			SendError( playerid, "You cannot enter vehicles with passive players in it as a wanted criminal." );
		}
	}
    return 1;
}

hook OnPlayerSpawn( playerid )
{
	if ( ! IsPlayerInPaintBall( playerid ) )
	{
	    // Toggle Anti Spawn Kill
		DisableRemoteVehicleCollisions( playerid, p_AdminOnDuty{ playerid } );
		SetPlayerHealth( playerid, INVALID_PLAYER_ID );
		Delete3DTextLabel( p_SpawnKillLabel[ playerid ] );
		p_SpawnKillLabel[ playerid ] = Create3DTextLabel( "Spawn Protected!", COLOR_GOLD, 0.0, 0.0, 0.0, 15.0, 0 );
		p_AntiSpawnKill[ playerid ] = g_iTime + 15;
	    Attach3DTextLabelToPlayer( p_SpawnKillLabel[ playerid ], playerid, 0.0, 0.0, 0.3 );
	    p_AntiSpawnKillEnabled{ playerid } = true;

	    // Toggle Passive Mode
		SetPlayerPassiveMode( playerid );
	}
    return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	ResetPlayerPassiveMode( playerid );
	Delete3DTextLabel( p_SpawnKillLabel[ playerid ] );
	p_SpawnKillLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	p_AntiSpawnKillEnabled{ playerid } = false;
    return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
    ResetPlayerPassiveMode( playerid );
    return 1;
}

hook OnPlayerUnjailed( playerid, reasonid )
{
	SetPlayerPassiveMode( playerid );
    return 1;
}

hook OnPlayerEnterVehicle( playerid, vehicleid, ispassenger )
{

	if ( IsPlayerPassive( playerid ) )
	{
		if ( IsWantedPlayerInVehicle( vehicleid ) )
		{
			SetPlayerWantedLevel( playerid, 6 );
			ShowPlayerHelpDialog( playerid, 3000, "You are now considered wanted for associating yourself with a wanted player." );
			return 1;
		}
	}
	return 1;

}

/* ** Functions ** */
stock GivePassivePassengersWanted( playerid, vehicleid )
{
	foreach( new pID : Player )
	{
		if ( !IsPlayerPassive( pID ) || IsPlayerNPC( pID ) || pID == playerid )
			continue;

		if ( GetPlayerVehicleID( pID ) == vehicleid )
		{
			SetPlayerWantedLevel( pID, 6 );
			ShowPlayerHelpDialog( pID, 3000, "You are now considered wanted for associating yourself with a wanted player." );
		}
	}
	return true;
}

stock IsPassivePlayerInVehicle( vehicleid )
{
	foreach ( new pID : Player )
	{
		if ( !IsPlayerPassive( pID ) || !IsPlayerInAnyVehicle( pID ) )
			continue;

		if ( GetPlayerVehicleID( pID ) == vehicleid )
			return true;
	}
	return false;
}

stock DisablePlayerSpawnProtection( playerid, Float: default_health = 100.0 )
{
	if ( p_AntiSpawnKillEnabled{ playerid } )
	{
		SetPlayerHealth( playerid, p_AdminOnDuty{ playerid } ? float( INVALID_PLAYER_ID ) : default_health );
		DisableRemoteVehicleCollisions( playerid, p_AdminOnDuty{ playerid } );
		Delete3DTextLabel( p_SpawnKillLabel[ playerid ] );
		p_SpawnKillLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
		p_AntiSpawnKillEnabled{ playerid } = false;
	}
	return 1;
}

stock SetPlayerPassiveMode( playerid )
{
	if ( IsPlayerSettingToggled( playerid, SETTING_PASSIVE_MODE ) )
	{
		ResetPlayerPassiveMode( playerid, .passive_disabled = true );
		return 0;
	}

	// reset any labels etc
	ResetPlayerPassiveMode( playerid );

	// place label
	if ( ! p_WantedLevel[ playerid ] && ! IsPlayerInPaintBall( playerid ) && GetPlayerClass( playerid ) != CLASS_POLICE ) {
		p_PassiveModeLabel[ playerid ] = CreateDynamic3DTextLabel( "Passive Mode", COLOR_GREEN, 0.0, 0.0, -0.6, 15.0, .attachedplayer = playerid );
		TextDrawShowForPlayer( playerid, g_PassiveModeTD );
	}
	return 1;
}

stock IsPlayerPassive( playerid )
{
	return ! p_WantedLevel[ playerid ] && p_Class[ playerid ] != CLASS_POLICE && ! p_PassiveModeDisabled{ playerid };
}

stock ResetPlayerPassiveMode( playerid, bool: passive_disabled = false )
{
	DestroyDynamic3DTextLabel( p_PassiveModeLabel[ playerid ] );
	//KillTimer( p_PassiveModeExpireTimer[ playerid ] );
	p_PassiveModeLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	//p_PassiveModeExpireTimer[ playerid ] = -1;
	p_PassiveModeDisabled{ playerid } = passive_disabled;
	TextDrawHideForPlayer( playerid, g_PassiveModeTD );
	return 1;
}

/*function PassiveMode_Reset( playerid, time_left )
{
	// if you happen to die then have a shot synced ... just reset normally
	if ( GetPlayerState( playerid ) == PLAYER_STATE_WASTED ) {
		return ResetPlayerPassiveMode( playerid );
	}

	if ( p_WantedLevel[ playerid ] > 0 || p_Class[ playerid ] != CLASS_CIVILIAN || -- time_left <= 0 )
	{
		ResetPlayerPassiveMode( playerid, .passive_disabled = true );
		ShowPlayerHelpDialog( playerid, 2000, "Passive mode is ~r~disabled." );
	}
	else
	{
    	UpdateDynamic3DTextLabelText( p_PassiveModeLabel[ playerid ], COLOR_RED, sprintf( "Passive Mode Disabled In %d Seconds", time_left ) );
		p_PassiveModeExpireTimer[ playerid ] = SetTimerEx( "PassiveMode_Reset", 980, false, "dd", playerid, time_left );
 		ShowPlayerHelpDialog( playerid, 1500, "Passive mode disabled in ~r~%d seconds.", time_left );
	}
	return 1;
}*/

stock IsPlayerSpawnProtected( playerid ) {
    return p_AntiSpawnKillEnabled{ playerid };
}