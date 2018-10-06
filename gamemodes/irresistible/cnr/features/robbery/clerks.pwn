/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\robbery\clerks.pwn
 * Purpose: NPC (aim to rob) robbery system
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >
#include 							< FCNPC >

/* ** Definitions ** */
#define ENABLED_NPC_ROBBERIES		( true )
#define MAX_ROBBERY_NPCS 			( MAX_ROBBERIES ) // ( 50 )
#define MAX_CIVILIANS				( 50 )

/* ** Variables ** */
enum E_ROBBERY_NPC_DATA
{
	E_NPC_NAME[ 24 ], 				E_NPC_ID,						E_TIMEOUT,
	E_HOLDUP_TIMER,					bool: E_PROVOKED,				Float: E_RZ,
 	E_WORLD,						E_MAX_LOOT, 					E_LOOT,
 	Text3D: E_LABEL,				E_SHOOTING_TIMER,				Float: E_SHOOTING_OFFSET
};

enum E_CIVILIAN_DATA
{
	E_CLERK_ID,						E_NPC_ID,						E_NPC_NAME[ 24 ],
	E_WEAPON_ID,					E_ANIM_LIB[ 16 ], 				E_ANIM_NAME[ 16 ],
	E_WORLD, E_INTERIOR, 			Float: E_RZ, 					bool: E_HOSTILE,
	bool: E_PROVOKED, 				E_TIMEOUT
};

static stock
	g_robberyNpcData				[ MAX_ROBBERY_NPCS ] [ E_ROBBERY_NPC_DATA ],
	Iterator: RobberyNpc 			< MAX_ROBBERY_NPCS >,

	g_civilianNpcData 				[ MAX_CIVILIANS ] [ E_CIVILIAN_DATA ],
	Iterator:CivilianNpc 			< MAX_CIVILIANS >
;

/* ** Hooks ** */
hook OnServerUpdate( )
{
	// Replenish NPC Robberies
	foreach ( new clerkid : RobberyNpc ) if ( g_iTime > g_robberyNpcData[ clerkid ] [ E_TIMEOUT ] && ! g_robberyNpcData[ clerkid ] [ E_LOOT ] ) {
		ReplenishRobberyNpc( clerkid );
	}

	// Make civilians react
	foreach (new civilianid : CivilianNpc)
	{
		if ( g_civilianNpcData[ civilianid ] [ E_HOSTILE ] && g_civilianNpcData[ civilianid ] [ E_PROVOKED ] )
		{
			new
				Float: distance = FLOAT_INFINITY,
				closestid = GetClosestPlayer( g_civilianNpcData[ civilianid ] [ E_NPC_ID ], distance );

			if ( IsPlayerConnected( closestid ) && 0.0 < distance < 5625 )
				FCNPC_AimAtPlayer( g_civilianNpcData[ civilianid ] [ E_NPC_ID ], closestid, .shoot = true );

			else
			{
				if ( ! g_civilianNpcData[ civilianid ] [ E_TIMEOUT ] )
					g_civilianNpcData[ civilianid ] [ E_TIMEOUT ] = g_iTime + 30;

				if ( g_civilianNpcData[ civilianid ] [ E_TIMEOUT ] != 0 && g_iTime > g_civilianNpcData[ civilianid ] [ E_TIMEOUT ] ) {
					// Reset civilian variables
					g_civilianNpcData[ civilianid ] [ E_TIMEOUT ] = 0;
					g_civilianNpcData[ civilianid ] [ E_PROVOKED ] = false;

					// Respawn
					if ( FCNPC_IsDead( g_civilianNpcData[ civilianid ] [ E_NPC_ID ] ) ) {
						FCNPC_Respawn( g_civilianNpcData[ civilianid ] [ E_NPC_ID ] );
					} else {
						FCNPC_NeutralState( g_civilianNpcData[ civilianid ] [ E_NPC_ID ] );
						FCNPC_SetAngle( g_civilianNpcData[ civilianid ] [ E_NPC_ID ], g_civilianNpcData[ civilianid ] [ E_RZ ] );
					}
				}
			}
		}
	}
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	if ( IsPlayerSpawned( playerid ) )
	{
		new
			aiming_player = GetPlayerTargetPlayer( playerid );

		if ( FCNPC_IsValid( aiming_player ) && p_Class[ playerid ] != CLASS_POLICE )
		{
			new clerkid = GetRobberyNpcFromPlayer( aiming_player );

			if ( clerkid != -1 )
			{
				new weaponid = GetPlayerWeapon( playerid );
				new Float: distance = GetDistanceBetweenPlayers( playerid, aiming_player, .bAllowNpc = true );
				new is_melee = ( weaponid == 0 || weaponid == 1 || weaponid == 7 || 10 <= weaponid <= 18 );

				if ( g_robberyNpcData[ clerkid ] [ E_TIMEOUT ] < g_iTime && g_robberyNpcData[ clerkid ] [ E_HOLDUP_TIMER ] == -1 && g_robberyNpcData[ clerkid ] [ E_LOOT ] && ! g_robberyNpcData[ clerkid ] [ E_PROVOKED ] && distance < 10.0 && ! is_melee )
				{
					GivePlayerWantedLevel( playerid, 6 );
					PlayerTextDrawSetString( playerid, p_RobberyRiskTD[ playerid ], "~y~~h~Clerk is confused" );
					PlayerTextDrawShow( playerid, p_RobberyRiskTD[ playerid ] );
					PlayerTextDrawSetString( playerid, p_RobberyAmountTD[ playerid ], "Robbed ~g~~h~$0" );
					PlayerTextDrawShow( playerid, p_RobberyAmountTD[ playerid ] );

					FCNPC_ApplyAnimation( aiming_player, "SHOP", "SHP_Rob_React", 4.1, 0, 1, 1, 1, 0 );
					FCNPC_SetAnimationByName( aiming_player, "SHOP:SHP_Rob_React", 4.1, 0, 1, 1, 1, 0 );
					g_robberyNpcData[ clerkid ] [ E_HOLDUP_TIMER ] = SetTimerEx( "OnPlayerHoldupStore", 2300, false, "ddd", playerid, clerkid, 0 );

					TriggerClosestCivilians( playerid, clerkid );
				}
			}
			else
			{
				new
					civilianid = GetCivilianNpcFromPlayer( aiming_player );

				if ( civilianid != -1 ) {
					TriggerClosestCivilians( playerid, GetClosestRobberyNPC( getClosestRobberySafe( playerid ) ) );
				}
			}
		}
	}
	return 1;
}

