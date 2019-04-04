/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc - adjusted by Damen to remove passive mode
 * Module: cnr\features\anti-spawn_kill.pwn
 * Purpose: anti-spawn kill
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
	}
    return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	Delete3DTextLabel( p_SpawnKillLabel[ playerid ] );
	p_SpawnKillLabel[ playerid ] = Text3D: INVALID_3DTEXT_ID;
	p_AntiSpawnKillEnabled{ playerid } = false;
    return 1;
}

/* ** Functions ** */
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

stock IsPlayerSpawnProtected( playerid ) {
    return p_AntiSpawnKillEnabled{ playerid };
}