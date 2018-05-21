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
	#define AC_INCLUDED
#else
	#endinput
#endif

/* ** Includes ** */
#include 							< YSI\y_hooks >

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

hook OnPlayerConnect( playerid )
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
		p_acSpawned 			{ playerid } = false;
		//p_SpectatePermission 	{ playerid } = false;
	    p_abDetected 			{ playerid } = 0;
	    p_abResetTimer 			[ playerid ] = -1;
		p_abLastTick 			[ playerid ] = GetTickCount( ) + 3000;
		p_FlyHacksWarns 		{ playerid } = 3;
		p_cbugWarns 			{ playerid } = 0;

		for ( new i = 0; i < AC_MAX_WEAPONS; i++ )
			p_PlayerHasWeapon 	[ playerid ] { i } = false;
	}
	return 1;
}

// Callback Hook (OnPlayerSpawn)

hook OnPlayerSpawn( playerid )
{
	// General
	p_acSpawned{ playerid } = true;

	// Weapon Hack
	for ( new i = 0; i < 3; i++ )
	{
		new
			weaponid = mAvailableSpawns[ p_SelectedClassID[ playerid ] ] [ E_WEAPONS ] [ i ];

		if( weaponid != -1 && weaponid < AC_MAX_WEAPONS )
			p_PlayerHasWeapon[ playerid ] { weaponid } = true;
	}

	// Airbrake
    p_abDetected{ playerid } = 0;
    p_abLastTick[ playerid ] = GetTickCount( ) + 3000;
	return 1;
}

// Hook (OnPlayerStateChange)

hook OnPlayerStateChange( playerid, newstate, oldstate )
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
	return 1;
}

// Hook (OnPlayerUpdate)

hook OnPlayerUpdate( playerid )
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
	return 1;
}

// Hook (OnPlayerRequestClass)

hook OnPlayerRequestClass( playerid, classid )
{
	// General
	p_acSpawned{ playerid } = false;
	p_SelectedClassID[ playerid ] = classid;
	return 1;
}

// Callback Hook (OnPlayerKeyStateChange)

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if( !IsPlayerNPC( playerid ) )
	{
		vWeaponHackCheck 	( playerid, newkeys );
		vAutoCbugKeyState 	( playerid, newkeys, oldkeys );
	}
	return 1;
}

// Callback Hook (OnPlayerWeaponShot)

hook OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	//printf("OnPlayerWeaponShot(%d, %d, %d, %d, %f, %f, %f)",playerid, weaponid, hittype, hitid, fX, fY, fZ);

	new
		iState = GetPlayerState( playerid );

	if( iState == PLAYER_STATE_WASTED || !ac_IsPlayerSpawned( playerid ) )
		return 0; // Why bother, he's dead!

	vCheckForAutoCbug( playerid, weaponid );
	vCheckForSilentAimbot( playerid, hittype, hitid );
	return 1;
}

// Callback Hook (OnPlayerPickupDynamicPickup)

hook OnPlayerPickUpDynPickup( playerid, pickupid )
{
	if ( GetGVarType( "ac_WeaponPickup", pickupid ) != GLOBAL_VARTYPE_NONE ) {
		p_PlayerHasWeapon[ playerid ] { GetGVarInt( "ac_WeaponPickup", pickupid ) } = true;
	}
}