hook OnNpcConnect( npcid )
{
	static
		npc_ip[ 16 ];

    GetPlayerIp( npcid, npc_ip, sizeof( npc_ip ) );

	if ( strmatch( npc_ip, "127.0.0.1" ) ) {
		SetPlayerColor( npcid, 0xFFFFFF20 );
		return Y_HOOKS_BREAK_RETURN_1;
	}
	return 1;
}

hook FCNPC_OnDeath( npcid, killerid, weaponid )
{
	if ( !IsPlayerConnected( killerid ) )
		return 1;

	new
		clerkid = GetRobberyNpcFromPlayer( npcid )
	;

	if ( 0 <= clerkid < MAX_ROBBERY_NPCS )
	{
		StopPlayerNpcRobbery( killerid, clerkid, .cower = false );

		if ( g_robberyNpcData[ clerkid ] [ E_PROVOKED ] )
			return 1;

	    new
			szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ];

		if ( GetPlayerLocation( killerid, szCity, szLocation ) )
			SendClientMessageToCops( -1, ""COL_BLUE"[POLICE RADIO]"COL_WHITE" %s has murdered "COL_GREY"%s"COL_WHITE" near %s in %s.", ReturnPlayerName( killerid ), g_robberyNpcData[ clerkid ] [ E_NPC_NAME ], szLocation, szCity );
		else
			SendClientMessageToCops( -1, ""COL_BLUE"[POLICE RADIO]"COL_WHITE" %s has murdered "COL_GREY"%s"COL_WHITE".", ReturnPlayerName( killerid ), g_robberyNpcData[ clerkid ] [ E_NPC_NAME ] );

		CreateCrimeReport( killerid );
		GivePlayerWantedLevel( killerid, 6 );
		SendServerMessage( killerid, "You have killed the clerk! "COL_RED"The cops have been informed." );
	}
	return 1;
}

hook FCNPC_OnSpawn( npcid )
{
	new
		clerkid = GetRobberyNpcFromPlayer( npcid );

	if ( 0 <= clerkid < MAX_ROBBERY_NPCS )
	{
		FCNPC_ApplyAnimation( npcid, "SHOP", "null", 0.0, 0, 0, 0, 0, 0 );
		FCNPC_ApplyAnimation( npcid, "PED", "null", 0.0, 0, 0, 0, 0, 0 );
		FCNPC_SetVirtualWorld( g_robberyNpcData[ clerkid ] [ E_NPC_ID ], g_robberyNpcData[ clerkid ] [ E_WORLD ] );
	}
	else
	{
		new
			civilianid = GetCivilianNpcFromPlayer( npcid );

		if ( 0 <= civilianid < MAX_CIVILIANS )
		{
			FCNPC_SetVirtualWorld( npcid, g_civilianNpcData[ civilianid ] [ E_WORLD ] );
			FCNPC_SetInterior( npcid, g_civilianNpcData[ civilianid ] [ E_INTERIOR ] );

			// animations
			FCNPC_ApplyAnimation( npcid, g_civilianNpcData[ civilianid ] [ E_ANIM_LIB ], "null", 0.0, 0, 0, 0, 0, 0 );
			FCNPC_ApplyAnimation( npcid, g_civilianNpcData[ civilianid ] [ E_ANIM_LIB ], g_civilianNpcData[ civilianid ] [ E_ANIM_NAME ], 3.0, 1, 1, 1, 1, 0 );
			FCNPC_SetAnimationByName( npcid, sprintf( "%s:%s", g_civilianNpcData[ civilianid ] [ E_ANIM_LIB ], g_civilianNpcData[ civilianid ] [ E_ANIM_NAME ] ), 3.0, 1, 1, 1, 1, 0 );
		}
	}
	return 1;
}

