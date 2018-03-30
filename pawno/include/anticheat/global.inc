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

// Definitions (Global)

#define AC_MAX_DETECTIONS 			( 13 )
#define AC_DEFAULT_TEAM				( 1337 )
#define AC_DEBUG					( true )


#if !defined MAX_CLASSES
	#define MAX_CLASSES 			( 300 )
#endif

#if !defined AC_MAX_WEAPONS
	#define AC_MAX_WEAPONS 			( 55 )
#endif

// Variables (Global)

enum
{
	CHEAT_TYPE_WEAPON,
	//CHEAT_TYPE_CARWARP,
	//CHEAT_TYPE_MONEY,
	//CHEAT_TYPE_PLAYERBUGGER,
	//CHEAT_TYPE_PICKUP_SPAM,
	CHEAT_TYPE_SPECTATE,
	//CHEAT_TYPE_FAKEKILL,
	CHEAT_TYPE_REMOTE_JACK,
	//CHEAT_TYPE_PING_LIMIT,
	CHEAT_TYPE_SPEED_HACK,
	//CHEAT_TYPE_JETPACK,
	CHEAT_TYPE_HEALTH,
	CHEAT_TYPE_ARMOUR,
	CHEAT_TYPE_AIRBRAKE,
	CHEAT_TYPE_PROAIM,
	CHEAT_TYPE_AUTOCBUG,
	CHEAT_TYPE_FLYHACKS
};

enum E_CLASS_DATA
{
	E_WEAPONS[ 3 ]
};

stock
	bool: bIsDetectionEnabled		[ AC_MAX_DETECTIONS ] = { true, ... },

	mAvailableSpawns 				[ MAX_CLASSES ] [ E_CLASS_DATA ],
	//g_iWeaponPickup 				[ MAX_PICKUPS ],


	s_ValidDamageGiven[] = {
		1, // 0 - Fist
		1, // 1 - Brass knuckles
		1, // 2 - Golf club
		1, // 3 - Nitestick
		0, // 4 - Knife
		1, // 5 - Bat
		1, // 6 - Shovel
		1, // 7 - Pool cue
		1, // 8 - Katana
		1, // 9 - Chainsaw
		1, // 10 - Dildo
		1, // 11 - Dildo 2
		1, // 12 - Vibrator
		1, // 13 - Vibrator 2
		1, // 14 - Flowers
		1, // 15 - Cane
		0, // 16 - Grenade
		0, // 17 - Teargas
		0, // 18 - Molotov
		0, // 19 - Vehicle M4 (custom)
		0, // 20 - Vehicle minigun
		0, // 21
		1, // 22 - Colt 45
		1, // 23 - Silenced
		1, // 24 - Deagle
		1, // 25 - Shotgun
		1, // 26 - Sawed-off
		1, // 27 - Spas
		1, // 28 - UZI
		1, // 29 - MP5
		1, // 30 - AK47
		1, // 31 - M4
		1, // 32 - Tec9
		1, // 33 - Cuntgun
		1, // 34 - Sniper
		0, // 35 - Rocket launcher
		0, // 36 - Heatseeker
		0, // 37 - Flamethrower
		1, // 38 - Minigun
		0, // 39 - Satchel
		0, // 40 - Detonator
		1, // 41 - Spraycan
		1, // 42 - Fire extinguisher
		0, // 43 - Camera
		0, // 44 - Night vision
		0, // 45 - Infrared
		1, // 46 - Parachute
		0, // 47 - Fake pistol
		0, // 48 - Pistol whip (custom)
		0, // 49 - Vehicle
		0, // 50 - Helicopter blades
		0, // 51 - Explosion
		0, // 52 - Car park (custom)
		0, // 53 - Drowning
		0  // 54 - Splat
	},

	Float: s_ValidMaxDamage[] = {
		6.6, // 0 - Fist
		6.6, // 1 - Brass knuckles
		6.6, // 2 - Golf club
		6.6, // 3 - Nitestick
		6.7, // 4 - Knife (varies with back stab)
		6.6, // 5 - Bat
		6.6, // 6 - Shovel
		6.6, // 7 - Pool cue
		6.6, // 8 - Katana
		27.1, // 9 - Chainsaw
		6.6, // 10 - Dildo
		6.6, // 11 - Dildo 2
		6.6, // 12 - Vibrator
		6.6, // 13 - Vibrator 2
		6.6, // 14 - Flowers
		6.6, // 15 - Cane
		82.5, // 16 - Grenade
		0.0, // 17 - Teargas
		0.1, // 18 - Molotov
		0.0, // 19 - Vehicle M4 (custom)
		0.0, // 20 - Vehicle minigun
		0.0, // 21
		8.25, // 22 - Colt 45
		13.2, // 23 - Silenced
		46.2, // 24 - Deagle
		49.5, // 25 - Shotgun
		49.5, // 26 - Sawed-off
		39.6, // 27 - Spas
		6.6, // 28 - UZI
		8.3, // 29 - MP5
		9.9, // 30 - AK47
		9.9, // 31 - M4
		6.6, // 32 - Tec9
		24.8, // 33 - Cuntgun
		61.9, // 34 - Sniper
		82.5, // 35 - Rocket launcher
		82.5, // 36 - Heatseeker
		0.1, // 37 - Flamethrower
		46.2, // 38 - Minigun
		0.0, // 39 - Satchel (apparently 20, not synced anyway)
		0.0, // 40 - Detonator
		0.4, // 41 - Spraycan
		0.4, // 42 - Fire extinguisher
		0.0, // 43 - Camera
		0.0, // 44 - Night vision
		0.0, // 45 - Infrared
		6.6  // 46 - Parachute
	},

	Float: s_WeaponRange[] = {
		0.0, // 0 - Fist
		0.0, // 1 - Brass knuckles
		0.0, // 2 - Golf club
		0.0, // 3 - Nitestick
		0.0, // 4 - Knife
		0.0, // 5 - Bat
		0.0, // 6 - Shovel
		0.0, // 7 - Pool cue
		0.0, // 8 - Katana
		0.0, // 9 - Chainsaw
		0.0, // 10 - Dildo
		0.0, // 11 - Dildo 2
		0.0, // 12 - Vibrator
		0.0, // 13 - Vibrator 2
		0.0, // 14 - Flowers
		0.0, // 15 - Cane
		0.0, // 16 - Grenade
		0.0, // 17 - Teargas
		0.0, // 18 - Molotov
		90.0, // 19 - Vehicle M4 (custom)
		75.0, // 20 - Vehicle minigun (custom)
		0.0, // 21
		35.0, // 22 - Colt 45
		35.0, // 23 - Silenced
		35.0, // 24 - Deagle
		40.0, // 25 - Shotgun
		35.0, // 26 - Sawed-off
		40.0, // 27 - Spas
		35.0, // 28 - UZI
		45.0, // 29 - MP5
		70.0, // 30 - AK47
		90.0, // 31 - M4
		35.0, // 32 - Tec9
		100.0, // 33 - Cuntgun
		320.0, // 34 - Sniper
		0.0, // 35 - Rocket launcher
		0.0, // 36 - Heatseeker
		0.0, // 37 - Flamethrower
		75.0,  // 38 - Minigun
		0.0, // 39 - Satchel (apparently 20, not synced anyway)
		0.0, // 40 - Detonator
		0.0, // 41 - Spraycan
		0.0, // 42 - Fire extinguisher
		0.0, // 43 - Camera
		0.0, // 44 - Night vision
		0.0, // 45 - Infrared
		0.0  // 46 - Parachute
	},

	Iterator:classes<MAX_CLASSES>
