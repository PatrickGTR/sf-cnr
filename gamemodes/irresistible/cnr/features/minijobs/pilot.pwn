/*
 * Irresistible Gaming (c) 2018
 * Developed by Steven Howard
 * Module: cnr\features\minijobs\pilot.pwn
 * Purpose: pilot minijob - cargo pickup and transport to another airport.
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define CARGO_PAYOUT_LOW			6000
#define CARGO_PAYOUT_HIGH			15000

#define RISK_EASY 					0
#define RISK_HARD 					1

/* ** Variables ** */

enum E_PILOT_DATA
{

};

enum E_CARGO_DATA
{
	E_VEHICLE, 				E_RISK, 			E_REWARD[ 2 ]
};

new
	Float: g_CargoStart				[ 3 ] = { 180.3708, 2502.9565, 16.4844 },
	g_CargoData 					[  ] [ E_CARGO_DATA ] =
	{
		// LOW RISK
		{ 511, RISK_EASY, { 7000, 12000 } },
		{ 593, RISK_EASY, { 7000, 12000 } },
		
		// HIGH RISK
		{ 460, RISK_HARD, { 10000, 15000 } },
		{ 512, RISK_HARD, { 10000, 15000 } }
	},
	Float: g_AirportLocations 		[  ][ 3 ] =
	{
		{ 1818.4377, -2493.9846, 13.5547 },
		{ 1477.4904, 1474.5323, 10.8203 },
		{ -1491.7163, 0.8244, 14.1484 }
	},
	CARGO_NAMES 					[ ][ 8 ] = {"Weed", "Meth", "Coke", "Weapons", "Clothes", "Drinks"},

	bool: p_hasPilotJob 			[ MAX_PLAYERS char ],
	p_PilotMapIcon 					[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_PilotCheckPoint 				[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_PilotCancelTimer 				[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_PilotPositionTimer 			[ MAX_PLAYERS ],
	Float: p_PilotDistance			[ MAX_PLAYERS ],
	p_PilotTimeElapsed 				[ MAX_PLAYERS ],
	p_PilotTaskID 					[ MAX_PLAYERS ],
	p_PilotAirportID 				[ MAX_PLAYERS ],
	p_PilotProgress 				[ MAX_PLAYERS ]
;

/* ** Hooks ** */
hook OnPlayerEnterDynRaceCP( playerid, checkpointid )
{
	if ( checkpointid == p_PilotCheckPoint[ playerid ] )
	{
		DestroyDynamicMapIcon( p_PilotMapIcon[ playerid ] );
		DestroyDynamicRaceCP ( p_PilotCheckPoint[ playerid ] );

		if ( p_PilotProgress[ playerid ] == 0)
		{
			static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;

			new 
				iAirport = random( sizeof( g_AirportLocations ));

			p_PilotCheckPoint[ playerid ] = CreateDynamicRaceCP(0, g_AirportLocations[ iAirport ] [ 0 ] , g_AirportLocations[ iAirport ] [ 1 ] , g_AirportLocations[ iAirport ] [ 2 ], 0.0, 0.0, 0.0, 10.0, -1, -1, playerid );
			p_PilotMapIcon[ playerid ] = CreateDynamicMapIconEx( g_AirportLocations[ iAirport ] [ 0 ] , g_AirportLocations[ iAirport ] [ 1 ] , g_AirportLocations[ iAirport ] [ 2 ] , 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );
			p_PilotAirportID[ playerid ] = iAirport;

			ShowPlayerHelpDialog( playerid, 7500, "Alright! You have found the cargo, deliever it to the location on your radar!");

			GivePlayerWantedLevel( playerid, ( g_CargoData[ p_PilotTaskID[ playerid ] ] [ E_RISK ] == RISK_EASY ? 6 : 12 ) );

			return ( p_PilotProgress[ playerid ] = 1), 1;
		}
		else if ( p_PilotProgress[ playerid ] == 1)
		{
			//p_PilotDistance[ playerid ] = GetDistanceBetweenPoints(g_CargoStart[ 0 ], g_CargoStart[ 1 ], g_CargoStart[ 2 ], g_AirportLocations[ p_PilotAirportID[ playerid ] ] [ 0 ] , g_AirportLocations[ p_PilotAirportID[ playerid ] ] [ 1 ] , g_AirportLocations[ p_PilotAirportID[ playerid ] ] [ 2 ]);

			/*new
				iElapsed = g_iTime - p_PilotTimeElapsed[ playerid ],
				iTheoreticalFinish = floatround( p_PilotDistance[ playerid ] / 30.0 ) // distance / 25m/s (2000m / 25m/s)
			;

			// Check if it is really quick to finish
			if ( iElapsed < iTheoreticalFinish ) {
		   		SendServerMessage( playerid, "You've been kicked due to suspected teleport hacking (0xBC-%d-%d).", iTheoreticalFinish, iElapsed );
		    	KickPlayerTimed( playerid );
		    	return 1;
			}*/

			new 
				iCashEarned = RandomEx(CARGO_PAYOUT_LOW, CARGO_PAYOUT_HIGH);

			GivePlayerScore( playerid, 2 );
			GivePlayerCash( playerid, iCashEarned );
			
			ShowPlayerHelpDialog( playerid, 5000, "You have earned ~y~%s ~w~for exporting %s!", cash_format( iCashEarned ), CARGO_NAMES[ p_PilotTaskID[ playerid ] ] );

			p_PilotDistance			[ playerid ] = 0.0;
			p_PilotCancelTimer 		[ playerid ] = 0xFFFF;
			p_PilotCheckPoint		[ playerid ] = 0xFFFF;
			p_PilotMapIcon			[ playerid ] = 0xFFFF;
			p_PilotAirportID		[ playerid ] = -1;
			p_hasPilotJob			[ playerid ] = false;

			return ( p_PilotProgress[ playerid ] = 0), 1;
		}

		return 1;
	}

	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	new 
		iVehicle = GetPlayerVehicleID( playerid ),
		iModel = GetVehicleModel( iVehicle ),
		iState = GetPlayerState( playerid )
	;

	// check if the player has detached their trailer
	if ( iState == PLAYER_STATE_DRIVER && iVehicle && p_hasPilotJob{ playerid } && ! IsVehicleCargoPlane( iModel ) && p_PilotCancelTimer[ playerid ] == 0xFFFF ) {
 		cancelPlayerPilotWork( playerid, iVehicle, .ticks = 60 );
	}

	return 1;
}

hook OnPlayerStateChange( playerid, newstate, oldstate )
{
    if ( newstate != PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_DRIVER && p_hasPilotJob{ playerid } ) {
		cancelPlayerPilotWork( playerid, GetPlayerVehicleID( playerid ), .ticks = 0 );
    }
    else if ( newstate == PLAYER_STATE_DRIVER && IsPlayerInAnyVehicle(playerid) ) {
    	if ( IsVehicleCargoPlane( GetVehicleModel( GetPlayerVehicleID( playerid ) ) ) ) {
    		ShowPlayerHelpDialog( playerid, 3000, "You can begin a pilot job by typing ~g~~h~/pilot~n~~n~Mission Risk: %s", ( g_CargoData[ p_PilotTaskID[ playerid ] ] [ E_RISK ] == RISK_EASY ? ( "~y~Low Risk" ) : ( "~r~High Risk" ) ) );
    	}
    }
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
	StopPlayerPilotWork( playerid );
	return 1;
}

/* ** Functions ** */
stock StopPlayerPilotWork( playerid )
{
	DestroyDynamicMapIcon	( p_PilotMapIcon[ playerid ] );
	DestroyDynamicRaceCP 	( p_PilotCheckPoint[ playerid ] );

	KillTimer 				( p_PilotCancelTimer[ playerid ] );

	p_PilotDistance			[ playerid ] = 0.0;
	p_hasPilotJob			[ playerid ] = false;
	p_PilotCancelTimer 		[ playerid ] = 0xFFFF;
	p_PilotCheckPoint		[ playerid ] = 0xFFFF;
	p_PilotMapIcon			[ playerid ] = 0xFFFF;
	p_PilotAirportID		[ playerid ] = -1;
}

stock IsVehicleCargoPlane( modelid )
{
	for ( new i = 0; i < sizeof ( g_CargoData ); i ++ )
	{
		if ( g_CargoData[ i ] [ E_VEHICLE ] == modelid ) {
			return 1;
		}
	}
	return 0;
}

/* ** Commands ** */

CMD:pilot( playerid, params[ ] )
{
	new 
		iVehicle = GetPlayerVehicleID( playerid ),
		iModel = GetVehicleModel( iVehicle );

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "You must be an ordinary civilian to use this command." );
	else if ( strmatch( params, "STOP" ))
	{
		StopPlayerPilotWork( playerid );
		return SendServerMessage( playerid, "Your pilot mission has been stopped." );
	}
	else if ( !strmatch( params, "WORK" )) return SendUsage( playerid, "/pilot [WORK/STOP]" );
	else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You must be a driver of a vehicle to work." );
	else if ( !iModel ) return SendError( playerid, "You are not in any vehicle." );
	else
	{
		if ( IsVehicleCargoPlane( iModel ))
		{
			if ( !p_hasPilotJob{ playerid })
			{
				if ( p_WorkCooldown[ playerid ] > g_iTime )
					return SendError( playerid, "You must wait %d seconds before working again.", p_WorkCooldown[ playerid ] - g_iTime );

				static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;

				new 
					iItem = RandomEx(0, sizeof( g_CargoData ));

				p_WorkCooldown			[ playerid ] = g_iTime + 60;
				p_hasPilotJob 	  		{ playerid } = true;
				p_PilotTaskID 	  		[ playerid ] = iItem;
				p_PilotProgress   		[ playerid ] = 0;
				p_PilotTimeElapsed		[ playerid ] = g_iTime;
				p_PilotCheckPoint 		[ playerid ] = CreateDynamicRaceCP( 0, g_CargoStart[ 0 ], g_CargoStart[ 1 ], g_CargoStart[ 2 ], 0.0, 0.0, 0.0, 10.0, -1, -1, playerid );
				p_PilotMapIcon			[ playerid ] = CreateDynamicMapIconEx( g_CargoStart[ 0 ], g_CargoStart[ 1 ], g_CargoStart[ 2 ], 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );
			
				ShowPlayerHelpDialog( playerid, 7500, "A ~g~~h~truck blip~w~~h~ has been shown on your radar. Go to where the truck blip is to pickup your cargo full of %s.", CARGO_NAMES[ iItem ] );
			}
			else SendError( playerid, "You already have a pilot job started! Cancel it with "COL_GREY"/pilot stop"COL_WHITE"." );
		}
		else SendError( playerid, "There are currently no jobs for this particular vehicle." );
	}
	return 1;
}


function cancelPlayerPilotWork( playerid, vehicleid, ticks )
{
	if (GetPlayerVehicleID( playerid ) == vehicleid && ticks )
		return KillTimer( p_PilotCancelTimer[ playerid ] ), p_PilotCancelTimer[ playerid ] = 0xFFFF;

	if ( ticks < 1 || !IsPlayerConnected( playerid ) || !IsPlayerSpawned( playerid ) )
	{
		StopPlayerPilotWork( playerid );
		SendServerMessage( playerid, "Your pilot mission has been stopped." );
	}
	else
	{
		ShowPlayerHelpDialog( playerid, 1000, "You have %d seconds to get back inside your plane you were using.", ticks - 1 );
		p_PilotCancelTimer[ playerid ] = SetTimerEx( "cancelPlayerPilotWork", 980, false, "ddd", playerid, vehicleid, ticks - 1 );
	}

	return 1;
}