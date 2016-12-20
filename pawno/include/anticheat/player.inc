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

// Macro Definitions (Global)

#define ac_IsPlayerSpawned(%0) 		(p_acSpawned{%0})

// Variables (Player)

enum E_PLAYER_HITPOINTS
{
	Float: E_POINTS, 		E_UPDATE_TIME, 				E_UPDATE_FAIL,
	bool: E_SYNCED
};

enum E_PLAYER_REMOTEJACK
{
    Float: E_LAST_X,        Float: E_LAST_Y,        Float: E_LAST_Z,
    E_LAST_VEH
};

new
	// General
    bool: p_acSpawned  				[ MAX_PLAYERS char ],
    p_acUpdateTime 					[ MAX_PLAYERS ],

	// Health/Armour
	Float: p_PlayerHealth 			[ MAX_PLAYERS ] [ E_PLAYER_HITPOINTS ],
	Float: p_PlayerArmour 			[ MAX_PLAYERS ] [ E_PLAYER_HITPOINTS ],
	Float: p_LastDamageIssued		[ MAX_PLAYERS ],
	p_LastTookDamage 				[ MAX_PLAYERS ],
	p_LastDamageIssuer 				[ MAX_PLAYERS ] = { INVALID_PLAYER_ID, ... },
	p_LastWeaponIssuer 				[ MAX_PLAYERS ],

	// Weapon Hacks
	bool: p_PlayerHasWeapon 		[ MAX_PLAYERS ] [ MAX_WEAPONS char ],
	//p_PlayerWeaponUpdateTime 		[ MAX_PLAYERS ],
	p_SelectedClassID 				[ MAX_PLAYERS ],

	// Spectating
	//bool: p_SpectatePermission 		[ MAX_PLAYERS char ],
	//p_PlayerSpectateUpdateTime 		[ MAX_PLAYERS ],

	// Airbrake
    Float: p_abLastPosition 		[ MAX_PLAYERS ] [ 3 ],
    p_abLastTick					[ MAX_PLAYERS ],
    p_abPosTick						[ MAX_PLAYERS ],
    p_abDetected					[ MAX_PLAYERS char ],
    p_abResetTimer 					[ MAX_PLAYERS ],

    // Pro-Aim
    p_silentAimbotLastCalled 		[ MAX_PLAYERS ],

    // Auto Cbug
	p_cbugKeyTicks					[ MAX_PLAYERS ],
	p_cbugFireTicks					[ MAX_PLAYERS ],
    p_cbugWarns 					[ MAX_PLAYERS char ],

    // Flying
    p_FlyHacksTick 					[ MAX_PLAYERS ],
    p_FlyHacksWarns 				[ MAX_PLAYERS char ],

    // Remote Jacking
	p_remoteJackData 				[ MAX_PLAYERS ] [ E_PLAYER_REMOTEJACK ]
;

// Functions (Player)
