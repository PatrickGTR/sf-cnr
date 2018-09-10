/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc Pekaj
 * Module: cnr\features\minijobs\trucking.pwn
 * Purpose: trucking minijob
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define RISK_FACTOR_EASY 				( 0x10 )
#define RISK_FACTOR_HARD 				( 0x8 )

#define INVALID_TRUCKING_ROUTE 			( 0xFF )

/* ** Variables ** */
enum E_TRUCKING_DATA
{
	E_NAME[ 32 ],				E_CITY,
	Float: E_X,					Float: E_Y,					Float: E_Z
};

enum E_TRAILER_DATA
{
	E_NAME[ 17 ], 				E_BONUS, 					E_RISK
};

new
	g_aTruckingLocations[ ] [ E_TRUCKING_DATA ] =
	{
		// SF
		{ "Supa",					CITY_SF, -2492.6143, 768.56420, 34.5737 },
		{ "SF Hospital",			CITY_SF, -2698.4365, 622.14070, 13.8549 },
		{ "Golf Club",				CITY_SF, -2729.0786, -311.8507, 6.44090 },
		{ "SF Airport Fueling",		CITY_SF, -1127.2633, -150.5504, 13.5457 },
		{ "Herb Farm", 				CITY_SF, -1085.3650, -1644.566, 75.7690 },
		{ "Farm", 					CITY_SF, -376.94220, -1429.182, 25.1285 },
		{ "FleischBerg Beer",		CITY_SF, -172.67190, -233.8773, 0.83140 },
		{ "Chemical Plant",			CITY_SF, -1025.5406, -666.9636, 31.4098 },
		{ "SF Mine",				CITY_SF, -2755.9512, 1256.9657, 11.1721 },
		{ "Gas Station",			CITY_SF, -2405.2808, 982.05940, 44.6987 },

		// LV
		{ "LV SMALL Town",			CITY_LV, -796.19470, 1491.5441, 21.3110 },
		{ "Small LV Farm", 			CITY_LV, -379.07180, 2217.4116, 41.4955 },
		{ "Abandoned Airport LV", 	CITY_LV, 386.869300, 2539.4175, 15.9411 },
		{ "LV Truck Depot", 		CITY_LV, 1439.58200, 989.50120, 10.2221 },
		{ "LV Airport", 			CITY_LV, 1328.65330, 1613.9368, 10.2221 },
		{ "LV Construction Site", 	CITY_LV, 2422.11400, 1922.9708, 5.41740 },
		{ "LV Construction Site", 	CITY_LV, 2618.30830, 833.75980, 4.71790 },
		{ "LV Casino", 				CITY_LV, 1945.29390, 1347.5150, 8.51120 },
		{ "LV Train Station", 		CITY_LV, 1433.38670, 2606.7341, 10.0737 },
		//{ "LV Golf Course", 		CITY_LV, 1467.91980, 2775.1060, 10.0737 },
		{ "LV Army base",			CITY_LV, 314.20850, 1901.61900, 18.3275 },

		// LS
		{ "LS Farm", 				CITY_LS, 1933.2828, 171.656600, 36.6801 },
		{ "LS Farm", 				CITY_LS, 2372.1514, -647.70950, 126.906 },
		{ "LS Arena", 				CITY_LS, 2687.5447, -1682.9163, 8.84300 },
		{ "LS Trucking Depot", 		CITY_LS, 2488.4692, -2089.7585, 12.9487 },
		{ "LS Military Depot", 		CITY_LS, 2760.9412, -2456.6716, 12.9522 },
		{ "LS Pier", 				CITY_LS, 369.90320, -2027.8804, 7.07380 },
		{ "LS Airport", 			CITY_LS, 1930.5016, -2396.6973, 14.2341 },
		{ "LS Town Hall", 			CITY_LS, 1306.2109, -2056.8953, 58.1423 },
		{ "LS Farm", 				CITY_LS, 1557.1737, 24.4480000, 24.8366 },
		{ "LS Depot", 				CITY_LS, 2538.0132, -2228.3872, 14.0296 },

		// Assorted
		{ "Desert town",			CITY_DESERTS, -1495.147, 2614.85550, 56.3716 },
		{ "Farm",					CITY_DESERTS, -1480.387, 1949.57060, 49.6636 },
		{ "Hard Desert Town",		CITY_DESERTS, -788.0822, 2415.39090, 157.722 },
		{ "Desert Town",			CITY_DESERTS, -824.9703, 2728.89160, 46.2619 },
		{ "Small Town",				CITY_DESERTS, -1648.912, 2475.92090, 87.6510 },
		{ "Ganja Farm",				CITY_DESERTS, -1116.771, -1115.2540, 128.952 },
		{ "Farm",					CITY_COUNTRY, -367.4244, -1048.4260, 60.0209 }
	},

	g_aTrailerData[ 3 ] [ 8 ] [ E_TRAILER_DATA ] =
	{
		{
			{ "Methylamine", 		5000, 	RISK_FACTOR_HARD },
			{ "Mustard Gas", 		4000, 	RISK_FACTOR_HARD },
			{ "Ethylamine", 		2000, 	RISK_FACTOR_HARD },
			{ "Safrole", 			1000, 	RISK_FACTOR_HARD },

			{ "Crude Oil", 			2000,	RISK_FACTOR_EASY },
			{ "Natural Gas", 		1500,	RISK_FACTOR_EASY },
			{ "Unleaded Gas", 		1250,	RISK_FACTOR_EASY },
			{ "Heating Oil", 		750,	RISK_FACTOR_EASY }
		},

		{
			{ "Pseudoephedrine", 	5000, 	RISK_FACTOR_HARD },
			{ "Coca Plant", 		4000, 	RISK_FACTOR_HARD },
			{ "Kush", 				2000, 	RISK_FACTOR_HARD },
			{ "Opium", 				1000, 	RISK_FACTOR_HARD },

			{ "Soybeans", 			2000, 	RISK_FACTOR_EASY },
			{ "Wheat", 				1500, 	RISK_FACTOR_EASY },
			{ "Cocoa", 				1250, 	RISK_FACTOR_EASY },
			{ "Coffee", 			750, 	RISK_FACTOR_EASY }
		},

		{
			{ "Gold Bullion", 		2000, 	RISK_FACTOR_EASY },
			{ "Silver Bullion", 	1500, 	RISK_FACTOR_EASY },
			{ "Platinum Bullion",	1250, 	RISK_FACTOR_EASY },
			{ "Precious Metals", 	750, 	RISK_FACTOR_EASY },

			{ "Cocaine", 			5000, 	RISK_FACTOR_HARD },
			{ "Methamphetamine", 	4000, 	RISK_FACTOR_HARD },
			{ "Heroin", 			2000, 	RISK_FACTOR_HARD },
			{ "Various Pills", 		1000, 	RISK_FACTOR_HARD }
		}
	},

	bool: p_hasTruckingJob			[ MAX_PLAYERS char ],
	p_TruckingTrailer 				[ MAX_PLAYERS char ],
	p_TruckingTrailerModel 			[ MAX_PLAYERS char ],
	Float: p_TruckingDistance 		[ MAX_PLAYERS ],
	p_TruckingTimeElapsed			[ MAX_PLAYERS ],
	p_TruckingRoute 				[ MAX_PLAYERS ] [ 2 char ],
	p_TruckingCheckPoint			[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_TruckingMapIcon 				[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_TruckingCancelTimer 			[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_TruckingPositionTimer 		[ MAX_PLAYERS ] = { 0xFFFF, ... },
	p_LastAttachedVehicle 			[ MAX_PLAYERS ] = { INVALID_VEHICLE_ID, ... }
;

/* ** Hooks ** */
hook OnPlayerEnterDynRaceCP( playerid, checkpointid )
{
	new
		player_vehicle = GetPlayerVehicleID( playerid );

	if ( checkpointid == p_TruckingCheckPoint[ playerid ] )
	{
		if ( ! IsTrailerAttachedToVehicle( player_vehicle ) )
			return SendError( playerid, "You cannot import/export anything without a trailer!" );

		DestroyDynamicMapIcon( p_TruckingMapIcon[ playerid ] );
		DestroyDynamicRaceCP ( p_TruckingCheckPoint[ playerid ] );
		KillTimer			 ( p_TruckingPositionTimer[ playerid ] );

		if ( g_aTrailerData[ p_TruckingTrailerModel{ playerid } ] [ p_TruckingTrailer{ playerid } ] [ E_RISK ] == RISK_FACTOR_HARD )
			GivePlayerWantedLevel( playerid, 6 );

		if ( p_TruckingRoute[ playerid ] { 0 } != INVALID_TRUCKING_ROUTE )
		{
			static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;
			p_TruckingPositionTimer[ playerid ] = SetTimerEx( "OnTruckPositionUpdate", 750, false, "dd", playerid, p_TruckingRoute[ playerid ] { 1 } );
  			TextDrawShowForPlayer( playerid, p_TruckingTD[ playerid ] );

			ShowPlayerHelpDialog( playerid, 7500, "Your trailer has been loaded with %s. ~g~~h~Follow the truck blip on your radar to meet the destination.", g_aTrailerData[ p_TruckingTrailerModel{ playerid } ] [ p_TruckingTrailer{ playerid } ] [ E_NAME ] );
			p_TruckingMapIcon	[ playerid ] = CreateDynamicMapIconEx( g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_X ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_Y ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_Z ], 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );
			p_TruckingCheckPoint[ playerid ] = CreateDynamicRaceCP( 0, g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_X ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_Y ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_Z ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_X ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_Y ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_Z ], 10.0, -1, -1, playerid );
			return ( p_TruckingRoute[ playerid ] { 0 } = INVALID_TRUCKING_ROUTE ), 1;
		}

		else if ( p_TruckingRoute[ playerid ] { 1 } != INVALID_TRUCKING_ROUTE )
		{
			new
				iTimeElapsed = g_iTime - p_TruckingTimeElapsed[ playerid ],
				iTheoreticalFinish = floatround( p_TruckingDistance[ playerid ] / 30.0 ) // distance / 25m/s (2000m / 25m/s)
			;

			// Check if it is really quick to finish
			if ( iTimeElapsed < iTheoreticalFinish ) {
		   		SendServerMessage( playerid, "You've been kicked due to suspected teleport hacking (0xBC-%d-%d).", iTheoreticalFinish, iTimeElapsed );
		    	KickPlayerTimed( playerid );
		    	return 1;
			}

			new
				iCashEarned = floatround( p_TruckingDistance[ playerid ] * 2.0 + g_aTrailerData[ p_TruckingTrailerModel{ playerid } ] [ p_TruckingTrailer{ playerid } ] [ E_BONUS ] );

			ach_HandleTruckingCouriers( playerid );
			TextDrawHideForPlayer( playerid, p_TruckingTD[ playerid ] );

			GivePlayerScore( playerid, 1 + floatround( p_TruckingDistance[ playerid ] / 1000.0 ) );
			GivePlayerCash( playerid, iCashEarned );

			p_TruckingDistance		[ playerid ] = 0.0;
			p_hasTruckingJob		{ playerid } = false;
			p_TruckingCheckPoint	[ playerid ] = 0xFFFF;
			p_TruckingMapIcon 		[ playerid ] = 0xFFFF;
			p_TruckingCancelTimer	[ playerid ] = 0xFFFF;

			//SetTimerEx( "RespawnVehicle", 3500, false, "d", GetVehicleTrailer( player_vehicle ) );
			DetachTrailerFromVehicle( player_vehicle );

			ShowPlayerHelpDialog( playerid, 7500, "You have earned ~y~~h~%s~w~~h~ for exporting %s!", cash_format( iCashEarned ), g_aTrailerData[ p_TruckingTrailerModel{ playerid } ] [ p_TruckingTrailer{ playerid } ] [ E_NAME ] );
        	return ( p_TruckingRoute[ playerid ] { 1 } = INVALID_TRUCKING_ROUTE ), 1;
		}
		return 1;
	}
	return 1;
}

hook OnPlayerUpdateEx( playerid )
{
	new player_vehicle = GetPlayerVehicleID( playerid );
	new player_state = GetPlayerState( playerid );

	// check if the player has detached their trailer
	if ( player_state == PLAYER_STATE_DRIVER && player_vehicle && p_hasTruckingJob{ playerid } && ! IsTrailerAttachedToVehicle( player_vehicle ) && p_TruckingCancelTimer[ playerid ] == 0xFFFF ) {
 		cancelPlayerTruckingCourier( playerid, player_vehicle, .ticks = 60 );
	}
	return 1;
}

hook OnPlayerStateChange( playerid, newstate, oldstate )
{
    if ( newstate != PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_DRIVER && p_hasTruckingJob{ playerid } ) {
		cancelPlayerTruckingCourier( playerid, GetPlayerVehicleID( playerid ), .ticks = 0 );
    }
    return 1;
}

hook OnPlayerDisconnect( playerid, reason )
{
	StopPlayerTruckingCourier( playerid );
	return 1;
}

hook OnTrailerUpdate( playerid, vehicleid )
{
	new
		iModel = GetVehicleModel( GetPlayerVehicleID( playerid ) );

	if ( p_LastAttachedVehicle[ playerid ] != vehicleid && iModel != 525 )
	{
		if ( !p_hasTruckingJob{ playerid } )
			ShowPlayerHelpDialog( playerid, 3000, "You can begin a trucking job by typing ~g~~h~/work" );
		else
			cancelPlayerTruckingCourier( playerid, GetPlayerVehicleID( playerid ), .ticks = 0 );

		p_LastAttachedVehicle[ playerid ] = vehicleid;
	}
	return 1;
}


/* ** Commands ** */
CMD:work( playerid, params[ ] )
{
	new
		szDifficulty[ 7 ],
		iVehicle = GetPlayerVehicleID( playerid ),
		iModel 	 = GetVehicleModel( iVehicle ),
		iTrailer = GetVehicleModel( GetVehicleTrailer( iVehicle ) )
	;

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "You must be an ordinary civilian to use this command." );
	else if ( sscanf( params, "S(NORMAL)[7]", szDifficulty ) ) return SendUsage( playerid, "/work [NORMAL/HARDER]" );
	else if ( strmatch( szDifficulty, "STOP" ) )
	{
		StopPlayerTruckingCourier( playerid );
		return SendServerMessage( playerid, "Your trucking mission has been stopped." );
	}
	else if ( !strmatch( szDifficulty, "NORMAL" ) && !strmatch( szDifficulty, "HARDER" ) ) return SendUsage( playerid, "/work [NORMAL/HARDER/STOP]" );
	else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You must be a driver of a vehicle to work." );
	else if ( !iModel ) return SendError( playerid, "You are not in any vehicle." );
	else
	{
		if ( iModel == 403 || iModel == 514 || iModel == 515 )
		{
			if ( !p_hasTruckingJob{ playerid } )
			{
				if ( !IsTrailerAttachedToVehicle( iVehicle ) )
					return SendError( playerid, "You can only begin to work only if you have a trailer attached to your vehicle." );

				if ( p_WorkCooldown[ playerid ] > g_iTime )
					return SendError( playerid, "You must wait %d seconds before working again.", p_WorkCooldown[ playerid ] - g_iTime );

				static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;
				DestroyDynamicMapIcon( p_TruckingMapIcon[ playerid ] );

				p_hasTruckingJob 		{ playerid } = true;
				p_WorkCooldown			[ playerid ] = g_iTime + 60;

				p_TruckingTrailerModel	{ playerid } = getTrailerType( iTrailer );
				p_TruckingTrailer 		{ playerid } = getRandomTrailerLoad( p_TruckingTrailerModel{ playerid }, strmatch( szDifficulty, "HARDER" ) ? RISK_FACTOR_HARD : RISK_FACTOR_EASY );

				p_TruckingRoute[ playerid ] { 0 } = getClosestTruckingRoute( playerid );

			random_route:
				p_TruckingRoute[ playerid ] { 1 } = random( sizeof( g_aTruckingLocations ) );

				if ( p_TruckingRoute[ playerid ] { 0 } == p_TruckingRoute[ playerid ] { 1 } )
					goto random_route;

				p_TruckingTimeElapsed[ playerid ] = g_iTime;
				p_TruckingDistance	[ playerid ] = GetDistanceBetweenPoints( g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 0 } ] [ E_X ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 0 } ] [ E_Y ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 0 } ] [ E_Z ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_X ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_Y ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_Z ] );
				p_TruckingMapIcon	[ playerid ] = CreateDynamicMapIconEx( g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 0 } ] [ E_X ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 0 } ] [ E_Y ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 0 } ] [ E_Z ], 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );
				p_TruckingCheckPoint[ playerid ] = CreateDynamicRaceCP( 0, g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 0 } ] [ E_X ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 0 } ] [ E_Y ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 0 } ] [ E_Z ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_X ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_Y ], g_aTruckingLocations[ p_TruckingRoute[ playerid ] { 1 } ] [ E_Z ], 10.0, -1, -1, playerid );

				p_TruckingPositionTimer[ playerid ] = SetTimerEx( "OnTruckPositionUpdate", 750, false, "dd", playerid, p_TruckingRoute[ playerid ] { 0 } );
	  			TextDrawShowForPlayer( playerid, p_TruckingTD[ playerid ] );

				ShowPlayerHelpDialog( playerid, 7500, "A ~g~~h~truck blip~w~~h~ has been shown on your radar. Go to where the truck blip is load your trailer with %s.", g_aTrailerData[ p_TruckingTrailerModel{ playerid } ] [ p_TruckingTrailer{ playerid } ] [ E_NAME ] );
			}
			else SendError( playerid, "You already have a trucking job started! Cancel it with "COL_GREY"/work stop"COL_WHITE"." );
		}
		else SendError( playerid, "There are currently no jobs for this particular vehicle." );
	}
	return 1;
}

