/*
	PROJECT		<>	SA:MP Anticheat Plug-in
	LICENSE		<>	See LICENSE in the top level directory.
	AUTHOR(S)	<>	Lorenc_ (zeelorenc@hotmail.com), Emmet_ (no email)
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

// Forwards

public AC_ResetABDetected( playerid );

// Function Hook (SetPlayerPos)

stock AC_SetPlayerPos( playerid, Float: x, Float: y, Float: z )
{
    p_abLastTick[ playerid ] = GetTickCount( ) + 3000;
    return SetPlayerPos( playerid, x, y, z );
}

#if defined _ALS_SetPlayerPos
    #undef SetPlayerPos
#else
    #define _ALS_SetPlayerPos
#endif
#define SetPlayerPos AC_SetPlayerPos

// Function Hook (SetPlayerPosFindZ)

stock AC_SetPlayerPosFindZ(playerid, Float:x, Float:y, Float:z)
{
    p_abLastTick[ playerid ] = GetTickCount( ) + 3000;
	return SetPlayerPosFindZ( playerid, x, y, z );
}

#if defined _ALS_SetPlayerPosFindZ
    #undef SetPlayerPosFindZ
#else
    #define _ALS_SetPlayerPosFindZ
#endif
#define SetPlayerPosFindZ AC_SetPlayerPosFindZ

// Functions

stock bCheckForAirbrake( playerid, iTicks, iState )
{
    if( iState == 0 || iState == 2 || iState == 3 || iState == 7 || iState == 9 )
		p_abLastTick[ playerid ] = iTicks + 1000;

    else if( !IsPlayerInAnyVehicle( playerid ) && GetPlayerSurfingVehicleID( playerid ) == INVALID_VEHICLE_ID && GetPlayerSurfingObjectID( playerid ) == INVALID_VEHICLE_ID ) // && !IsPlayerNPC( playerid )
    {
        new
            Float: iPacketLoss = NetStats_PacketLossPercent( playerid );

        if( iTicks > p_abLastTick[ playerid ] && iPacketLoss < 0.8 )
        {
            static
                Float: x, Float: y, Float: z,
                Float: distance
           	;

            GetPlayerPos( playerid, x, y, z );

            if( floatabs( p_abLastPosition[ playerid ] [ 2 ] - z ) < 1.0 )
            {
                distance = GetPlayerDistanceFromPoint( playerid, p_abLastPosition[ playerid ] [ 0 ], p_abLastPosition[ playerid ] [ 1 ], p_abLastPosition[ playerid ] [ 2 ] );
                if( floatabs( distance ) >= 75.0 && ( floatabs( p_abLastPosition[ playerid ] [ 1 ] - y ) >= 50.0 || floatabs( p_abLastPosition[ playerid ] [ 0 ] - x ) >= 50.0 ) )
                {
                    if( ++p_abDetected{ playerid } >= 3 )
						CallLocalFunction( "OnPlayerCheatDetected", "ddd", playerid, CHEAT_TYPE_AIRBRAKE, 0 );

                    if( p_abResetTimer[ playerid ] == -1 )
                        p_abResetTimer[ playerid ] = SetTimerEx( "AC_ResetABDetected", 60000, false, "d", playerid );
                }
            }
            p_abLastTick[ playerid ] = iTicks + 1000;
        }

        if( iTicks > p_abPosTick[ playerid ] )
        {
            p_abPosTick[ playerid ] = iTicks + 1000;
       		GetPlayerPos( playerid, p_abLastPosition[ playerid ] [ 0 ], p_abLastPosition[ playerid ] [ 1 ], p_abLastPosition[ playerid ] [ 2 ] );
        }
    }
    return 1;
}

public AC_ResetABDetected( playerid )
{
    p_abDetected{ playerid } = 0;
    p_abResetTimer[ playerid ] = -1;
}
