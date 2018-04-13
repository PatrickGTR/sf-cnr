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

#include 							< a_samp >

#include 							< anticheat\global >
#include 							< anticheat\player >

// Function Hook (GivePlayerWeapon)

stock AC_GivePlayerWeapon( playerid, weaponid, ammo )
{
	//p_PlayerWeaponUpdateTime[ playerid ] = GetTickCount( ) + 2000;

	if( weaponid < AC_MAX_WEAPONS )
		p_PlayerHasWeapon[ playerid ] { weaponid } = true;

    return GivePlayerWeapon( playerid, weaponid, ammo );
}

#if defined _ALS_GivePlayerWeapon
    #undef GivePlayerWeapon
#else
    #define _ALS_GivePlayerWeapon
#endif
#define GivePlayerWeapon AC_GivePlayerWeapon

// Function Hook (ResetPlayerWeapons)

stock AC_ResetPlayerWeapons( playerid )
{
	//p_PlayerWeaponUpdateTime[ playerid ] = GetTickCount( ) + 2000;

	for ( new i = 0; i < AC_MAX_WEAPONS; i++ )
		p_PlayerHasWeapon[ playerid ] { i } = false;

    return ResetPlayerWeapons( playerid );
}

#if defined _ALS_ResetPlayerWeapons
    #undef ResetPlayerWeapons
#else
    #define _ALS_ResetPlayerWeapons
#endif
#define ResetPlayerWeapons AC_ResetPlayerWeapons

// Function Hook (SetSpawnInfo)

stock AC_SetSpawnInfo( playerid, team, skin, Float: x, Float: y, Float: z, Float: Angle, weapon1, weapon1_ammo, weapon2, weapon2_ammo, weapon3, weapon3_ammo )
{
	if ( weapon1 != -1 && weapon1 < AC_MAX_WEAPONS ) p_PlayerHasWeapon[ playerid ] { weapon1 } = true;
	if ( weapon2 != -1 && weapon2 < AC_MAX_WEAPONS ) p_PlayerHasWeapon[ playerid ] { weapon2 } = true;
	if ( weapon3 != -1 && weapon3 < AC_MAX_WEAPONS ) p_PlayerHasWeapon[ playerid ] { weapon3 } = true;

    return SetSpawnInfo( playerid, team, skin, x, y, z, Angle, weapon1, weapon1_ammo, weapon2, weapon2_ammo, weapon3, weapon3_ammo );
}

#if defined _ALS_SetSpawnInfo
    #undef SetSpawnInfo
#else
    #define _ALS_SetSpawnInfo
#endif
#define SetSpawnInfo AC_SetSpawnInfo

// Function Hook (AddPlayerClass)

stock AC_AddPlayerClass( skin, Float: x, Float: y, Float: z, Float: Angle, weapon1, weapon1_ammo, weapon2, weapon2_ammo, weapon3, weapon3_ammo )
{
	new
		classid = Iter_Free(classes);

	if( classid != -1 )
	{
		mAvailableSpawns[ classid ] [ E_WEAPONS ] [ 0 ] = weapon1;
		//mAvailableSpawns[ classid ] [ E_WEAPONS_AMMO ] [ 0 ] = static_cast<int>(params[7]);

		mAvailableSpawns[ classid ] [ E_WEAPONS ] [ 1 ] = weapon2;
		//mAvailableSpawns[ classid ] [ E_WEAPONS_AMMO ] [ 1 ] = static_cast<int>(params[9]);

		mAvailableSpawns[ classid ] [ E_WEAPONS ] [ 2 ] = weapon3;
		//mAvailableSpawns[ classid ] [ E_WEAPONS_AMMO ] [ 2 ] = static_cast<int>(params[11]);

		Iter_Add(classes, classid);
	}
    return AddPlayerClass( skin, x, y, z, Angle, weapon1, weapon1_ammo, weapon2, weapon2_ammo, weapon3, weapon3_ammo );
}

#if defined _ALS_AddPlayerClass
    #undef AddPlayerClass
#else
    #define _ALS_AddPlayerClass
#endif
#define AddPlayerClass AC_AddPlayerClass