hook FCNPC_OnTakeDamage( npcid, damagerid, weaponid, bodypart, Float: health_loss )
{
	new civilianid = GetCivilianNpcFromPlayer( npcid );
	new clerkid = GetRobberyNpcFromPlayer( npcid );

	// trigger npcs
	if ( civilianid != -1 ) {
		TriggerClosestCivilians( damagerid, GetClosestRobberyNPC( getClosestRobberySafe( damagerid ) ) );
	}

	// no damage for bots
	if ( 0 <= clerkid < MAX_ROBBERY_NPCS && 0 <= damagerid < MAX_PLAYERS && p_Class[ damagerid ] == CLASS_POLICE ) {
		return 0;
	}
	return 1;
}

/* ** Functions ** */
stock CreateRobberyNPC( name[ ], max_loot, Float: X, Float: Y, Float: Z, Float: rZ, skinid, ... )
{
	static const
		Float: drugDealerPositions[ 5 ] [ 2 ] [ 4 ] =
		{
			// Fiddle
			{
				{ 2182.2810, -1204.4282, 1049.0234, 91.1168 },
				{ 2194.7588, -1201.1827, 1049.0234, 313.135 }
			},

			// Lean
			{
				{ 2194.5054, -1207.9854, 1049.0234, 360.0000 },
				{ 2187.7302, -1206.4150, 1049.0308, 270.0000 }
			},

			// Lay
			{
				{ 2191.0098, -1206.1421, 1049.5361, 41.4342 },
				{ 2195.3901, -1206.0587, 1049.5361, 317.403 }
			},

			// Leaning
			{
				{ 2196.0134, -1218.3213, 1049.0234, 270.0000 },
				{ 2196.0159, -1213.3755, 1049.0234, 270.0000 }
			},

			// Cross arms
			{
				{ 2193.2097, -1219.9078, 1049.0234, 1.4630 },
				{ 2191.6738, -1214.6738, 1049.0234, 270.7185 }
			}
		}
	;

	new
		szBotName[ MAX_PLAYER_NAME ];

	format( szBotName, sizeof( szBotName ), "%s", name );
	strreplacechar( szBotName, ' ', '\0' );
	strreplacechar( szBotName, '/', '\0' );

	for( new i = 7; i < numargs( ); i++ )
    {
		new
			clerkid = Iter_Free(RobberyNpc);

		if ( clerkid != ITER_NONE )
		{
			new
				randomMaxLoot = RandomEx( max_loot - 100, max_loot + 100 ),
				worldid = getarg( i );

			Iter_Add(RobberyNpc, clerkid);

			if ( strlen( worldid != -1 ? sprintf( "[BOT]%s%d", szBotName, clerkid ) : sprintf( "[BOT]%s", szBotName )  ) >= MAX_PLAYER_NAME )
				printf( "Warning: NPC name is too long (%s)", worldid != -1 ? sprintf( "[BOT]%s%d", szBotName, clerkid ) : sprintf( "[BOT]%s", szBotName ) );

			format( g_robberyNpcData[ clerkid ] [ E_NPC_NAME ], MAX_PLAYER_NAME, "%s", name );
			g_robberyNpcData[ clerkid ] [ E_LABEL ] = CreateDynamic3DTextLabel( sprintf( "%s\n"COL_WHITE"Aim To Start Robbery", name ), COLOR_GOLD, X, Y, Z, 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0, .worldid = worldid );
			g_robberyNpcData[ clerkid ] [ E_NPC_ID ] = FCNPC_Create( worldid != -1 ? sprintf( "[BOT]%s%d", szBotName, clerkid ) : sprintf( "[BOT]%s", szBotName ) );
			g_robberyNpcData[ clerkid ] [ E_WORLD ] = worldid == -1 ? 0 : worldid;
			g_robberyNpcData[ clerkid ] [ E_HOLDUP_TIMER ] = -1;
			g_robberyNpcData[ clerkid ] [ E_MAX_LOOT ] = randomMaxLoot;
			g_robberyNpcData[ clerkid ] [ E_LOOT ] = randomMaxLoot;
			g_robberyNpcData[ clerkid ] [ E_SHOOTING_TIMER ] = -1;
			FCNPC_Spawn( g_robberyNpcData[ clerkid ] [ E_NPC_ID ], skinid, X, Y, Z );
			FCNPC_SetAngle( g_robberyNpcData[ clerkid ] [ E_NPC_ID ], ( g_robberyNpcData[ clerkid ] [ E_RZ ] = rZ ) );

			// Create Civilians
			if ( strmatch( name, "Triad Boss" ) )
			{
				CreateCivilianNpc( "Triad", { 117, 118, 121, 122, 123 }, clerkid, "INT_HOUSE", "wash_up", drugDealerPositions[ 0 ] [ random( sizeof( drugDealerPositions[ ] ) ) ], worldid, .interior = 6 );
				CreateCivilianNpc( "Triad", { 117, 118, 121, 122, 123 }, clerkid, "GANGS", "leanIDLE", drugDealerPositions[ 1 ] [ random( sizeof( drugDealerPositions[ ] ) ) ], worldid, .interior = 6 );
				CreateCivilianNpc( "Triad", { 117, 118, 121, 122, 123 }, clerkid, "BEACH", "bather", drugDealerPositions[ 2 ] [ random( sizeof( drugDealerPositions[ ] ) ) ], worldid, .interior = 6 );
				CreateCivilianNpc( "Triad", { 117, 118, 121, 122, 123 }, clerkid, "GANGS", "leanIDLE", drugDealerPositions[ 3 ] [ random( sizeof( drugDealerPositions[ ] ) ) ], worldid, .interior = 6 );
				CreateCivilianNpc( "Triad", { 117, 118, 121, 122, 123 }, clerkid, "COP_AMBIENT", "Coplook_loop", drugDealerPositions[ 4 ] [ random( sizeof( drugDealerPositions[ ] ) ) ], worldid, .interior = 6 );
			}
			else if ( strmatch( name, "Mafia Boss" ) )
			{
				CreateCivilianNpc( "Soldier", { 111, 112, 124, 125, 126, 127 }, clerkid, "INT_HOUSE", "wash_up", drugDealerPositions[ 0 ] [ random( sizeof( drugDealerPositions[ ] ) ) ], worldid, .interior = 6 );
				CreateCivilianNpc( "Soldier", { 111, 112, 124, 125, 126, 127 }, clerkid, "GANGS", "leanIDLE", drugDealerPositions[ 1 ] [ random( sizeof( drugDealerPositions[ ] ) ) ], worldid, .interior = 6 );
				CreateCivilianNpc( "Soldier", { 111, 112, 124, 125, 126, 127 }, clerkid, "BEACH", "bather", drugDealerPositions[ 2 ] [ random( sizeof( drugDealerPositions[ ] ) ) ], worldid, .interior = 6 );
				CreateCivilianNpc( "Soldier", { 111, 112, 124, 125, 126, 127 }, clerkid, "GANGS", "leanIDLE", drugDealerPositions[ 3 ] [ random( sizeof( drugDealerPositions[ ] ) ) ], worldid, .interior = 6 );
				CreateCivilianNpc( "Soldier", { 111, 112, 124, 125, 126, 127 }, clerkid, "COP_AMBIENT", "Coplook_loop", drugDealerPositions[ 4 ] [ random( sizeof( drugDealerPositions[ ] ) ) ], worldid, .interior = 6 );
			}
			else if ( strmatch( name, "Militia Boss" ) )
			{
				CreateCivilianNpc( "Militia", { 125, 127, 272, 273, 299 }, clerkid, "COP_AMBIENT", "Coplook_loop", Float: { -2379.767333, 1554.927001, 2.117187, -150.0000 }, 0, 0 );
				CreateCivilianNpc( "Militia", { 125, 127, 272, 273, 299 }, clerkid, "COP_AMBIENT", "Coplook_think", Float: { -2422.314697, 1549.529541, 2.117187, 120.00000 }, 0, 0 );
				CreateCivilianNpc( "Militia", { 125, 127, 272, 273, 299 }, clerkid, "COP_AMBIENT", "Coplook_watch", Float: { -2417.101562, 1546.823608, 2.117187, 79.399986 }, 0, 0 );
				CreateCivilianNpc( "Militia", { 125, 127, 272, 273, 299 }, clerkid, "COP_AMBIENT", "Coplook_think", Float: { -2402.885986, 1550.987548, 2.117187, 99.200134 }, 0, 0 );
				CreateCivilianNpc( "Militia", { 125, 127, 272, 273, 299 }, clerkid, "COP_AMBIENT", "Coplook_loop", Float: { -2389.123535, 1552.664794, 2.117187, 132.69992 }, 0, 0 );
				CreateCivilianNpc( "Militia", { 125, 127, 272, 273, 299 }, clerkid, "COP_AMBIENT", "Coplook_watch", Float: { -2400.807861, 1544.349975, 2.117187, -75.30000 }, 0, 0 );
				CreateCivilianNpc( "Militia", { 125, 127, 272, 273, 299 }, clerkid, "COP_AMBIENT", "Coplook_loop", Float: { -2394.430664, 1536.986572, 2.117187, 96.699829 }, 0, 0 );
			}
		}
	}
}

