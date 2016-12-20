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

#define ac_GetDistanceBetweenPoints(%0,%1,%2,%3,%4,%6) \
	(VectorSize(%0-%3,%1-%4,%2-%6))

// Callback Hook (OnPlayerWeaponShot)

stock vCheckForSilentAimbot( playerid, hittype, hitid )
{
    static
    	Float: fVictimX, Float: fVictimY, Float: fVictimZ,
		Float: fCameraX, Float: fCameraY, Float: fCameraZ,
		Float: fVectorX, Float: fVectorY, Float: fVectorZ,
        Float: fHitPosX, Float: fHitPosY, Float: fHitPosZ
   	;

    if( hittype == BULLET_HIT_TYPE_PLAYER && IsPlayerConnected( hitid ) && ! IsPlayerNPC( hitid ) )
    {
	   	GetPlayerPos( hitid, fVictimX, fVictimY, fVictimZ );
		GetPlayerCameraPos( playerid, fCameraX, fCameraY, fCameraZ );
		GetPlayerCameraFrontVector( playerid, fVectorX, fVectorY, fVectorZ );
	    GetPlayerLastShotVectors( playerid, fHitPosX, fHitPosY, fHitPosZ, fHitPosX, fHitPosY, fHitPosZ );

	    //printf("%f = %f, %f = %f, %f = %f\n", fX + fVictimX, fHitPosX, fY + fVictimY, fHitPosY, fZ + fVictimZ, fHitPosZ );

	    fCameraX += 4.0 * fVectorX;
	    fCameraY += 4.0 * fVectorY;
	    fCameraZ += 4.0 * fVectorZ;

	    new Float: fCamera = 	ac_GetDistanceBetweenPoints( fHitPosX, fHitPosY, fHitPosZ, fCameraX, fCameraY, fCameraZ );
	    new Float: fRadius = 	ac_GetDistanceBetweenPoints( fHitPosX, fHitPosY, fHitPosZ, fVictimX, fVictimY, fVictimZ );
	    new Float: fPlayerDis = GetPlayerDistanceFromPoint( playerid, fVictimX, fVictimY, fVictimZ );

        if( GetPlayerSurfingVehicleID( playerid ) == INVALID_VEHICLE_ID && GetPlayerSurfingVehicleID( hitid ) == INVALID_VEHICLE_ID && !IsPlayerInAnyVehicle( hitid ) )
        {
            new
				Float: fHitPacketLoss = NetStats_PacketLossPercent( hitid ),
				Float: fOwnPacketLoss = NetStats_PacketLossPercent( playerid ),
				iLastUpdateInterval   = GetTickCount( ) - p_acUpdateTime[ hitid ] // AFK Check
			;

		    if( fCamera < 1.20 && fPlayerDis > 4.0 && fPlayerDis < 300.0 && fRadius > 4.0 && fOwnPacketLoss < 0.8 && fHitPacketLoss < 0.8 && iLastUpdateInterval < 3000 ) {
		    	new
		    		iTicks = GetTickCount( );

		    	if( iTicks - p_silentAimbotLastCalled[ playerid ] <= 5000 ) {
		    		printf("[PRO-AIM] Detected %d - last %dms", playerid, iTicks - p_silentAimbotLastCalled[ playerid ]);
					CallLocalFunction( "OnPlayerCheatDetected", "dd", playerid, CHEAT_TYPE_PROAIM );
		    	}

				p_silentAimbotLastCalled[ playerid ] = iTicks;
		    }
	    }
    }
}
