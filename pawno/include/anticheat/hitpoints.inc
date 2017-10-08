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

#if !defined AC_HITPOINTS_INCLUDED
	#include 							< a_samp >

	#include 							< anticheat\global >
	#include 							< anticheat\player >

	// Forwards
	public OnPlayerTakePlayerDamage 	( playerid, issuerid, &Float: amount, weaponid, bodypart );
	public OnPlayerDeathEx 				( playerid, killerid, reason, Float: damage, bodypart );

	// Function (AC_UpdateKillerData)

	stock AC_UpdateDamageInformation( playerid, attackerid, weaponid )
	{
		p_LastTookDamage[ playerid ] = GetTickCount( );
		p_LastDamageIssuer[ playerid ] = attackerid;
		p_LastWeaponIssuer[ playerid ] = weaponid;
	}

	// Function (AC_GetPlayerHealth)

	stock Float: AC_GetPlayerHealth( playerid )
		return p_PlayerHealth[ playerid ] [ E_POINTS ];

	// Function (AddPlayerHealth)

	stock AC_AddPlayerHealth( playerid, Float:amount )
	{
		p_PlayerHealth[ playerid ] [ E_POINTS ] += amount;
		p_PlayerHealth[ playerid ] [ E_SYNCED ] = false;

	    return SetPlayerHealth( playerid, p_PlayerHealth[ playerid ] [ E_POINTS ] );
	}

	// Function Hook (SetPlayerHealth)

	stock AC_SetPlayerHealth( playerid, Float:amount )
	{
		p_PlayerHealth[ playerid ] [ E_POINTS ] = amount;
		p_PlayerHealth[ playerid ] [ E_SYNCED ] = false;

		if( amount <= 0.0 && p_acSpawned{ playerid } )
		{
			if( ( GetTickCount( ) - p_LastTookDamage[ playerid ] ) > 2500 )
				p_LastDamageIssuer[ playerid ] = INVALID_PLAYER_ID, p_LastWeaponIssuer[ playerid ] = 47;

			p_acSpawned{ playerid } = false; // They're dead!
			OnPlayerDeathEx( playerid, p_LastDamageIssuer[ playerid ], p_LastWeaponIssuer[ playerid ], 3.3, 3 );
		}

	    return SetPlayerHealth( playerid, amount );
	}

	#if defined _ALS_SetPlayerHealth
	    #undef SetPlayerHealth
	#else
	    #define _ALS_SetPlayerHealth
	#endif
	#define SetPlayerHealth AC_SetPlayerHealth

	// Function Hook (SetPlayerArmour)

	stock AC_SetPlayerArmour( playerid, Float:amount )
	{
		p_PlayerArmour[ playerid ] [ E_POINTS ] = amount;
		p_PlayerArmour[ playerid ] [ E_SYNCED ] = false;
	    return SetPlayerArmour( playerid, amount );
	}

	#if defined _ALS_SetPlayerArmour
	    #undef SetPlayerArmour
	#else
	    #define _ALS_SetPlayerArmour
	#endif
	#define SetPlayerArmour AC_SetPlayerArmour

	// Function Hook (SetPlayerTeam)

	stock AC_SetPlayerTeam( playerid, teamid )
	{
		if( teamid != AC_DEFAULT_TEAM )
			printf("[ACWarning] You cannot use SetPlayerTeam as you have hitpoint hack detection enabled (teamid %d, default %d).", teamid, AC_DEFAULT_TEAM );

	    return SetPlayerTeam( playerid, AC_DEFAULT_TEAM );
	}

	#if defined _ALS_SetPlayerTeam
	    #undef SetPlayerTeam
	#else
	    #define _ALS_SetPlayerArmour
	#endif
	#define SetPlayerTeam AC_SetPlayerTeam

	// Functions (Player)
	stock vCheckForHealthHacks( playerid, iTicks )
	{
		new
			Float: currentHealth,
			Float: currentArmour
		;
		GetPlayerHealth( playerid, currentHealth );
		GetPlayerArmour( playerid, currentArmour );

		// Lag Calculations
		new
			Float: fHitDamage = p_LastDamageIssued[ playerid ],
			Float: fArmourDamage,
			Float: fHealthDamage
		;

		if( fHitDamage > currentArmour ) {
			fArmourDamage = currentArmour;
			fHealthDamage = fHitDamage - currentArmour;
		}
		else fArmourDamage = fHitDamage;

		// Begin Health Hack Detection
		if( iTicks > p_PlayerHealth[ playerid ] [ E_UPDATE_TIME ] )
		{
			new currentHealthInt 	= floatround( currentHealth, floatround_floor );
			new healthShouldBeInt 	= floatround( p_PlayerHealth[ playerid ] [ E_POINTS ], floatround_floor );

			if( currentHealthInt == healthShouldBeInt )
				p_PlayerHealth[ playerid ] [ E_SYNCED ] = true;

			if( !p_PlayerHealth[ playerid ] [ E_SYNCED ] )
			{
				if( currentHealthInt > healthShouldBeInt )
				{
					switch( p_PlayerHealth[ playerid ] [ E_UPDATE_FAIL ]++ )
					{
						case 0 .. 9: SetPlayerHealth( playerid, p_PlayerHealth[ playerid ] [ E_POINTS ] );
						case 10: SendClientMessage( playerid, 0xa9c4e4ff, "You have been kicked as you are desynced from the server. Please relog!" ), KickPlayerTimed( playerid ), printf("[health] Player %d was desynced thus kicked.", playerid);
					}
				}
			}
			else
			{
				p_PlayerHealth[ playerid ] [ E_UPDATE_FAIL ] = 0;

				if( healthShouldBeInt > currentHealthInt )
					p_PlayerHealth[ playerid ] [ E_POINTS ] = currentHealth;

				if( currentHealthInt > healthShouldBeInt && currentHealthInt <= 255 && currentHealthInt > 0 )
	            	SetPlayerHealth( playerid, p_PlayerHealth[ playerid ] [ E_POINTS ] );

				currentHealthInt = floatround( currentHealth, floatround_floor );
				healthShouldBeInt = floatround( p_PlayerHealth[ playerid ] [ E_POINTS ], floatround_floor );

				new dmgOne = floatround( currentHealthInt - fHealthDamage, floatround_floor );
				new dmgTwo = floatround( currentHealthInt - fHealthDamage, floatround_ceil );

	            if( !( currentHealthInt == healthShouldBeInt || dmgOne == healthShouldBeInt || dmgTwo == healthShouldBeInt ) )
	            {
	            	SetPlayerHealth( playerid, p_PlayerHealth[ playerid ] [ E_POINTS ] );
					//printf("[health][%d] %d seems to health hack (server health: %d and client health: %d, health dmg: %f, armour dmg: %f).", playerid, playerid, healthShouldBeInt, currentHealthInt, fHealthDamage, fArmourDamage );
	            }
			}
			p_PlayerHealth[ playerid ] [ E_UPDATE_TIME ] = iTicks + 1000;
		}

		// Begin Armour Hack Detection
		if( iTicks > p_PlayerArmour[ playerid ] [ E_UPDATE_TIME ] )
		{
			new currentArmourInt 	= floatround( currentArmour, floatround_floor );
			new ArmourShouldBeInt 	= floatround( p_PlayerArmour[ playerid ] [ E_POINTS ], floatround_floor );

			if( currentArmourInt == ArmourShouldBeInt )
				p_PlayerArmour[ playerid ] [ E_SYNCED ] = true;

			if( !p_PlayerArmour[ playerid ] [ E_SYNCED ] )
			{
				if( currentArmourInt > ArmourShouldBeInt )
				{
					switch( p_PlayerArmour[ playerid ] [ E_UPDATE_FAIL ]++ )
					{
						case 0 .. 9: SetPlayerArmour( playerid, p_PlayerArmour[ playerid ] [ E_POINTS ] );
						case 10: SendClientMessage( playerid, 0xa9c4e4ff, "You have been kicked as you are desynced from the server. Please relog!" ), KickPlayerTimed( playerid ), printf("[armour] Player %d was desynced thus kicked.", playerid);
					}
				}
			}
			else
			{
				p_PlayerArmour[ playerid ] [ E_UPDATE_FAIL ] = 0;

				if( ArmourShouldBeInt > currentArmourInt )
					p_PlayerArmour[ playerid ] [ E_POINTS ] = currentArmour;

				if( currentArmourInt > ArmourShouldBeInt && currentArmourInt <= 255 && currentArmourInt > 0 )
	            	SetPlayerArmour( playerid, p_PlayerArmour[ playerid ] [ E_POINTS ] );

				currentArmourInt = floatround( currentArmour, floatround_floor );
				ArmourShouldBeInt = floatround( p_PlayerArmour[ playerid ] [ E_POINTS ], floatround_floor );

				new dmgOne = floatround( currentArmourInt - fArmourDamage, floatround_floor );
				new dmgTwo = floatround( currentArmourInt - fArmourDamage, floatround_ceil );

	            if( !( currentArmourInt == ArmourShouldBeInt || dmgOne == ArmourShouldBeInt || dmgTwo == ArmourShouldBeInt ) )
	            {
	            	SetPlayerArmour( playerid, p_PlayerArmour[ playerid ] [ E_POINTS ] );
					//printf("[armour] %d seems to armour hack (server armour: %d and client armour: %d, health dmg: %f, armour dmg: %f).", playerid, ArmourShouldBeInt, currentArmourInt, fHealthDamage, fArmourDamage );
	            }
			}
			p_PlayerArmour[ playerid ] [ E_UPDATE_TIME ] = iTicks + 1000;
		}
	}

	/*
		@function 		ForcePlayerKill
		@description 	forces a kill on a player
		@return 		void
	*/
	stock ForcePlayerKill( playerid, killerid, weaponid )
	{
		SetPVarInt( playerid, "KillerID", killerid );
		SetPVarInt( playerid, "WeaponID", weaponid );
		SetPVarInt( playerid, "CustomKill", 1 );

		SetPlayerHealth( playerid, -1 );
	}

	#define AC_HITPOINTS_INCLUDED
#endif
