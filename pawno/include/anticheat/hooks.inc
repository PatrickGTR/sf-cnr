/*
	PROJECT		<>	SA:MP Anticheat Plug-in
	LICENSE		<>	See LICENSE in the top level directory.
	AUTHOR(S)	<>	Lorenc_ (zeelorenc@hotmail.com)
	PURPOSE		<>  Providing datastructures for the internal SA:MP Server.


	Copyright (C) 2014 SA:MP Anticheat Plug-in.

	The Project is available on https://github.com/myudev/SAMPAC

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program; if not, see <http://www.gnu.org/licenses/>.
*/

#if !defined AC_INCLUDED
	#include 							< a_samp >

	// Function Hook (PutPlayerInVehicle)

	stock AC_PutPlayerInVehicle(playerid, vehicleid, seatid)
	{
		// Remote Jacking
		p_remoteJackData[ playerid ] [ E_LAST_VEH ] = vehicleid;

		// Airbreak
	    p_abLastTick[ playerid ] = GetTickCount( ) + 3000;
		return PutPlayerInVehicle(playerid, vehicleid, seatid);
	}

	#if defined _ALS_PutPlayerInVehicle
	    #undef PutPlayerInVehicle
	#else
	    #define _ALS_PutPlayerInVehicle
	#endif
	#define PutPlayerInVehicle AC_PutPlayerInVehicle

	// Callback Hook (OnPlayerConnect)

	public OnPlayerConnect( playerid )
	{
		if ( !IsPlayerNPC( playerid ) )
		{
			// Remove Vending Machines
			RemoveBuildingForPlayer( playerid, 1302, 0.0, 0.0, 0.0, 6000.0 );
		    RemoveBuildingForPlayer( playerid, 1209, 0.0, 0.0, 0.0, 6000.0 );
		    RemoveBuildingForPlayer( playerid, 955, 0.0, 0.0, 0.0, 6000.00 );
		    RemoveBuildingForPlayer( playerid, 956, 0.0, 0.0, 0.0, 6000.00 );
		    RemoveBuildingForPlayer( playerid, 1775, 0.0, 0.0, 0.0, 6000.0 );
		    RemoveBuildingForPlayer( playerid, 1776, 0.0, 0.0, 0.0, 6000.0 );
		    RemoveBuildingForPlayer( playerid, 1977, 0.0, 0.0, 0.0, 6000.0 );

		    // Reset Variables
			p_PlayerHealth			[ playerid ] [ E_UPDATE_FAIL ] = 0;
			p_PlayerArmour			[ playerid ] [ E_UPDATE_FAIL ] = 0;
			p_acSpawned 			{ playerid } = false;
			//p_SpectatePermission 	{ playerid } = false;
		    p_abDetected 			{ playerid } = 0;
		    p_abResetTimer 			[ playerid ] = -1;
			p_abLastTick 			[ playerid ] = GetTickCount( ) + 3000;
			p_FlyHacksWarns 		{ playerid } = 3;
			p_cbugWarns 			{ playerid } = 0;

			for ( new i = 0; i < MAX_WEAPONS; i++ )
				p_PlayerHasWeapon 	[ playerid ] { i } = false;
		}

		#if defined SAMPAC_OnPlayerConnect
			return SAMPAC_OnPlayerConnect( playerid );
		#else
			return 1;
		#endif
	}

	#if defined SAMPAC_OnPlayerConnect
		forward SAMPAC_OnPlayerConnect( playerid );
	#endif
	#if defined _ALS_OnPlayerConnect
		#undef OnPlayerConnect
	#else
		#define _ALS_OnPlayerConnect
	#endif
	#define OnPlayerConnect SAMPAC_OnPlayerConnect

	// Callback Hook (OnPlayerSpawn)

	public OnPlayerSpawn( playerid )
	{
		// General
		p_acSpawned{ playerid } = true;

		// Health/Armour Hack
		p_PlayerHealth[ playerid ] [ E_UPDATE_FAIL ] = 0;
		p_PlayerHealth[ playerid ] [ E_POINTS ] = 100.0;

		p_PlayerArmour[ playerid ] [ E_UPDATE_FAIL ] = 0;
		p_PlayerArmour[ playerid ] [ E_POINTS ] = 0.0;

		SetPlayerTeam( playerid, AC_DEFAULT_TEAM ); // Set everyone the same team

		// Weapon Hack
		for ( new i = 0; i < 3; i++ )
		{
			new
				weaponid = mAvailableSpawns[ p_SelectedClassID[ playerid ] ] [ E_WEAPONS ] [ i ];

			if( weaponid != -1 && weaponid < MAX_WEAPONS )
				p_PlayerHasWeapon[ playerid ] { weaponid } = true;
		}

		// Airbrake
	    p_abDetected{ playerid } = 0;
	    p_abLastTick[ playerid ] = GetTickCount( ) + 3000;

		#if defined SAMPAC_OnPlayerSpawn
			return SAMPAC_OnPlayerSpawn( playerid );
		#else
			return 1;
		#endif
	}

	#if defined SAMPAC_OnPlayerSpawn
		forward SAMPAC_OnPlayerSpawn( playerid );
	#endif
	#if defined _ALS_OnPlayerSpawn
		#undef OnPlayerSpawn
	#else
		#define _ALS_OnPlayerSpawn
	#endif
	#define OnPlayerSpawn SAMPAC_OnPlayerSpawn

	// Callback Hook (OnPlayerDeath)

	public OnPlayerDeath(playerid, killerid, reason)
	{
		if ( !IsPlayerNPC( playerid ) )
		{
	    	// Health/Armour Hack
		    if( GetPVarInt( playerid, "CustomKill" ) )
		    {
				new
					customKiller = GetPVarInt( playerid, "KillerID" );

		  		OnPlayerDeathEx( playerid, customKiller != playerid ? customKiller : INVALID_PLAYER_ID, GetPVarInt( playerid, "WeaponID" ), 3.3, 3 );

			    DeletePVar( playerid, "KillerID" );
			    DeletePVar( playerid, "WeaponID" );
		    	DeletePVar( playerid, "CustomKill" );
		    }

		    else if( GetPlayerVehicleID( playerid ) && ac_IsPlayerSpawned( playerid ) )  // Died in Vehicle
		    {
				if( ( GetTickCount( ) - p_LastTookDamage[ playerid ] ) > 2500 )
					p_LastDamageIssuer[ playerid ] = INVALID_PLAYER_ID, p_LastWeaponIssuer[ playerid ] = 51;

				p_acSpawned{ playerid } = false; // They're dead!
				OnPlayerDeathEx( playerid, p_LastDamageIssuer[ playerid ], p_LastWeaponIssuer[ playerid ], 3.3, 3 );
		    }

			// General
	    	p_acSpawned{ playerid } = false;

			// Airbrake
	        p_abLastTick[ playerid ] = GetTickCount( ) + 3000;
	   	}

		#if defined SAMPAC_OnPlayerDeath
			return SAMPAC_OnPlayerDeath(playerid, killerid, reason);
		#else
			return 1;
		#endif
	}

	#if defined SAMPAC_OnPlayerDeath
		forward SAMPAC_OnPlayerDeath(playerid, killerid, reason);
	#endif
	#if defined _ALS_OnPlayerDeath
		#undef OnPlayerDeath
	#else
		#define _ALS_OnPlayerDeath
	#endif
	#define OnPlayerDeath SAMPAC_OnPlayerDeath

	// Callback Hook (OnPlayerTakeDamage)

	public OnPlayerTakeDamage( playerid, issuerid, Float: amount, weaponid, bodypart )
	{
		new
			is_npc = IsPlayerNPC( issuerid );

		p_LastTookDamage[ playerid ] = GetTickCount( );
		p_LastDamageIssuer[ playerid ] = issuerid;
		p_LastWeaponIssuer[ playerid ] = weaponid;
		p_LastDamageIssued[ playerid ] = amount;

		//if( !( issuerid != INVALID_PLAYER_ID && IsPlayerInAnyVehicle( issuerid ) && GetPlayerVehicleSeat( issuerid ) == 0 && ( weaponid == WEAPON_M4 || weaponid == WEAPON_MINIGUN ) ) )
		//	return 0;

		// Allow hunter damage/sparrow
		if( !( issuerid != INVALID_PLAYER_ID && IsPlayerInAnyVehicle( issuerid ) && GetPlayerVehicleSeat( issuerid ) == 0 && ( weaponid == WEAPON_M4 || weaponid == WEAPON_MINIGUN ) ) && !is_npc )
		{
			// Ignore unreliable and invalid damage
			if( weaponid < 0 || weaponid >= sizeof( s_ValidDamageGiven ) || s_ValidDamageGiven[ weaponid ] )
				return 0;
		}

		if( ac_IsPlayerSpawned( playerid ) )
		{
			if( issuerid != INVALID_PLAYER_ID && ! is_npc )
			{
				if( OnPlayerTakePlayerDamage( playerid, issuerid, amount, weaponid, bodypart ) )
				{
					new Float: tmp, Float: tmp_amount = amount;

					if( p_PlayerArmour[ playerid ] [ E_POINTS ] )
					{
						if( ( tmp = p_PlayerArmour[ playerid ] [ E_POINTS ] - tmp_amount ) < 0.0 )  {
							tmp_amount -= p_PlayerArmour[ playerid ] [ E_POINTS ];
							p_PlayerArmour[ playerid ] [ E_POINTS ] = 0.0;
						} else  {
							p_PlayerArmour[ playerid ] [ E_POINTS ] = tmp;
							tmp_amount = 0.0;
						}
					}

					if( ( p_PlayerHealth[ playerid ] [ E_POINTS ] -= tmp_amount ) < 0.0 ) {
						p_acSpawned{ playerid } = false; // They're dead!
						OnPlayerDeathEx( playerid, issuerid, weaponid, amount, bodypart );
					}

					SetPlayerArmour( playerid, p_PlayerArmour[ playerid ] [ E_POINTS ] );
					SetPlayerHealth( playerid, p_PlayerHealth[ playerid ] [ E_POINTS ] );
				}
			}
			else
			{
				new Float: tmp, Float: tmp_amount = amount;

				if( !( weaponid == 53 || weaponid == 54 || weaponid == 50 ) && p_PlayerArmour[ playerid ] [ E_POINTS ] )
				{
					if( ( tmp = p_PlayerArmour[ playerid ] [ E_POINTS ] - tmp_amount ) < 0.0 )  {
						tmp_amount -= p_PlayerArmour[ playerid ] [ E_POINTS ];
						p_PlayerArmour[ playerid ] [ E_POINTS ] = 0.0;
					} else  {
						p_PlayerArmour[ playerid ] [ E_POINTS ] = tmp;
						tmp_amount = 0.0;
					}
				}

				//printf("OnPlayerTakeDamage( %d, %d, %f, %d, %d ) %f", playerid, issuerid, amount, weaponid, bodypart, p_PlayerHealth[ playerid ] [ E_POINTS ] );
				if( ( p_PlayerHealth[ playerid ] [ E_POINTS ] -= tmp_amount ) <= ( weaponid == 37 ? 0.99999 : 0.0 ) ) {
					p_acSpawned{ playerid } = false; // They're dead!
					if ( weaponid == 37 ) SetPlayerHealth( playerid, -1 );
					OnPlayerDeathEx( playerid, issuerid, weaponid, amount, bodypart );
				}
			}
		}

		#if defined SAMPAC_OnPlayerTakeDamage
			return SAMPAC_OnPlayerTakeDamage(playerid, issuerid, amount, weaponid, bodypart);
		#else
			return 0;
		#endif
	}

	#if defined SAMPAC_OnPlayerTakeDamage
		forward SAMPAC_OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid, bodypart);
	#endif
	#if defined _ALS_OnPlayerTakeDamage
		#undef OnPlayerTakeDamage
	#else
		#define _ALS_OnPlayerTakeDamage
	#endif
	#define OnPlayerTakeDamage SAMPAC_OnPlayerTakeDamage


	// Callback Hook (OnPlayerGiveDamage)

	public OnPlayerGiveDamage( playerid, damagedid, Float: amount, weaponid, bodypart )
	{
		// Ignore unreliable and invalid damage
		if ( weaponid < 0 || weaponid >= sizeof( s_ValidDamageGiven ) || !s_ValidDamageGiven[ weaponid ] )
			return 0;

		if( weaponid < 0 || weaponid >= sizeof( s_ValidMaxDamage ) || amount > s_ValidMaxDamage[ weaponid ] + 2.0 ) // 2.0 safety margin
			return 0;

		if( damagedid == INVALID_PLAYER_ID )
			return 0;

		if( IsPlayerInAnyVehicle( playerid ) && GetPlayerVehicleSeat( playerid ) == 0 && ( weaponid == WEAPON_M4 || weaponid == WEAPON_MINIGUN ) )
			return 0;

		if ( !IsPlayerNPC( damagedid ) )
		{
			if( !ac_IsPlayerSpawned( damagedid ) )
				return 0;

			if( ( !IsPlayerStreamedIn( playerid, damagedid ) && !( GetTickCount( ) - p_acUpdateTime[ damagedid ] >= 2595 ) ) || !IsPlayerStreamedIn( damagedid, playerid ) )
				return 0;

			//printf("OnPlayerGiveDamage( %d, %d, %f, %d, %d )", playerid, damagedid, amount, weaponid, bodypart );
			//p_LastTookDamage[ damagedid ] = GetTickCount( );
			//p_LastDamageIssuer[ damagedid ] = playerid;
			//p_LastWeaponIssuer[ damagedid ] = weaponid;
			//p_LastDamageIssued[ damagedid ] = amount;

			if( OnPlayerTakePlayerDamage( damagedid, playerid, amount, weaponid, bodypart ) )
			{
				new
					Float: tmp,
					Float: distance = GetDistanceBetweenPlayers( playerid, damagedid ), // Calc distance between players
					Float: tmp_amount = amount // this amount is extremely unreliable
				;
				//printf("Proposed dmg %f kinda %f (min: %f, max: %f, rng: %f)", amount, tmp_amount, GetWeaponMinRange( weaponid ), GetWeaponMaxRange( weaponid ), distance );

				if( distance > s_WeaponRange[ weaponid ] + 2.0 )
					return 0; //printf(" INVALID RANGE %f (MAX %f)", distance, GetWeaponMaxRange( weaponid ) ), 0;

				if( p_PlayerArmour[ damagedid ] [ E_POINTS ] )
				{
					if( ( tmp = p_PlayerArmour[ damagedid ] [ E_POINTS ] - tmp_amount ) < 0.0 )  {
						tmp_amount -= p_PlayerArmour[ damagedid ] [ E_POINTS ];
						p_PlayerArmour[ damagedid ] [ E_POINTS ] = 0.0;
					} else  {
						p_PlayerArmour[ damagedid ] [ E_POINTS ] = tmp;
						tmp_amount = 0.0;
					}
				}

				if( ( p_PlayerHealth[ damagedid ] [ E_POINTS ] -= tmp_amount ) < 0.0 ) {
					p_acSpawned{ damagedid } = false; // They're dead!
					OnPlayerDeathEx( damagedid, playerid, weaponid, amount, bodypart );
				}

				SetPlayerArmour( damagedid, p_PlayerArmour[ damagedid ] [ E_POINTS ] );
				SetPlayerHealth( damagedid, p_PlayerHealth[ damagedid ] [ E_POINTS ] );
			}
		}

		#if defined SAMPAC_OnPlayerGiveDamage
			return SAMPAC_OnPlayerGiveDamage( playerid, damagedid, Float: amount, weaponid, bodypart );
		#else
			return 0;
		#endif
	}

	#if defined SAMPAC_OnPlayerGiveDamage
		forward SAMPAC_OnPlayerGiveDamage( playerid, damagedid, Float: amount, weaponid, bodypart );
	#endif
	#if defined _ALS_OnPlayerGiveDamage
		#undef OnPlayerGiveDamage
	#else
		#define _ALS_OnPlayerGiveDamage
	#endif
	#define OnPlayerGiveDamage SAMPAC_OnPlayerGiveDamage

	// Hook (OnPlayerStateChange)

	public OnPlayerStateChange( playerid, newstate, oldstate )
	{
		if ( !IsPlayerNPC( playerid ) )
		{
			// Spectate Hacks
			/*if( oldstate == PLAYER_STATE_SPECTATING && newstate != PLAYER_STATE_SPECTATING ) {
				p_PlayerSpectateUpdateTime[ playerid ] = GetTickCount( ) + 1250;
				p_SpectatePermission{ playerid } = false; // Bugs otherwise dunno why
			}*/

			// Weapon Hacks - credits to wups
			if( newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER )
			{
				switch ( GetVehicleModel( GetPlayerVehicleID( playerid ) ) )
				{
					case 457:
						p_PlayerHasWeapon[ playerid ] { 2 } = true;

					case 592, 577, 511, 512, 520, 593, 553, 476, 519, 460, 513, 548, 425, 417, 487, 488, 497, 563, 447, 469, 539:
						p_PlayerHasWeapon[ playerid ] { 46 } = true;

					case 596, 597, 598, 599:
						p_PlayerHasWeapon[ playerid ] { 25 } = true;
				}
			}

			// Airbrake
	        p_abLastTick[ playerid ] = GetTickCount( ) + 3000;
	   	}

		#if defined SAMPAC_OnPlayerStateChange
			return SAMPAC_OnPlayerStateChange( playerid, newstate, oldstate );
		#else
			return 1;
		#endif
	}

	#if defined SAMPAC_OnPlayerStateChange
		forward SAMPAC_OnPlayerStateChange( playerid, newstate, oldstate );
	#endif
	#if defined _ALS_OnPlayerStateChange
		#undef OnPlayerStateChange
	#else
		#define _ALS_OnPlayerStateChange
	#endif
	#define OnPlayerStateChange SAMPAC_OnPlayerStateChange

	// Hook (OnPlayerUpdate)

	public OnPlayerUpdate( playerid )
	{
		if( !ac_IsPlayerSpawned( playerid ) )
			return 0; // Not Spawned, No SYNC!

		if( !IsPlayerNPC( playerid ) )
		{
			new
				iState = GetPlayerState( playerid );

			p_acUpdateTime[ playerid ] = GetTickCount( );
			//bCheckForSpectatingHacks	( playerid, iState, iTicks );

			if( iState != PLAYER_STATE_SPECTATING )
			{
	        	bCheckForAirbrake			( playerid, p_acUpdateTime[ playerid ], iState );
				vCheckForHealthHacks		( playerid, p_acUpdateTime[ playerid ] );
	        	vCheckForFlyHacks			( playerid, p_acUpdateTime[ playerid ] );
				//vWeaponHackCheck			( playerid, p_acUpdateTime[ playerid ] );
	        	bCheckPlayerRemoteJacking 	( playerid );
			}
		}

		#if defined SAMPAC_OnPlayerUpdate
			return SAMPAC_OnPlayerUpdate( playerid );
		#else
			return 1;
		#endif
	}

	#if defined SAMPAC_OnPlayerUpdate
		forward SAMPAC_OnPlayerUpdate( playerid );
	#endif
	#if defined _ALS_OnPlayerUpdate
		#undef OnPlayerUpdate
	#else
		#define _ALS_OnPlayerUpdate
	#endif
	#define OnPlayerUpdate SAMPAC_OnPlayerUpdate

	// Hook (OnPlayerRequestClass)

	public OnPlayerRequestClass( playerid, classid )
	{
		// General
		p_acSpawned{ playerid } = false;
		p_SelectedClassID[ playerid ] = classid;

		#if defined SAMPAC_OnPlayerRequestClass
			return SAMPAC_OnPlayerRequestClass( playerid, classid );
		#else
			return 1;
		#endif
	}

	#if defined SAMPAC_OnPlayerRequestClass
		forward SAMPAC_OnPlayerRequestClass( playerid, classid );
	#endif
	#if defined _ALS_OnPlayerRequestClass
		#undef OnPlayerRequestClass
	#else
		#define _ALS_OnPlayerRequestClass
	#endif
	#define OnPlayerRequestClass SAMPAC_OnPlayerRequestClass

	// Callback Hook (OnPlayerKeyStateChange)

	public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
	{
		if( !IsPlayerNPC( playerid ) )
		{
			vWeaponHackCheck 	( playerid, newkeys );
			vAutoCbugKeyState 	( playerid, newkeys, oldkeys );
		}

		#if defined SAMPAC_OnPlayerKeyStateChange
			return SAMPAC_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
		#else
			return 1;
		#endif
	}

	#if defined SAMPAC_OnPlayerKeyStateChange
		forward SAMPAC_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
	#endif
	#if defined _ALS_OnPlayerKeyStateChange
		#undef OnPlayerKeyStateChange
	#else
		#define _ALS_OnPlayerKeyStateChange
	#endif
	#define OnPlayerKeyStateChange SAMPAC_OnPlayerKeyStateChange

	// Callback Hook (OnPlayerWeaponShot)

	public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
	{
		//printf("OnPlayerWeaponShot(%d, %d, %d, %d, %f, %f, %f)",playerid, weaponid, hittype, hitid, fX, fY, fZ);

		new
			iState = GetPlayerState( playerid );

		if( iState == PLAYER_STATE_WASTED || !ac_IsPlayerSpawned( playerid ) )
			return 0; // Why bother, he's dead!

		vCheckForAutoCbug( playerid, weaponid );
		vCheckForSilentAimbot( playerid, hittype, hitid );

		#if defined SAMPAC_OnPlayerWeaponShot
			return SAMPAC_OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, fX, fY, fZ);
		#else
			return 1;
		#endif
	}

	#if defined SAMPAC_OnPlayerWeaponShot
		forward SAMPAC_OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ);
	#endif
	#if defined _ALS_OnPlayerWeaponShot
		#undef OnPlayerWeaponShot
	#else
		#define _ALS_OnPlayerWeaponShot
	#endif
	#define OnPlayerWeaponShot SAMPAC_OnPlayerWeaponShot

	#define AC_INCLUDED
#endif