// Function Hook (AddPlayerClass)

stock AC_AddPlayerClassEx( teamid, skin, Float:x, Float:y, Float:z, Float:Angle, weapon1, weapon1_ammo, weapon2, weapon2_ammo, weapon3, weapon3_ammo )
{
	new
		classid = Iter_Free(classes);

	if( classid != -1 )
	{
		mAvailableSpawns[ classid ] [ E_WEAPONS ] [ 0 ] = weapon1;
		//mAvailableSpawns[ classid ] [ E_WEAPONS_AMMO ] [ 0 ] = static_cast<int>(params[7]);

		mAvailableSpawns[ classid ] [ E_WEAPONS ] [ 1 ] = weapon2;
		//mAvailableSpawns[ classid ] [ E_WEAPONS_AMMO ] [ 1 ] = static_cast<int>(params[9]);

		mAvailableSpawns[ classid ] [ E_WEAPONS ] [ 2 ] = weapon3;
		//mAvailableSpawns[ classid ] [ E_WEAPONS_AMMO ] [ 2 ] = static_cast<int>(params[11]);

		Iter_Add(classes, classid);
	}
    return AddPlayerClassEx( teamid, skin, x, y, z, Angle, weapon1, weapon1_ammo, weapon2, weapon2_ammo, weapon3, weapon3_ammo )
}

#if defined _ALS_AddPlayerClassEx
    #undef AddPlayerClassEx
#else
    #define _ALS_AddPlayerClassEx
#endif
#define AddPlayerClassEx AC_AddPlayerClassEx

// Function Hook (CreateDynamicPickup)

stock AC_CreateDynamicPickup( modelid, type, Float: x, Float: y, Float: z, worldid = -1, interiorid = -1, playerid = -1, Float: streamdistance = 100.0 )
{
	new
		id = CreateDynamicPickup( modelid, type, x, y, z, worldid, interiorid, playerid, streamdistance );

	if( type == 2 || type == 3 || type == 15 || type == 22 )
	{
        for( new i = 0; i < AC_MAX_WEAPONS; i ++ )
        	if( GetWeaponModel( i ) == modelid )
        		SetGVarInt( "ac_WeaponPickup", i, id );
	}
	return id;
}

#if defined _ALS_CreateDynamicPickup
    #undef CreateDynamicPickup
#else
    #define _ALS_CreateDynamicPickup
#endif
#define CreateDynamicPickup AC_CreateDynamicPickup

// Functions

stock vWeaponHackCheck( playerid, keys )
{
	if( ( keys & KEY_FIRE ) && ac_IsPlayerSpawned( playerid ) ) {
		new
			iWeapon = GetPlayerWeapon( playerid );

		if( iWeapon > -1 && iWeapon < AC_MAX_WEAPONS )
		{
			if( !p_PlayerHasWeapon[ playerid ] { iWeapon } && ( iWeapon != 0 && iWeapon != 40 ) ) {
				CallLocalFunction( "OnPlayerCheatDetected", "dd", playerid, CHEAT_TYPE_WEAPON );
				printf("[weapon] %d seems to weapon hack (weapon id %d).", playerid, iWeapon );
			}
		}
	}
}

/*stock vWeaponHackCheck( playerid, iTicks )
{
	if( iTicks > p_PlayerWeaponUpdateTime[ playerid ] )
	{
		new
			iWeapon, iAmmo;

		for( new iSlot = 0; iSlot != 13; iSlot++ )
		{
			GetPlayerWeaponData( playerid, iSlot, iWeapon, iAmmo );

			if( !p_PlayerHasWeapon[ playerid ] { iWeapon } && ( iAmmo > 0 && iWeapon != 0 && iWeapon != 40 ) ) {
				CallLocalFunction( "OnPlayerCheatDetected", "dd", playerid, CHEAT_TYPE_WEAPON );
				printf("[weapon] %d seems to weapon hack (weapon id %d).", playerid, iWeapon );
				break;
			}
		}
		p_PlayerWeaponUpdateTime[ playerid ] = iTicks + 750;
	}
}*/