stock ReplenishRobberyNpc( clerkid, bool: fullreplenish = true )
{
	if ( 0 <= clerkid < MAX_ROBBERY_NPCS )
	{
		new
			Float: X, Float: Y, Float: Z,
			npcid = g_robberyNpcData[ clerkid ] [ E_NPC_ID ];

		// Get NPC Pos
		GetPlayerPos( npcid, X, Y, Z );

		// Reset NPC
		if ( FCNPC_IsDead( npcid ) ) {
			FCNPC_Respawn( npcid );
		} else {
			FCNPC_NeutralState( npcid );
			FCNPC_SetAngle( npcid, g_robberyNpcData[ clerkid ] [ E_RZ ] );
		}

		// Make NPC vulernable
		FCNPC_SetInvulnerable( npcid, false );

		// Reset NPC Data
		g_robberyNpcData[ clerkid ] [ E_LOOT ] = 0;
		g_robberyNpcData[ clerkid ] [ E_TIMEOUT ] = 0;
		g_robberyNpcData[ clerkid ] [ E_PROVOKED ] = false;

		KillTimer( g_robberyNpcData[ clerkid ] [ E_HOLDUP_TIMER ] ), g_robberyNpcData[ clerkid ] [ E_HOLDUP_TIMER ] = -1;
		UpdateDynamic3DTextLabelText( g_robberyNpcData[ clerkid ] [ E_LABEL ], COLOR_GOLD, sprintf( "%s\n"COL_WHITE"Aim To Start Robbery", g_robberyNpcData[ clerkid ] [ E_NPC_NAME ] ) );

		// Options
		if ( fullreplenish ) {
			g_robberyNpcData[ clerkid ] [ E_LOOT ] = g_robberyNpcData[ clerkid ] [ E_MAX_LOOT ];
		}
	}
}

