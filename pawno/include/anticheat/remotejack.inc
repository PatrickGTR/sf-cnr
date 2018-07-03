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

// Function (bCheckPlayerRemoteJacking)

stock bCheckPlayerRemoteJacking( playerid )
{
    new iVehicle = GetPlayerVehicleID( playerid );

    if( !IsPlayerInAnyVehicle( playerid ) )
        GetPlayerPos( playerid, p_remoteJackData[ playerid ] [ E_LAST_X ], p_remoteJackData[ playerid ] [ E_LAST_Y ], p_remoteJackData[ playerid ] [ E_LAST_Z ] );

    if( ( iVehicle != p_remoteJackData[ playerid ] [ E_LAST_VEH ] ) && ( iVehicle != 0 ) && ( GetPlayerState( playerid ) == PLAYER_STATE_DRIVER ) )
    {
        new
            Float: fDistance = GetVehicleDistanceFromPoint( iVehicle, p_remoteJackData[ playerid ] [ E_LAST_X ], p_remoteJackData[ playerid ] [ E_LAST_Y ], p_remoteJackData[ playerid ] [ E_LAST_Z ] ),
            Float: fOffset = 10.0
        ;

        if( ( GetVehicleModel( iVehicle ) == 577 ) || ( GetVehicleModel( iVehicle ) == 592 )) fOffset = 25.0; // Andromanda | AT-400

        if( fDistance > fOffset )
			CallLocalFunction( "OnPlayerCheatDetected", "ddd", playerid, CHEAT_TYPE_REMOTE_JACK, 0 );

        GetPlayerPos( playerid, p_remoteJackData[ playerid ] [ E_LAST_X ], p_remoteJackData[ playerid ] [ E_LAST_Y ], p_remoteJackData[ playerid ] [ E_LAST_Z ] );
        p_remoteJackData[ playerid ] [ E_LAST_VEH ] = iVehicle;
    }
    return 1;
}
