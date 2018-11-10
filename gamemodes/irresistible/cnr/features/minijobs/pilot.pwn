/*
 * Irresistible Gaming (c) 2018
 * Developed by Steven Howard
 * Module: cnr\features\minijobs\pilot.pwn
 * Purpose: pilot minijob - cargo pickup and transport to another airport.
 */

/*

sql structure:

	ALTER TABLE `users` ADD `PILOT` INT(11) NULL DEFAULT '0' AFTER `TRUCKED`;

*/

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define PILOT_BONUS					( 4000.0 )
#define INVALID_PILOT_ROUTE 		( 0xFF )

/* ** Variables ** */

enum E_PILOT_DATA
{
	E_NAME[ 32 ],
	Float: E_X,				Float: E_Y,				Float: E_Z,
};

enum E_AIRPORT_DATA
{
	E_NAME[ 32 ],
	Float: E_X,				Float: E_Y,				Float: E_Z,
};

static stock
	g_DropOffLocations[ ] [ E_PILOT_DATA ] =
	{
		// SF
		{ "SF City Hall", 					-2706.2783, 376.4467, 4.9684 },
		{ "Whetstone Farm", 				-1442.2671, -1492.7599, 101.7578 },
		{ "Militia Ship", 					-2396.2244, 1543.2428, 31.8594 },

		// LV
		{ "Greenglass College",			 	1087.6841, 1073.0309, 10.8382 },
		{ "LV Baseball Ground", 			1355.2606, 2156.7888, 11.0156 },
		{ "The Visage", 					1965.2771, 1915.5419, 130.9375},
		{ "Spinybed", 						2400.8699, 2777.5608, 17.3643 },

		// LS
		{ "Santa Maria Beach",				369.9119, -2022.7925, 7.6719 },
		{ "Pershing Square",				1480.7731, -1638.8020, 14.1484 },
		{ "Glen Park",						1970.1884, -1201.0854, 25.6119 },

		// Assorted
		{ "Red County",						1929.0541, 170.9540, 37.2813 },
		{ "Blueberry Acres",				-76.9925, 1.9632, 3.1172 },
		{ "Bayside",						-2465.4614, 2234.1575, 4.8042 }
	},
	g_AirportLocations[ ] [ E_AIRPORT_DATA ] =
	{
		{ "San Fierro Airport",				-1233.8186, -128.0793, 14.1484 },
		{ "San Fierro Airport",				-1340.1185, 152.5395, 14.1484 },

		{ "Las Venturas Airport", 			1477.1909, 1532.9949, 10.8125 },
		{ "Las Venturas Airport", 			1620.1753, 1531.3868, 10.8011 },

		{ "Los Santos Airport", 			1797.7118, -2493.8835, 13.5547 },
		{ "Los Santos Airport", 			1921.8281, -2252.9990, 13.5469 },

		{ "Abandoned Airstrip",				175.2288, 2504.6611, 16.4844 },
		{ "Abandoned Airstrip",				266.3593, 2535.8496, 16.8125 }
	},
	g_CargoName[  ][ 8 ] = 					{ "Wheat", "Weed", "Meth", "Coke", "Weapons", "Clothes", "Drinks" },

	bool: p_hasPilotJob 					[ MAX_PLAYERS char ],
	p_PilotMapIcon 							[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_PilotCheckPoint 						[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_PilotPositionTimer 					[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_PilotCancelTimer 						[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_PilotLoadTimer						[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_PilotCargo 							[ MAX_PLAYERS ],
	p_PilotDifficulty 						[ MAX_PLAYERS ],
	p_PilotVehicle 							[ MAX_PLAYERS ],
	p_PilotTimeElapsed 						[ MAX_PLAYERS ],
	Float: p_PilotDistance					[ MAX_PLAYERS ],
	p_PilotRoute			 				[ MAX_PLAYERS ] [ 2 char ]
;

/* ** Forwards ** */
forward Float: Pilot_GetPlaneModelBonus 	( vehicleid );

/* ** Hooks ** */
hook OnPlayerDisconnect( playerid, reason )
{
	StopPlayerPilotWork( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	StopPlayerPilotWork( playerid );
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	new player_vehicle = GetPlayerVehicleID( playerid );

	if ( GetPlayerState( playerid ) == PLAYER_STATE_DRIVER && player_vehicle && p_hasPilotJob{ playerid } && p_PilotVehicle[ playerid ] != player_vehicle && p_PilotCancelTimer[ playerid ] == 0xFFFF ) {
 		cancelPlayerPilotWork( playerid, player_vehicle, .ticks = 60 );
	}

	return 1;
}

hook OnPlayerStateChange( playerid, newstate, oldstate )
{
	if ( newstate != PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_DRIVER && p_hasPilotJob{ playerid } ) {
		cancelPlayerPilotWork( playerid, GetPlayerVehicleID( playerid ), .ticks = 0 );
    }

    else if ( newstate == PLAYER_STATE_DRIVER && oldstate != PLAYER_STATE_DRIVER && p_hasPilotJob{ playerid } ) {
    	KillTimer( p_PilotCancelTimer[ playerid ] );
    	p_PilotCancelTimer[ playerid ] = 0xFFFF;
    }

    else if ( newstate == PLAYER_STATE_DRIVER && IsPlayerInAnyVehicle( playerid ) && !p_hasPilotJob{ playerid }) {
    	if ( Pilot_IsExportableVehicle( GetPlayerVehicleID( playerid ) ) ) {
    		ShowPlayerHelpDialog( playerid, 3000, "You can begin a pilot job in this vehicle by typing ~g~~h~/pilot" );
    	}
    }
    return 1;
}

hook OnPlayerEnterDynRaceCP( playerid, checkpointid )
{
	if ( checkpointid == p_PilotCheckPoint[ playerid ] )
	{
		DestroyDynamicMapIcon( p_PilotMapIcon[ playerid ] );
		DestroyDynamicRaceCP ( p_PilotCheckPoint[ playerid ] );
		KillTimer			 ( p_PilotPositionTimer[ playerid ] );

		if ( p_PilotRoute[ playerid ] { 0 } != INVALID_PILOT_ROUTE )
		{
			static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;

			p_PilotPositionTimer[ playerid ] = SetTimerEx( "OnPilotPositionUpdate", 750, false, "dd", playerid, p_PilotRoute[ playerid ] { 1 } );
	  		PlayerTextDrawShow( playerid, p_TruckingTD[ playerid ] );

	  		KillTimer( p_PilotLoadTimer[ playerid ] );
	  		p_PilotLoadTimer		[ playerid ] = 0xFFFF;
	  		p_PilotLoadTimer		[ playerid ] = SetTimerEx( "OnPilotLoadCargo", 5000, false, "d", playerid );

	  		TogglePlayerControllable(playerid, false);

	  		if ( p_PilotDifficulty[ playerid ] == RISK_FACTOR_HARD)
	  			GivePlayerWantedLevel( playerid, 6 );

	  		ShowPlayerHelpDialog( playerid, 5000, "Please wait while your cargo is getting loaded into your vehicle!" );

	  		p_PilotMapIcon		[ playerid ] = CreateDynamicMapIconEx( g_DropOffLocations[ p_PilotRoute[ playerid ] { 1 } ] [ E_X ], g_DropOffLocations[ p_PilotRoute[ playerid ] { 1 } ] [ E_Y ], g_DropOffLocations[ p_PilotRoute[ playerid ] { 1 } ] [ E_Z ], 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );
			p_PilotCheckPoint	[ playerid ] = CreateDynamicRaceCP( 4, g_DropOffLocations[ p_PilotRoute[ playerid ] { 1 } ] [ E_X ], g_DropOffLocations[ p_PilotRoute[ playerid ] { 1 } ] [ E_Y ], g_DropOffLocations[ p_PilotRoute[ playerid ] { 1 } ] [ E_Z ] + 50.0, 15.0, 0.0, 0.0, 10.0, -1, -1, playerid );

			return ( p_PilotRoute[ playerid ] { 0 } = INVALID_PILOT_ROUTE ), 1;
		}

		else if ( p_PilotRoute[ playerid ] { 1 } != INVALID_PILOT_ROUTE )
		{
			new Float: stock_dividend_allocation = 0.25;
			new cash_earned = floatround( ( p_PilotDistance[ playerid ] + PILOT_BONUS ) * Pilot_GetPlaneModelBonus( p_PilotVehicle[ playerid ] ) * ( 1.0 - stock_dividend_allocation ) );

			if ( p_PilotDifficulty[ playerid ] != RISK_FACTOR_EASY ) {
				cash_earned *= 2;
				GivePlayerWantedLevel( playerid, 6 );
			}

			ach_HandlePilotMissions( playerid );

			GivePlayerScore( playerid, 1 + floatround( p_PilotDistance[ playerid ] / 1000.0 ) );
			StockMarket_UpdateEarnings( E_STOCK_AVIATION, cash_earned, stock_dividend_allocation );
			GivePlayerCash( playerid, cash_earned );

			ShowPlayerHelpDialog( playerid, 5000, "You have earned ~y~%s ~w~for exporting %s!", cash_format( cash_earned ), g_CargoName[ p_PilotCargo[ playerid ] ] );
			StopPlayerPilotWork( playerid );
			return 1;
		}

		return 1;
	}
	return 1;
}
/* ** Functions ** */
stock getClosestPilotRoute( playerid, &Float: distance = FLOAT_INFINITY )
{
	new
		iCurrent = INVALID_PLAYER_ID, Float:fTmp;

	for( new i = 0; i < sizeof( g_AirportLocations ); i++ )
		if ( 0.0 < ( fTmp = GetDistanceFromPlayerSquared( playerid, g_AirportLocations[ i ] [ E_X ], g_AirportLocations[ i ] [ E_Y ], g_AirportLocations[ i ] [ E_Z ] ) ) < distance )
    		distance = fTmp, iCurrent = i;

	return iCurrent;
}

stock StopPlayerPilotWork( playerid )
{
	DestroyDynamicRaceCP	( p_PilotCheckPoint[ playerid ] );
	DestroyDynamicMapIcon 	( p_PilotMapIcon[ playerid ] );

	KillTimer 				( p_PilotCancelTimer[ playerid ] );
	KillTimer 				( p_PilotPositionTimer[ playerid ] );

	p_PilotDifficulty 		[ playerid ] = -1;
	p_PilotDistance			[ playerid ] = 0.0;
	p_hasPilotJob			{ playerid } = false;
	p_PilotCheckPoint		[ playerid ] = 0xFFFF;
	p_PilotMapIcon 			[ playerid ] = 0xFFFF;
	p_PilotCancelTimer		[ playerid ] = 0xFFFF;
	p_PilotPositionTimer 	[ playerid ] = 0xFFFF;
	p_PilotRoute 			[ playerid ] { 0 } = INVALID_PILOT_ROUTE;
	p_PilotRoute 			[ playerid ] { 1 } = INVALID_PILOT_ROUTE;
	p_PilotCargo 			[ playerid ] = -1;
	p_PilotVehicle 			[ playerid ] = INVALID_VEHICLE_ID;

	PlayerTextDrawHide( playerid, p_TruckingTD[ playerid ] );
}

stock Pilot_IsExportableVehicle( vehicleid )
{
	new
		modelid = GetVehicleModel( vehicleid );

	// skimmer, beagle, cropduster, nevada, andromada, dodo, -shamal-
	return modelid == 460 || modelid == 511 || modelid == 512 || modelid == 553 || modelid == 592 || modelid == 593 || modelid == 519 || modelid == 417 || modelid == 447 || modelid == 469 || modelid == 487 || modelid == 563 || modelid == 548;
}

stock Float: Pilot_GetPlaneModelBonus( vehicleid )
{
	new modelid = GetVehicleModel( vehicleid );
	new Float: bonus_export = 1.0;

	switch ( modelid )
	{
		// helicopter
		case 417: bonus_export = 2.1;
		case 447, 469: bonus_export = 1.6;
		case 487: bonus_export = 1.2;
		case 563, 548: bonus_export = 1.75;

		// airplanes
		case 460: bonus_export = 1.25;
		case 511: bonus_export = 1.35;
		case 512: bonus_export = 1.1;
		case 553: bonus_export = 1.8;
		case 592: bonus_export = 1.4;
		case 519: bonus_export = 0.8;
	}
	return bonus_export;
}

function OnPilotPositionUpdate( playerid, routeid )
{
	if ( !IsPlayerInAnyVehicle( playerid ) && !p_hasPilotJob{ playerid } && ( p_PilotRoute[ playerid ] { 0 } == 0 && p_PilotRoute[ playerid ] { 1 } == 0 ) ) {
	  	PlayerTextDrawHide( playerid, p_TruckingTD[ playerid ] );
		return ( p_PilotPositionTimer[ playerid ] = 0xFFFF );
	}

	new
		Float: fDistance = 0.0;

	if ( routeid == p_PilotRoute[ playerid ] { 0 }) {
		fDistance = GetPlayerDistanceFromPoint( playerid, g_AirportLocations[ routeid ] [ E_X ], g_AirportLocations[ routeid ] [ E_Y ], g_AirportLocations[ routeid ] [ E_Z ] );
		PlayerTextDrawSetString( playerid, p_TruckingTD[ playerid ], sprintf( "~b~Location:~w~ %s~n~~b~Distance:~w~ %0.2fm", g_AirportLocations[ routeid ] [ E_NAME ], fDistance ) );
	}
	else if ( routeid == p_PilotRoute[ playerid ] { 1 }) {
		fDistance = GetPlayerDistanceFromPoint( playerid, g_DropOffLocations[ routeid ] [ E_X ], g_DropOffLocations[ routeid ] [ E_Y ], g_DropOffLocations[ routeid ] [ E_Z ] );
		PlayerTextDrawSetString( playerid, p_TruckingTD[ playerid ], sprintf( "~b~Location:~w~ %s~n~~b~Distance:~w~ %0.2fm", g_DropOffLocations[ routeid ] [ E_NAME ], fDistance ) );
	}

	return ( p_PilotPositionTimer[ playerid ] = SetTimerEx( "OnPilotPositionUpdate", 750, false, "dd", playerid, routeid ) );
}

function cancelPlayerPilotWork( playerid, vehicleid, ticks )
{
	if ( p_PilotVehicle[ playerid ] == vehicleid && ticks )
		return KillTimer( p_PilotCancelTimer[ playerid ] ), p_PilotCancelTimer[ playerid ] = 0xFFFF;

	if ( ticks < 1 || !IsPlayerConnected( playerid ) || !IsPlayerSpawned( playerid ) || ! p_hasPilotJob{ playerid } )
	{
		StopPlayerPilotWork( playerid );
		return SendServerMessage( playerid, "Your pilot mission has been stopped." );
	}
	else
	{
		ShowPlayerHelpDialog( playerid, 1000, "You have %d seconds to get back inside the plane you were using.", ticks - 1 );
		p_PilotCancelTimer[ playerid ] = SetTimerEx( "cancelPlayerPilotWork", 980, false, "ddd", playerid, vehicleid, ticks - 1 );
	}
	return 1;
}

function OnPilotLoadCargo( playerid )
{
	if (!IsPlayerConnected(playerid))
		return 0;

	if ( !IsPlayerInAnyVehicle( playerid ) )
		return 0;

	TogglePlayerControllable(playerid, true);

	ShowPlayerHelpDialog( playerid, 7500, "Great! The cargo full of %s has been loaded, deliver it to the drop off location on your radar!", g_CargoName[ p_PilotCargo[ playerid ] ]);

	return KillTimer( p_PilotLoadTimer[ playerid ] ), p_PilotLoadTimer[ playerid ] = 0xFFFF, 1;
}

/* ** Commands ** */
CMD:pilot( playerid, params[ ] )
{
	new
		szDifficulty[ 7 ],
		iVehicle = GetPlayerVehicleID( playerid );

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "You must be an ordinary civilian to use this command." );
	else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You must be a driver of a vehicle to work." );
	else if ( !iVehicle ) return SendError( playerid, "You are not in any vehicle." );
	else if ( sscanf( params, "s[7]", szDifficulty ) ) return SendUsage( playerid, "/pilot [NORMAL/HARD/STOP]" );
	else if ( strmatch( szDifficulty, "stop" ))
	{
		StopPlayerPilotWork( playerid );
		return SendServerMessage( playerid, "Your pilot mission has been stopped." );
	}
	else if ( strmatch( szDifficulty, "normal" ) || strmatch( szDifficulty, "hard" ))
	{
		if ( Pilot_IsExportableVehicle( iVehicle ) )
		{
			if ( ! p_hasPilotJob{ playerid } )
			{
				if ( p_WorkCooldown[ playerid ] > g_iTime )
					return SendError( playerid, "You must wait %d seconds before working again.", p_WorkCooldown[ playerid ] - g_iTime );

				static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;
				DestroyDynamicMapIcon( p_PilotMapIcon[ playerid ] );

				p_hasPilotJob 			{ playerid } = true;
				p_WorkCooldown			[ playerid ] = g_iTime + 60;
				p_PilotVehicle 			[ playerid ] = GetPlayerVehicleID( playerid );
				p_PilotDifficulty 		[ playerid ] = ( strmatch( szDifficulty, "hard" ) ? RISK_FACTOR_HARD : RISK_FACTOR_EASY );

				p_PilotCargo 			[ playerid ] = random( sizeof( g_CargoName ) );
				p_PilotRoute			[ playerid ] { 0 } = random ( sizeof ( g_AirportLocations ) );
				p_PilotRoute			[ playerid ] { 1 } = random ( sizeof( g_DropOffLocations ) );

				p_PilotTimeElapsed		[ playerid ] = g_iTime;
				p_PilotDistance			[ playerid ] = GetDistanceBetweenPoints( g_AirportLocations[ p_PilotRoute[ playerid ] { 0 } ] [ E_X ], g_AirportLocations[ p_PilotRoute[ playerid ] { 0 } ] [ E_Y ], g_AirportLocations[ p_PilotRoute[ playerid ] { 0 } ] [ E_Z ], g_DropOffLocations[ p_PilotRoute[ playerid ] { 1 } ] [ E_X ], g_DropOffLocations[ p_PilotRoute[ playerid ] { 1 } ] [ E_Y ], g_DropOffLocations[ p_PilotRoute[ playerid ] { 1 } ] [ E_Z ] );
				p_PilotMapIcon			[ playerid ] = CreateDynamicMapIconEx( g_AirportLocations[ p_PilotRoute[ playerid ] { 0 } ] [ E_X ], g_AirportLocations[ p_PilotRoute[ playerid ] { 0 } ] [ E_Y ], g_AirportLocations[ p_PilotRoute[ playerid ] { 0 } ] [ E_Z ], 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );
				p_PilotCheckPoint		[ playerid ] = CreateDynamicRaceCP( 0, g_AirportLocations[ p_PilotRoute[ playerid ] { 0 } ] [ E_X ], g_AirportLocations[ p_PilotRoute[ playerid ] { 0 } ] [ E_Y ], g_AirportLocations[ p_PilotRoute[ playerid ] { 0 } ] [ E_Z ], 0.0, 0.0, 0.0, 10.0, -1, -1, playerid );

				if( p_PilotDifficulty[ playerid ] == RISK_FACTOR_HARD ) { // give the player 6 wanted for starting
					GivePlayerWantedLevel( playerid, 6 );
				}

				p_PilotPositionTimer[ playerid ] = SetTimerEx( "OnPilotPositionUpdate", 750, false, "dd", playerid, p_PilotRoute[ playerid ] { 0 } );
	  			PlayerTextDrawShow( playerid, p_TruckingTD[ playerid ] );

				ShowPlayerHelpDialog( playerid, 7500, "A ~g~~h~truck blip~w~~h~ has been shown on your radar. Go to where the truck blip is to pickup your cargo full of %s.", g_CargoName[ p_PilotCargo[ playerid ] ] );
			}
			else SendError( playerid, "You already have a pilot job started! Cancel it with "COL_GREY"/pilot stop"COL_WHITE"." );
		}
		else SendError( playerid, "There are currently no jobs for this particular vehicle." );
	}
	return 1;
}