stock GetRobberyNpcFromPlayer( playerid )
{
	foreach(new i : RobberyNpc)
		if ( g_robberyNpcData[ i ] [ E_NPC_ID ] == playerid )
			return i;

	return -1;
}

stock StopPlayerNpcRobbery( playerid, clerkid = -1, bool: cower = true )
{
	// Reset variables
	DeletePVar( playerid, sprintf( "robbedNpc_%d", clerkid ) );

	// Hide textdraws
	PlayerTextDrawHide( playerid, p_RobberyRiskTD[ playerid ] );
	PlayerTextDrawHide( playerid, p_RobberyAmountTD[ playerid ] );

	// Reset clerk variables
	if ( clerkid != -1 )
	{
		new
			npcid = g_robberyNpcData[ clerkid ] [ E_NPC_ID ];

		FCNPC_StopAim( npcid );
		FCNPC_SetWeapon( npcid, 0 );
		FCNPC_SetInvulnerable( npcid, true );

		if ( cower ) {
			FCNPC_ApplyAnimation( npcid, "PED", "cower", 3.0, 0, 1, 1, 1, 0 );
			FCNPC_SetAnimationByName( npcid, "PED:cower", 3.0, 0, 1, 1, 1, 0 );
		}

		// Reset loot
		g_robberyNpcData[ clerkid ] [ E_LOOT ] = 0;
		g_robberyNpcData[ clerkid ] [ E_PROVOKED ] = false;
		g_robberyNpcData[ clerkid ] [ E_TIMEOUT ] = g_iTime + 180;
		g_robberyNpcData[ clerkid ] [ E_SHOOTING_TIMER ] = -1;

		// Reset timer
		KillTimer( g_robberyNpcData[ clerkid ] [ E_HOLDUP_TIMER ] ), g_robberyNpcData[ clerkid ] [ E_HOLDUP_TIMER ] = -1;
		UpdateDynamic3DTextLabelText( g_robberyNpcData[ clerkid ] [ E_LABEL ], COLOR_GOLD, sprintf( "%s\n"COL_RED"Unavailable For Robbery", g_robberyNpcData[ clerkid ] [ E_NPC_NAME ] ) );
	}
	return 1;
}

stock FCNPC_ShootAtPlayer( playerid, npcid, weaponid = 25, clerkid = -1, bool: weapon_accurate = false )
{
	// Auto aim on crouch for store clerks
	if ( clerkid != -1 )
	{
		g_robberyNpcData[ clerkid ] [ E_SHOOTING_OFFSET ] = 0.6;
		KillTimer( g_robberyNpcData[ clerkid ] [ E_SHOOTING_TIMER ] );
		g_robberyNpcData[ clerkid ] [ E_SHOOTING_TIMER ] = SetTimerEx( "RobberyNpcShootCheck", 1500, false, "dd", clerkid, playerid );
	}
	else if ( ! weapon_accurate ) // Civilians should have inaccuracy
	{
		FCNPC_SetWeaponAccuracy( npcid, weaponid, 0.5 );
		FCNPC_SetWeaponSkillLevel( npcid, WEAPONSKILL_AK47, 8 );
	}
	FCNPC_ResetAnimation( npcid );
	FCNPC_ClearAnimations( npcid );
	FCNPC_SetWeapon( npcid, weaponid );
	FCNPC_ToggleInfiniteAmmo( npcid, true );
	FCNPC_AimAtPlayer( npcid, playerid, .shoot = true, .shoot_delay = -1, .setangle = true, .offset_x = 0.0, .offset_y = 0.0, .offset_z = 0.6 );
	return 1;
}

stock GetClosestRobberyNPC( robberyid, &Float: distance = FLOAT_INFINITY ) {
    new
    	iCurrent = -1, Float: fTmp;

    if ( 0 <= robberyid < MAX_ROBBERIES )
    {
		foreach(new clerkid : RobberyNpc)
		{
	        if ( g_robberyData[ robberyid ] [ E_WORLD ] && g_robberyNpcData[ clerkid ] [ E_WORLD ] && g_robberyNpcData[ clerkid ] [ E_WORLD ] != g_robberyData[ robberyid ] [ E_WORLD ] )
	        	continue;

            if ( 0.0 < ( fTmp = GetPlayerDistanceFromPoint( g_robberyNpcData[ clerkid ] [ E_NPC_ID ], g_robberyData[ robberyid ] [ E_DOOR_X ], g_robberyData[ robberyid ] [ E_DOOR_Y ], g_robberyData[ robberyid ] [ E_DOOR_Z ] ) ) < distance )
            {
                distance = fTmp;
                iCurrent = clerkid;
            }
	    }
    }
    return iCurrent;
}

