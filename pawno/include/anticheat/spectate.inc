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

stock AC_TogglePlayerSpectating( playerid, toggle )
{
	p_PlayerSpectateUpdateTime[ playerid ] = GetTickCount( ) + 1250;
    p_SpectatePermission{ playerid } = true;
    return TogglePlayerSpectating( playerid, toggle );
}

#if defined _ALS_TogglePlayerSpectating
    #undef TogglePlayerSpectating
#else
    #define _ALS_TogglePlayerSpectating
#endif
#define TogglePlayerSpectating AC_TogglePlayerSpectating

// Function (bCheckForSpectatingHacks)

stock bCheckForSpectatingHacks( playerid, iState, iTicks )
{
	if( iTicks > p_PlayerSpectateUpdateTime[ playerid ] )
	{
		if( iState == PLAYER_STATE_SPECTATING && !p_SpectatePermission{ playerid } ) {
			CallLocalFunction( "OnPlayerCheatDetected", "dd", playerid, CHEAT_TYPE_SPECTATE );
			printf("[spectate] [%d] %d seems to spectate hack (state id %d, perm %d).", GetTickCount( ), playerid, iState, p_SpectatePermission{ playerid } );
		}
		p_PlayerSpectateUpdateTime[ playerid ] = iTicks + 1000;
	}
}