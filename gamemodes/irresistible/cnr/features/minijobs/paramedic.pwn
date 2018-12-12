/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\minijobs\paramedic.pwn
 * Purpose: a paramedic minijob where people can heal with spraycans or ambulance trucks
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
DEFINE_HOOK_REPLACEMENT 			( Damage, Dmg );

/* ** Variables ** */
/*static stock
	p_CureDealer                    [ MAX_PLAYERS ] = { INVALID_PLAYER_ID, ... },
	p_CureTick                      [ MAX_PLAYERS ],
	p_HealDealer					[ MAX_PLAYERS ] = { INVALID_PLAYER_ID, ... },
	p_HealTick						[ MAX_PLAYERS ],
	p_LastCuredTS 					[ MAX_PLAYERS ],
	p_LastHealedTS 					[ MAX_PLAYERS ]
;*/

/* ** Hooks ** */
#if defined AC_INCLUDED
hook OnPlayerTakePlayerDmg( playerid, issuerid, &Float: amount, weaponid, bodypart )
{
	// Heal player (paramedic)
	if ( weaponid == WEAPON_SPRAYCAN )
	{
		new
			Float: fHealth = AC_GetPlayerHealth( playerid );

		if ( fHealth < 100.0 ) {
	 		AC_AddPlayerHealth( playerid, amount );
		}
	 	return 0;
	}
	return 1;
}
#endif

hook OnPlayerUpdateEx( playerid )
{
	new
		iVehicle = GetPlayerVehicleID( playerid );

	if ( iVehicle )
	{
	    if ( GetPlayerState( playerid ) == PLAYER_STATE_PASSENGER )
	    {
	    	if ( GetVehicleModel( iVehicle ) == 416 )
	    	{
	    		new
	    			iDriver = GetVehicleDriver( iVehicle );

	    		if ( IsPlayerConnected( iDriver ) )
	    		{
    				new
    					Float: fHealth;

    				if ( GetPlayerHealth( playerid, fHealth ) && fHealth < 100.0 ) {
    			 		SetPlayerHealth( playerid, fHealth + 2.0 ), GivePlayerCash( iDriver, 10 );
    				}
	    		}
	    	}
	    }
	}
	return 1;
}

hook OnPlayerDriveVehicle( playerid, vehicleid )
{
	new
		modelid = GetVehicleModel( vehicleid );

	if ( modelid == 416 ) {
		ShowPlayerHelpDialog( playerid, 2500, "You will make money by ~g~healing~w~ passengers of the vehicle" );
	}
	return 1;
}

/*hook OnPlayerDisconnect( playerid, reason )
{
	p_HealDealer[ playerid ] = INVALID_PLAYER_ID;
	return 1;
}*/