stock TriggerRobberyForClerks( playerid, robberyid )
{
	new Float: distance = FLOAT_INFINITY;
	new	clerkid = GetClosestRobberyNPC( robberyid, distance );

	if ( clerkid != -1 && distance < 50.0 )
	{
		new
			npcid = g_robberyNpcData[ clerkid ] [ E_NPC_ID ];

		if ( FCNPC_IsDead( npcid ) || g_robberyNpcData[ clerkid ] [ E_PROVOKED ] || ! g_robberyNpcData[ clerkid ] [ E_LOOT ] )
			return;

		StopPlayerNpcRobbery( playerid );
		FCNPC_ShootAtPlayer( playerid, npcid, .weaponid = 25, .clerkid = clerkid );
		g_robberyNpcData[ clerkid ] [ E_PROVOKED ] = true;
		KillTimer( g_robberyNpcData[ clerkid ] [ E_HOLDUP_TIMER ] ), g_robberyNpcData[ clerkid ] [ E_HOLDUP_TIMER ] = -1;
		TriggerClosestCivilians( playerid, clerkid );
		SendServerMessage( playerid, "You have committed a robbery while the clerk is concious! "COL_ORANGE"The police have been informed." );
	}
}

function OnPlayerHoldupStore( playerid, clerkid, step )
{
	if ( !( 0 <= clerkid < MAX_ROBBERY_NPCS )  )
		return 1;

	new npcid = g_robberyNpcData[ clerkid ] [ E_NPC_ID ];
	new Float: fX, Float: fY, Float: fZ, Float: distance;
	new szLocation[ MAX_ZONE_NAME ], szCity[ MAX_ZONE_NAME ];

	GetPlayerPos( npcid, fX, fY, fZ );
	distance = GetDistanceFromPlayerSquared( playerid, fX, fY, fZ );

	if ( ! g_robberyNpcData[ clerkid ] [ E_LOOT ] || !( 0.0 < distance < 625.0 ) || !IsPlayerConnected( playerid ) || ! IsPlayerSpawned( playerid ) || IsPlayerTied( playerid ) || IsPlayerInAnyVehicle( playerid ) || GetPlayerState( playerid ) == PLAYER_STATE_WASTED || IsPlayerAFK( playerid ) || p_Class[ playerid ] == CLASS_POLICE )
		return StopPlayerNpcRobbery( playerid, clerkid );

	// Enough loot? Else finish.
	if ( g_robberyNpcData[ clerkid ] [ E_LOOT ] <= 0 )
		return StopPlayerNpcRobbery( playerid, clerkid );

	if ( step == 0 )
	{
		if ( GetPlayerLocation( playerid, szCity, szLocation ) ) {
			SendClientMessageToCops( -1, ""COL_BLUE"[POLICE RADIO]"COL_WHITE" %s began robbing "COL_GREY"%s"COL_WHITE" near %s in %s.", ReturnPlayerName( playerid ), g_robberyNpcData[ clerkid ] [ E_NPC_NAME ], szLocation, szCity );
		} else {
			SendClientMessageToCops( -1, ""COL_BLUE"[POLICE RADIO]"COL_WHITE" %s began robbing "COL_GREY"%s"COL_WHITE".", ReturnPlayerName( playerid ), g_robberyNpcData[ clerkid ] [ E_NPC_NAME ] );
		}

		CreateCrimeReport( playerid );
		DeletePVar( playerid, sprintf( "robbedNpc_%d", clerkid ) );
		PlayerTextDrawSetString( playerid, p_RobberyRiskTD[ playerid ], "~g~~h~Clerk is scared" );
		UpdateDynamic3DTextLabelText( g_robberyNpcData[ clerkid ] [ E_LABEL ], COLOR_GOLD, sprintf( "%s\n"COL_GREY"Currently Being Robbed", g_robberyNpcData[ clerkid ] [ E_NPC_NAME ] ) );
	}
	else
	{
		/*new
			targetplayerid = GetPlayerTargetPlayer( playerid );

		// If the player aint aiming at the assistant, whip out a gun
		if ( targetplayerid != npcid || 0 < GetPlayerWeapon( playerid ) < 1 || !( 0.0 < distance < 25.0 ) ) {
			PlayerTextDrawSetString( playerid, p_RobberyRiskTD[ playerid ], "~r~~h~~h~Clerk might draw out gun" );

			// Shoot player
			if ( random( 101 ) < 20 && p_Robberies[ playerid ] > 10 ) {
				g_robberyNpcData[ clerkid ] [ E_PROVOKED ] = true;
				return StopPlayerNpcRobbery( playerid ), FCNPC_ShootAtPlayer( playerid, npcid, .weaponid = 25, .clerkid = clerkid );
			}
		}
		else
		{
			PlayerTextDrawSetString( playerid, p_RobberyRiskTD[ playerid ], "~g~~h~Clerk is scared" );
		}*/

		new
			amount = RandomEx( 250, 500 ),
			robbedNpc = GetPVarInt( playerid, sprintf( "robbedNpc_%d", clerkid ) ) + amount
		;

		g_robberyNpcData[ clerkid ] [ E_LOOT ] -= amount;

		if ( g_robberyNpcData[ clerkid ] [ E_LOOT ] < 0 )
		{
			amount += g_robberyNpcData[ clerkid ] [ E_LOOT ];
			robbedNpc = g_robberyNpcData[ clerkid ] [ E_MAX_LOOT ];

			if ( GetPlayerLocation( playerid, szCity, szLocation ) ) {
				SendGlobalMessage( -1, ""COL_GOLD"[ROBBERY]"COL_WHITE" %s(%d) has robbed "COL_GOLD"%s"COL_WHITE" from a %s near %s in %s!", ReturnPlayerName( playerid ), playerid, cash_format( robbedNpc ), g_robberyNpcData[ clerkid ] [ E_NPC_NAME ], szLocation, szCity );
			} else {
				SendGlobalMessage( -1, ""COL_GOLD"[ROBBERY]"COL_WHITE" %s(%d) has robbed "COL_GOLD"%s"COL_WHITE" from a %s!", ReturnPlayerName( playerid ), playerid, cash_format( robbedNpc ), g_robberyNpcData[ clerkid ] [ E_NPC_NAME ] );
			}

			/*new Float: safeDistance = 99999.99;
			new robberyid = getClosestRobberySafe( playerid, safeDistance );
			if ( robberyid != INVALID_OBJECT_ID && safeDistance < 100.0 && !g_robberyData[ robberyid ] [ E_STATE ] ) {
				//g_robberyData[ robberyid ] [ E_MULTIPLIER ] = 1.1;
				SendServerMessage( playerid, "You have successfully robbed "COL_GOLD"%s"COL_WHITE" from "COL_GREY"%s"COL_WHITE".", cash_format( robbedNpc ), g_robberyNpcData[ clerkid ] [ E_NPC_NAME ], "%%" );
			} else {
				SendServerMessage( playerid, "You have successfully robbed "COL_GOLD"%s"COL_WHITE" from "COL_GREY"%s"COL_WHITE".", cash_format( robbedNpc ), g_robberyNpcData[ clerkid ] [ E_NPC_NAME ] );
			}*/

			GivePlayerExperience( playerid, E_ROBBERY, 0.8 );
			PlayerPlaySound( playerid, 5201, 0.0, 0.0, 0.0 );
		} else {
			PlayerPlaySound( playerid, 5205, 0.0, 0.0, 0.0 );
		}

		if ( !( 0 <= amount < 10000 ) )
			return SendError( playerid, "A money exploit occurred. Contact Lorenc ASAP." );

		GivePlayerCash( playerid, amount );
		SetPVarInt( playerid, sprintf( "robbedNpc_%d", clerkid ), robbedNpc );
		PlayerTextDrawSetString( playerid, p_RobberyAmountTD[ playerid ], sprintf( "Robbed ~g~~h~%s", cash_format( robbedNpc ) ) );
	}

	FCNPC_ApplyAnimation( npcid, "SHOP", "SHP_Rob_GiveCash", 4.1, 0, 1, 1, 1, 0 );
	FCNPC_SetAnimationByName( npcid, "SHOP:SHP_Rob_GiveCash", 4.1, 0, 1, 1, 1, 0 );
	return ( g_robberyNpcData[ clerkid ] [ E_HOLDUP_TIMER ] = SetTimerEx( "OnPlayerHoldupStore", 800, false, "ddd", playerid, clerkid, step + 1 ) ), 1;
}

