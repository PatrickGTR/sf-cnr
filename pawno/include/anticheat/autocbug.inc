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

#include 						< anticheat\global >
#include 						< anticheat\player >

// Definitions (Global)

#define AUTOCBUG_TICKS_DEAGLE   ( 500 ) // prev 600
#define AUTOCBUG_TICKS_SHOTGUN  ( 850 )
#define AUTOCBUG_TICKS_COUNTRY  ( 750 )
#define AUTOCBUG_TICKS_SNIPER   ( 750 )

// Functions (Player)

stock vAutoCbugKeyState( playerid, newkeys, oldkeys )
{
	if( !p_cbugKeyTicks[ playerid ] )
		p_cbugKeyTicks[ playerid ] = GetTickCount( ), p_cbugWarns{ playerid } = 0;

	if( ( ( ( newkeys & ( KEY_CROUCH ) ) == ( KEY_CROUCH ) ) || ( ( oldkeys & ( KEY_CROUCH ) ) == ( KEY_CROUCH ) ) ) )
		p_cbugKeyTicks[ playerid ] = GetTickCount( ), p_cbugWarns{ playerid } = 0;
}

stock vCheckForAutoCbug( playerid, weaponid )
{
	// Anti-Rapid Fire
	if( !p_cbugFireTicks[ playerid ] ) p_cbugFireTicks[ playerid ] = GetTickCount( );
	else
	{
		new
			iTicks = GetTickCount( ),
			iInterval = iTicks - p_cbugFireTicks[ playerid ],
			iKeyInterval = iTicks - p_cbugKeyTicks[ playerid ],
			iHardInterval = 1000
		;

		if( weaponid == WEAPON_DEAGLE || weaponid == WEAPON_SHOTGUN || weaponid == WEAPON_RIFLE || weaponid == WEAPON_SNIPER )
		{
			new
				iCompare = iKeyInterval - iInterval,
				Float: fOwnPacketLoss = NetStats_PacketLossPercent( playerid )
			;

	     	switch( weaponid )
            {
                case WEAPON_DEAGLE: 	iHardInterval = AUTOCBUG_TICKS_DEAGLE;
                case WEAPON_SHOTGUN: 	iHardInterval = AUTOCBUG_TICKS_SHOTGUN;
                case WEAPON_RIFLE: 		iHardInterval = AUTOCBUG_TICKS_COUNTRY;
                case WEAPON_SNIPER: 	iHardInterval = AUTOCBUG_TICKS_SNIPER;
            }

			if( iInterval < iHardInterval && iCompare > 1500 && fOwnPacketLoss < 0.8 ) {
				if( p_cbugWarns{ playerid }++ >= 2 ) {
					printf( "[autocbug detect] %d detected (wep %d, interval %d, compare %d, warns %d)", playerid, weaponid, iInterval, iCompare, p_cbugWarns{ playerid });
					CallLocalFunction( "OnPlayerCheatDetected", "ddd", playerid, CHEAT_TYPE_AUTOCBUG, 0 );
				}
			}
		}
		p_cbugFireTicks[ playerid ] = iTicks;
	}
}