/* ** Commands ** */
/*CMD:cure( playerid, params[ ] )
{
  	new
  		pID,
  		time = g_iTime
  	;

   	if ( p_Class[ playerid ] != CLASS_MEDIC ) return SendError( playerid, "This is restricted to medics only." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/cure [PLAYER_ID]" );
	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
	else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "This player is not connected." );
	else if ( playerid == pID ) return SendError( playerid, "You cannot offer to cure yourself." );
	else if ( GetPlayerCash( pID ) < 4875 ) return SendError( playerid, "This player doesn't have enough money to get a cure." );
 	else if ( GetDistanceBetweenPlayers( playerid, pID ) < 4.0 )
 	{
		if ( IsPlayerInAnyVehicle( pID ) ) return SendError( playerid, "This player is in a vehicle " );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot do this while you're inside a vehicle." );
		if ( p_LastCuredTS[ playerid ] > time ) return SendError( playerid, "You must wait another %d seconds before curing somebody.", p_LastCuredTS[ playerid ] - time );
 		SendClientMessageFormatted( pID, -1, ""COL_ORANGE"[DISEASE CURE]{FFFFFF} %s(%d) wishes to cure you for $4,875. "COL_ORANGE"/acceptcure{FFFFFF} to accept the deal.", ReturnPlayerName( playerid ), playerid );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[DISEASE CURE]{FFFFFF} You have offered %s(%d) a cure for $4875.", ReturnPlayerName( pID ), pID );
   		p_CureDealer[ pID ] = playerid;
		p_CureTick[ pID ] = time + 120;
	}
	else SendError( playerid, "This player is not nearby." );
	return 1;
}

CMD:ac( playerid, params[ ] ) return cmd_acceptcure( playerid, params );
CMD:acceptcure( playerid, params[ ] )
{
	new
		time = g_iTime;

	if ( !IsPlayerConnected( p_CureDealer[ playerid ] ) ) return SendError( playerid, "Your dealer isn't connected anymore." );
	else if ( time > p_CureTick[ playerid ]  ) return p_CureDealer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "This deal has ended, each deal goes for 2 minutes maximum. You were late." );
	else if ( GetPlayerCash( playerid ) < 4875 ) return SendError( playerid, "You do not have enough money to get a cure." );
	else if ( p_Jailed{ playerid } ) return SendError( playerid, "You cannot buy cures while you're in jail." );
   	else if ( p_Class[ p_CureDealer[ playerid ] ] != CLASS_MEDIC ) return SendError( playerid, "The paramedic that offered you is no longer a paramedic." );
	else
	{
	    Beep( p_CureDealer[ playerid ] );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[DISEASE CURE]{FFFFFF} You have been cured from all diseases by %s(%d) for $4,875. ", ReturnPlayerName( p_CureDealer[ playerid ] ), p_CureDealer[ playerid ] );
		SendClientMessageFormatted( p_CureDealer[ playerid ], -1, ""COL_ORANGE"[DISEASE CURE]{FFFFFF} %s(%d) has paid and got himself cured.", ReturnPlayerName( playerid ), playerid );		p_InfectedHIV{ playerid } = false;
		GivePlayerCash( playerid, -4875 );
		GivePlayerCash( p_CureDealer[ playerid ], 4875 );
		GivePlayerScore( p_CureDealer[ playerid ], 2 );
		//GivePlayerExperience( p_CureDealer[ playerid ], E_PARAMEDIC );
		p_LastCuredTS[ p_CureDealer[ playerid ] ] = time + 15;
		p_CureDealer[ playerid ] = INVALID_PLAYER_ID;
	}
	return 1;
}

CMD:heal( playerid, params[ ] )
{
  	new
  		pID;

   	if ( p_Class[ playerid ] != CLASS_MEDIC ) return SendError( playerid, "This is restricted to medics only." );
	else if ( sscanf( params, "u", pID ) ) return SendUsage( playerid, "/heal [PLAYER_ID]" );
	else if ( p_Spectating{ playerid } ) return SendError( playerid, "You cannot use such commands while you're spectating." );
	else if ( !IsPlayerConnected( pID ) ) return SendError( playerid, "This player is not connected." );
	else if ( playerid == pID ) return SendError( playerid, "You cannot offer to heal yourself." );
	else if ( GetPlayerCash( pID ) < 750 ) return SendError( playerid, "This player doesn't have enough money to get a health refill." );
 	else if ( GetDistanceBetweenPlayers( playerid, pID ) < 4.0 )
 	{
		if ( IsPlayerInAnyVehicle( pID ) ) return SendError( playerid, "This player is in a vehicle " );
		if ( IsPlayerInAnyVehicle( playerid ) ) return SendError( playerid, "You cannot do this while you're inside a vehicle." );
		if ( p_LastHealedTS[ playerid ] > g_iTime ) return SendError( playerid, "You must wait another %d seconds before curing somebody.", p_LastHealedTS[ playerid ] - g_iTime );
 		SendClientMessageFormatted( pID, -1, ""COL_ORANGE"[HEALTH REFILL]{FFFFFF} %s(%d) wishes to heal you for $1,200. "COL_ORANGE"/acceptheal{FFFFFF} to accept the deal.", ReturnPlayerName( playerid ), playerid );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[HEALTH REFILL]{FFFFFF} You have offered %s(%d) a health refill for $1,200.", ReturnPlayerName( pID ), pID );
   		p_HealDealer[ pID ] = playerid;
		p_HealTick[ pID ] = g_iTime + 120;
	}
	else SendError( playerid, "This player is not nearby." );
	return 1;
}

CMD:ah( playerid, params[ ] ) return cmd_acceptheal( playerid, params );
CMD:acceptheal( playerid, params[ ] )
{
	new
		Float: fHealth;

	if ( !IsPlayerConnected( p_HealDealer[ playerid ] ) ) return SendError( playerid, "Your dealer isn't connected anymore." );
	else if ( g_iTime > p_HealTick[ playerid ]  ) return p_HealDealer[ playerid ] = INVALID_PLAYER_ID, SendError( playerid, "This deal has ended, each deal goes for 2 minutes maximum. You were late." );
	else if ( GetPlayerCash( playerid ) < 750 ) return SendError( playerid, "You do not have enough money to get a health refill." );
	else if ( p_Jailed{ playerid } ) return SendError( playerid, "You cannot buy heals while you're in jail." );
   	else if ( p_Class[ p_HealDealer[ playerid ] ] != CLASS_MEDIC ) return SendError( playerid, "The paramedic that offered you is no longer a paramedic." );
	else if ( IsPlayerInEvent( playerid ) ) return SendError( playerid, "You cannot use this command since you're in an event." );
	else if ( GetPlayerHealth( playerid, fHealth ) && fHealth >= 90.0 ) return SendError( playerid, "You need to have less than 90 percent of your health to be healed." );
	else
	{
	    Beep( p_HealDealer[ playerid ] );
		SendClientMessageFormatted( playerid, -1, ""COL_ORANGE"[HEALTH REFILL]{FFFFFF} You have patched up and healed by %s(%d) for $1,200. ", ReturnPlayerName( p_HealDealer[ playerid ] ), p_HealDealer[ playerid ] );
		SendClientMessageFormatted( p_HealDealer[ playerid ], -1, ""COL_ORANGE"[HEALTH REFILL]{FFFFFF} %s(%d) has paid and got his health refilled.", ReturnPlayerName( playerid ), playerid );
		SetPlayerHealth( playerid, 120.0 );
		GivePlayerCash( playerid, -1200 );
		GivePlayerCash( p_HealDealer[ playerid ], 1200 );
		GivePlayerScore( p_HealDealer[ playerid ], 2 );
		//GivePlayerExperience( p_HealDealer[ playerid ], E_PARAMEDIC );
		p_LastHealedTS[ p_HealDealer[ playerid ] ] = g_iTime + 15;
		p_HealDealer[ playerid ] = INVALID_PLAYER_ID;
	}
	return 1;
}*/