;

// Forwards (Global)

public OnPlayerCheatDetected( playerid, detection );
public OnPlayerDamagePlayer( playerid, damagedid, Float: amount, weaponid, bodypart );

// Functions (Global)

stock detectionToString( iDetection ) {
	new
		szString[ 16 ] = "unknown";

	switch( iDetection ) {
		case CHEAT_TYPE_ARMOUR: 		szString = "Armour Hacks";
		case CHEAT_TYPE_HEALTH:			szString = "Health Hacks";
		case CHEAT_TYPE_WEAPON: 		szString = "Weapon Hacks";
		case CHEAT_TYPE_SPECTATE:		szString = "Spectate Hacks";
		case CHEAT_TYPE_AIRBRAKE: 		szString = "Airbrake";
		case CHEAT_TYPE_PROAIM: 		szString = "Silent Aimbot";
		case CHEAT_TYPE_AUTOCBUG: 		szString = "Auto CBUG";
		case CHEAT_TYPE_FLYHACKS: 		szString = "Fly Hacks";
		case CHEAT_TYPE_REMOTE_JACK:	szString = "Remote Jacking";
	}

	return szString;
}

stock ac_IsPointInArea( Float: X, Float: Y, Float: minx, Float: maxx, Float: miny, Float: maxy )
 	return ( X > minx && X < maxx && Y > miny && Y < maxy );

stock Float: ac_PointDistance( Float: X, Float: Y, Float: dstX, Float: dstY )
	return ( ( X - dstX ) * ( X - dstX ) ) + ( ( Y - dstY ) * ( Y - dstY ) );

stock Float: ac_GetDistanceBetweenPlayers( iPlayer1, iPlayer2, &Float: fDistance = Float: 0x7F800000 )
{
    static
    	Float: fX, Float: fY, Float: fZ;

    if( GetPlayerVirtualWorld( iPlayer1 ) == GetPlayerVirtualWorld( iPlayer2 ) && GetPlayerPos( iPlayer2, fX, fY, fZ ) )
		fDistance = GetPlayerDistanceFromPoint( iPlayer1, fX, fY, fZ );

    return fDistance;
}