/* ** Functions ** */
stock StopPlayerTruckingCourier( playerid )
{
	DestroyDynamicRaceCP	( p_TruckingCheckPoint[ playerid ] );
	DestroyDynamicMapIcon 	( p_TruckingMapIcon[ playerid ] );

	KillTimer 				( p_TruckingPositionTimer[ playerid ] );
	KillTimer 				( p_TruckingCancelTimer[ playerid ] );

	p_TruckingDistance		[ playerid ] = 0.0;
	p_hasTruckingJob		{ playerid } = false;
	p_TruckingCheckPoint	[ playerid ] = 0xFFFF;
	p_TruckingMapIcon 		[ playerid ] = 0xFFFF;
	p_TruckingCancelTimer	[ playerid ] = 0xFFFF;
	p_TruckingPositionTimer [ playerid ] = 0xFFFF;
	p_TruckingRoute 		[ playerid ] { 0 } = INVALID_TRUCKING_ROUTE;
	p_TruckingRoute 		[ playerid ] { 1 } = INVALID_TRUCKING_ROUTE;

	TextDrawHideForPlayer( playerid, p_TruckingTD[ playerid ] );
}

stock getRandomTrailerLoad( iModel, iRisk ) {

	new
		aRandom[ sizeof( g_aTrailerData[ ] ) ],
		iRandomIndex = -1
	;

	for( new i = 0; i < sizeof( g_aTrailerData[ ] ); i++ ) {
		if ( g_aTrailerData[ iModel ] [ i ] [ E_RISK ] == iRisk ) {
			aRandom[ ++iRandomIndex ] = i;
		}
	}

	return aRandom[ random( iRandomIndex + 1 ) ];
}