function RobberyNpcShootCheck( clerkid, playerid )
{
	new
		npcid = g_robberyNpcData[ clerkid ] [ E_NPC_ID ];

	if ( ! IsPlayerConnected( playerid ) || ! IsPlayerSpawned( playerid ) || FCNPC_IsDead( npcid ) ) {
		return StopPlayerNpcRobbery( playerid, clerkid, .cower = true );
	}

	new
		specialAnimation = GetPlayerSpecialAction( playerid );

	if ( specialAnimation == SPECIAL_ACTION_DUCK && g_robberyNpcData[ clerkid ] [ E_SHOOTING_OFFSET ] != 0.1 ) {
		g_robberyNpcData[ clerkid ] [ E_SHOOTING_OFFSET ] = 0.1;
		FCNPC_AimAtPlayer( npcid, playerid, .shoot = true, .shoot_delay = -1, .setangle = true, .offset_x = 0.0, .offset_y = 0.0, .offset_z = 0.1 );
	} else if ( specialAnimation != SPECIAL_ACTION_DUCK && g_robberyNpcData[ clerkid ] [ E_SHOOTING_OFFSET ] != 0.6 ) {
		g_robberyNpcData[ clerkid ] [ E_SHOOTING_OFFSET ] = 0.6;
		FCNPC_AimAtPlayer( npcid, playerid, .shoot = true, .shoot_delay = -1, .setangle = true, .offset_x = 0.0, .offset_y = 0.0, .offset_z = 0.6 );
	}

	return ( g_robberyNpcData[ clerkid ] [ E_SHOOTING_TIMER ] = SetTimerEx( "RobberyNpcShootCheck", 1500, false, "dd", clerkid, playerid ) ), 1;
}