stock getClosestTruckingRoute( playerid, &Float: distance = FLOAT_INFINITY ) {
    new
    	iCurrent = INVALID_PLAYER_ID, Float: fTmp;

    for( new i = 0; i < sizeof( g_aTruckingLocations ); i++ )
    	if ( 0.0 < ( fTmp = GetDistanceFromPlayerSquared( playerid, g_aTruckingLocations[ i ] [ E_X ], g_aTruckingLocations[ i ] [ E_Y ], g_aTruckingLocations[ i ] [ E_Z ] ) ) < distance )
    		distance = fTmp, iCurrent = i;

    return iCurrent;
}

function OnTruckPositionUpdate( playerid, routeid )
{
	if ( !IsPlayerInAnyVehicle( playerid ) && !p_hasTruckingJob{ playerid } && ( p_TruckingRoute[ playerid ] { 0 } == 0 && p_TruckingRoute[ playerid ] { 1 } == 0 ) ) {
	  	TextDrawHideForPlayer( playerid, p_TruckingTD[ playerid ] );
		return ( p_TruckingPositionTimer[ playerid ] = 0xFFFF );
	}

	new
		Float: fDistance = GetPlayerDistanceFromPoint( playerid, g_aTruckingLocations[ routeid ] [ E_X ], g_aTruckingLocations[ routeid ] [ E_Y ], g_aTruckingLocations[ routeid ] [ E_Z ] );

	TextDrawSetString( p_TruckingTD[ playerid ], sprintf( "~b~Location:~w~ %s~n~~b~Distance:~w~ %0.2fm", g_aTruckingLocations[ routeid ] [ E_NAME ], fDistance ) );
	return ( p_TruckingPositionTimer[ playerid ] = SetTimerEx( "OnTruckPositionUpdate", 750, false, "dd", playerid, routeid ) );
}

stock getTrailerType( model )
{
	switch( model ) {
		case 584:
			return 0;
		case 450:
			return 1;
		case 435, 591:
			return 2;
	}
	return 0xF;
}

function cancelPlayerTruckingCourier( playerid, vehicleid, ticks )
{
	if ( IsTrailerAttachedToVehicle( vehicleid ) && ticks )
		return KillTimer( p_TruckingCancelTimer[ playerid ] ), p_TruckingCancelTimer[ playerid ] = 0xFFFF;

	if ( ticks < 1 || !IsPlayerConnected( playerid ) || !IsPlayerSpawned( playerid ) )
	{
		StopPlayerTruckingCourier( playerid );
		SendServerMessage( playerid, "Your trucking mission has been stopped." );
	}
	else
	{
		ShowPlayerHelpDialog( playerid, 1000, "You have %d seconds to attach back the trailer you were using.", ticks - 1 );
		p_TruckingCancelTimer[ playerid ] = SetTimerEx( "cancelPlayerTruckingCourier", 980, false, "ddd", playerid, vehicleid, ticks - 1 );
	}
	return 1;
}