stock CreateCivilianNpc( name[ ], skinId[ ], clerkId, animlib[ 16 ], animname[ 16 ], const Float: position[ 4 ], worldid, interior, bool: hostile = true, numSkins = sizeof( skinId ) )
{
	new
		szBotName[ MAX_PLAYER_NAME ];

	format( szBotName, sizeof( szBotName ), "%s", name );
	strreplacechar( szBotName, ' ', '\0' );
	strreplacechar( szBotName, '/', '\0' );

	new
		civilianid = Iter_Free(CivilianNpc);

	if ( civilianid != ITER_NONE )
	{
		new
			randomSkin = random( numSkins );

		Iter_Add(CivilianNpc, civilianid);

		format( g_civilianNpcData[ civilianid ] [ E_ANIM_LIB ], 16, "%s", animlib );
		format( g_civilianNpcData[ civilianid ] [ E_ANIM_NAME ], 16, "%s", animname );
		format( g_civilianNpcData[ civilianid ] [ E_NPC_NAME ], MAX_PLAYER_NAME, "%s", name );
		CreateDynamic3DTextLabel( sprintf( "%s", name ), 0xFFFFFF25, position[ 0 ], position[ 1 ], position[ 2 ], 25.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, .testlos = 0, .worldid = worldid );
		g_civilianNpcData[ civilianid ] [ E_NPC_ID ] = FCNPC_Create( worldid != -1 ? sprintf( "[BOT]%s%d", szBotName, civilianid ) : sprintf( "[BOT]%s", szBotName ) );
		g_civilianNpcData[ civilianid ] [ E_WORLD ] = worldid == -1 ? 0 : worldid;
		g_civilianNpcData[ civilianid ] [ E_INTERIOR ] = interior == -1 ? 0 : interior;
		g_civilianNpcData[ civilianid ] [ E_CLERK_ID ] = clerkId;
		g_civilianNpcData[ civilianid ] [ E_HOSTILE ] = hostile;
		FCNPC_Spawn( g_civilianNpcData[ civilianid ] [ E_NPC_ID ], skinId[ randomSkin ], position[ 0 ], position[ 1 ], position[ 2 ] );
		FCNPC_SetAngle( g_civilianNpcData[ civilianid ] [ E_NPC_ID ], ( g_civilianNpcData[ civilianid ] [ E_RZ ] = position[ 3 ] ) );
	}
	else print( "[ERROR] Civilian cannot be added due to small limit, please raise." );
}

stock GetCivilianNpcFromPlayer( playerid )
{
	foreach(new i : CivilianNpc)
		if ( g_civilianNpcData[ i ] [ E_NPC_ID ] == playerid )
			return i;

	return -1;
}

stock TriggerClosestCivilians( playerid, clerkid = -1, Float: radius = 50.0, &Float: distance = FLOAT_INFINITY )
{
    if ( ! IsPlayerConnected( playerid ) )
    	return;

    new
    	Float: X, Float: Y, Float: Z,
    	worldid = GetPlayerVirtualWorld( playerid )
    ;

    GetPlayerPos( playerid, X, Y, Z );

	foreach (new civilianid : CivilianNpc) if ( ! g_civilianNpcData[ civilianid ] [ E_PROVOKED ] && g_civilianNpcData[ civilianid ] [ E_WORLD ] == worldid )
	{
		if ( ( clerkid != -1 && g_civilianNpcData[ civilianid ] [ E_CLERK_ID ] == clerkid ) || GetPlayerDistanceFromPoint( g_civilianNpcData[ civilianid ] [ E_NPC_ID ], X, Y, Z ) < radius )
		{
			if ( g_civilianNpcData[ civilianid ] [ E_HOSTILE ] )
			{
				new
					closestid = GetClosestPlayer( g_civilianNpcData[ civilianid ] [ E_NPC_ID ] );

				g_civilianNpcData[ civilianid ] [ E_PROVOKED ] = true;
				FCNPC_ShootAtPlayer( closestid, g_civilianNpcData[ civilianid ] [ E_NPC_ID ], 30, .weapon_accurate = strmatch( g_civilianNpcData[ civilianid ] [ E_NPC_NAME ], "Militia" ) );
			}
		}
    }

    // Trigger the robbery NPC TOO!
	if ( clerkid != -1 && g_robberyNpcData[ clerkid ] [ E_HOLDUP_TIMER ] == -1 && g_iTime > g_robberyNpcData[ clerkid ] [ E_TIMEOUT ] && ! g_robberyNpcData[ clerkid ] [ E_PROVOKED ] )
	{
		g_robberyNpcData[ clerkid ] [ E_PROVOKED ] = true;
		FCNPC_ShootAtPlayer( playerid, g_robberyNpcData[ clerkid ] [ E_NPC_ID ], 24, clerkid );
		StopPlayerNpcRobbery( playerid );
	}
}

stock FCNPC_NeutralState( npcid )
{
	FCNPC_StopAim( npcid );
	FCNPC_ResetAnimation( npcid );
	FCNPC_ClearAnimations( npcid );
	FCNPC_SetWeapon( npcid, 0 );
}
