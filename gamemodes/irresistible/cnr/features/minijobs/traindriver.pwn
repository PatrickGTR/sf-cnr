/*
 * Irresistible Gaming (c) 2018
 * Developed by Steven Howard
 * Module: cnr/features/minijobs/traindriver.pwn
 * Purpose: traindriver minijob
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Marcos ** */
#define IsVehicleTrain(%0) 			(GetVehicleModel(%0) == 538)

/* ** Definitions ** */
#define INVALID_TRAIN_ROUTE 		( 0xFF ) // keep this as 0xFF since -1 will not work in a char array
#define LOADING_SPEED 				( 30 ) 	// in mph

/* ** Variables ** */
enum E_STATION_DATA
{
	E_NAME[ 32 ],
	Float: E_X, 				Float: E_Y, 				Float: E_Z
};

static stock
	g_StationData[ ] [ E_STATION_DATA ] =
	{
		{ "Prickle Pine LV",				1474.3666, 2634.2493, 10.8203 },
		{ "Cranberry Station SF", 			-1944.0211, 180.4831, 25.7109 },
		{ "Market LS", 						816.3867, -1370.4550, -1.6781 },
		{ "El Corona LS", 					1689.9775, -1955.7910, 13.5469 },
		{ "Linden Station LV", 				2866.7095, 1329.3573, 10.8203 }
	},

	bool: p_hasTrainJob 					[ MAX_PLAYERS char ],

	p_TrainMissions 						[ MAX_PLAYERS ],
	p_TrainMapIcon							[ MAX_PLAYERS ] = { -1, ... },
	p_TrainCheckPoint						[ MAX_PLAYERS ] = { -1, ... },
	p_TrainPositionTimer					[ MAX_PLAYERS ] = { -1, ... },
	p_TrainLoadTimer						[ MAX_PLAYERS ] = { -1, ... },
	p_TrainCancelTimer						[ MAX_PLAYERS ] = { -1, ... },

	p_TrainTimeElapsed 						[ MAX_PLAYERS ],
	Float: p_TrainDistance					[ MAX_PLAYERS ],
	p_TrainRoute			 				[ MAX_PLAYERS ] [ 2 char ]
;

/* ** Hooks ** */
hook OnScriptInit(  )
{
	AddStaticVehicleEx( 538, 1443.5094, 2636.3716, 10.8910, 270.9954, 1, 98, 800);
	AddStaticVehicleEx( 538, 1465.4567, 2632.7007, 10.7463, 269.1136, 1, 98, 800);
	AddStaticVehicleEx( 538, 785.0410, -1339.9872, -2.0049, 46.9541, 6, 0, 800);
	AddStaticVehicleEx( 538, 842.2191, -1397.2175, -2.0471, 227.3936, 6, 0, 800);
	AddStaticVehicleEx( 538, -1946.3875, 181.3526, 25.7186, 354.3933, 2, 2, 800);
}

hook OnPlayerDisconnect( playerid, reason )
{
	StopPlayerTrainWork( playerid );
	return 1;
}

#if defined AC_INCLUDED
hook OnPlayerDeathEx( playerid, killerid, reason, Float: damage, bodypart )
#else
hook OnPlayerDeath( playerid, killerid, reason )
#endif
{
	StopPlayerTrainWork( playerid );
	return 1;
}

hook OnPlayerStateChange( playerid, newstate, oldstate )
{
	new
		vehicleid = GetPlayerVehicleID( playerid );

	if ( newstate != PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_DRIVER && p_hasTrainJob{ playerid } ) {
		KillTimer( p_TrainCancelTimer[ playerid ] ); // just in-case
		cancelPlayerTrainWork( playerid, 15 );
    }

    else if ( newstate == PLAYER_STATE_DRIVER && oldstate != PLAYER_STATE_DRIVER && p_hasTrainJob{ playerid } && IsVehicleTrain( vehicleid ) ) {
    	KillTimer( p_TrainCancelTimer[ playerid ] );
    	p_TrainCancelTimer[ playerid ] = -1;
    }

    else if ( newstate == PLAYER_STATE_DRIVER && IsPlayerInAnyVehicle( playerid ) && !p_hasTrainJob{ playerid } && IsVehicleTrain( vehicleid ) ) {
    	ShowPlayerHelpDialog( playerid, 5000, "You can begin a train job by typing ~g~/train" );
    }
    return 1;
}

hook OnPlayerEnterDynRaceCP( playerid, checkpointid )
{
	if ( checkpointid == p_TrainCheckPoint[ playerid ] )
	{
		if ( Train_GetSpeed( GetPlayerVehicleID( playerid ) ) > LOADING_SPEED )
			return SendError( playerid, "Please slow down before %s your passengers!", p_TrainRoute[ playerid ] { 0 } != INVALID_TRAIN_ROUTE ? ( "loading" ) : ( "un-loading" ) ), 1;

		DestroyDynamicRaceCP	( p_TrainCheckPoint[ playerid ] );
		DestroyDynamicMapIcon 	( p_TrainMapIcon[ playerid ] );

		KillTimer 				( p_TrainPositionTimer[ playerid ] );

		if ( p_TrainRoute[ playerid ] { 0 } != INVALID_TRAIN_ROUTE )
		{
			static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;

			KillTimer( p_TrainPositionTimer[ playerid ] ); // just in-case
			p_TrainPositionTimer[ playerid ] = SetTimerEx( "OnTrainPositionUpdate", 750, false, "dd", playerid, p_TrainRoute[ playerid ] { 1 } );
	  		PlayerTextDrawShow( playerid, p_TruckingTD[ playerid ] );

	  		KillTimer( p_TrainLoadTimer[ playerid ] );
	  		p_TrainLoadTimer[ playerid ] = SetTimerEx( "OnTrainLoadPassengers", 5000, false, "d", playerid );

	  		TogglePlayerControllable( playerid, false );
	  		ShowPlayerHelpDialog( playerid, 5000, "Please wait while your passengers are getting inside your train!" );

	  		p_TrainMapIcon		[ playerid ] = CreateDynamicMapIconEx( g_StationData[ p_TrainRoute[ playerid ] { 1 } ] [ E_X ], g_StationData[ p_TrainRoute[ playerid ] { 1 } ] [ E_Y ], g_StationData[ p_TrainRoute[ playerid ] { 1 } ] [ E_Z ], 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );
			p_TrainCheckPoint	[ playerid ] = CreateDynamicRaceCP( 0, g_StationData[ p_TrainRoute[ playerid ] { 1 } ] [ E_X ], g_StationData[ p_TrainRoute[ playerid ] { 1 } ] [ E_Y ], g_StationData[ p_TrainRoute[ playerid ] { 1 } ] [ E_Z ], 15.0, 0.0, 0.0, 10.0, -1, -1, playerid );

			p_TrainRoute[ playerid ] { 0 } = INVALID_TRAIN_ROUTE;
			Streamer_Update( playerid );
			return 1;
		}

		else if ( p_TrainRoute[ playerid ] { 1 } != INVALID_TRAIN_ROUTE )
		{
			new
				iCashEarned = floatround( p_TrainDistance[ playerid ] * 1.4 );

			GivePlayerScore( playerid, 1 + floatround( p_TrainDistance[ playerid ] / 1000.0 ) );
			GivePlayerCash( playerid, iCashEarned );

			ach_HandleTrainMissions( playerid );

			ShowPlayerHelpDialog( playerid, 5000, "You have earned ~y~%s ~w~for transporting passengers!", cash_format( iCashEarned ) );
			StopPlayerTrainWork( playerid );

			p_TrainRoute[ playerid ] { 1 } = INVALID_TRAIN_ROUTE;
			return 1;
		}

		return 1;
	}

	return 1;
}

/* ** Functions ** */
stock Train_GetSpeed( vehicleid )
{
	new Float: speed_x, Float: speed_y, Float: speed_z, Float: iFinal, iSpeed,
		Float: x, Float: y, Float: z;

	GetVehiclePos( vehicleid, x, y, z );
	GetVehicleVelocity( vehicleid, speed_x, speed_y, speed_z );

	iFinal = floatsqroot( ( ( speed_x * speed_x ) + ( speed_y * speed_y ) ) + ( speed_z * speed_z ) ) * 136.666667;
	iSpeed = floatround( iFinal, floatround_round );
	return iSpeed;
}

stock StopPlayerTrainWork( playerid )
{
	DestroyDynamicRaceCP	( p_TrainCheckPoint[ playerid ] );
	DestroyDynamicMapIcon 	( p_TrainMapIcon[ playerid ] );
	KillTimer 				( p_TrainCancelTimer[ playerid ] );
	KillTimer 				( p_TrainPositionTimer[ playerid ] );
	p_TrainDistance			[ playerid ] = 0.0;
	p_hasTrainJob			{ playerid } = false;
	p_TrainCheckPoint		[ playerid ] = -1;
	p_TrainMapIcon 			[ playerid ] = -1;
	p_TrainCancelTimer		[ playerid ] = -1;
	p_TrainLoadTimer		[ playerid ] = -1;
	p_TrainPositionTimer 	[ playerid ] = -1;
	p_TrainRoute 			[ playerid ] { 0 } = INVALID_TRAIN_ROUTE;
	p_TrainRoute 			[ playerid ] { 1 } = INVALID_TRAIN_ROUTE;
	PlayerTextDrawHide( playerid, p_TruckingTD[ playerid ] );
	return 1;
}

function OnTrainLoadPassengers( playerid )
{
	if ( !IsPlayerConnected( playerid ) )
		return 0;

	if ( !IsPlayerInAnyVehicle( playerid ) )
		return 0;

	TogglePlayerControllable( playerid, true );

	ShowPlayerHelpDialog( playerid, 7500, "Great! All of your passengers are sitting comfortably!" );
	return KillTimer( p_TrainLoadTimer[ playerid ] ), p_TrainLoadTimer[ playerid ] = -1, 1;
}

function OnTrainPositionUpdate( playerid, routeid )
{
	if ( ! IsPlayerInAnyVehicle( playerid ) && ! p_hasTrainJob{ playerid } )  {
		return StopPlayerTrainWork( playerid );
	}

	new
		Float: fDistance = GetPlayerDistanceFromPoint( playerid, g_StationData[ routeid ][ E_X ] , g_StationData[ routeid ][ E_Y ] , g_StationData[ routeid ][ E_Z ] );

	PlayerTextDrawSetString( playerid, p_TruckingTD[ playerid ], sprintf( "~b~Location:~w~ %s~n~~b~Distance:~w~ %0.2fm", g_StationData[ routeid ] [ E_NAME ], fDistance ) );
	p_TrainPositionTimer[ playerid ] = SetTimerEx( "OnTrainPositionUpdate", 750, false, "dd", playerid, routeid );
	return 1;
}

function cancelPlayerTrainWork( playerid, ticks )
{
	if ( ticks < 1 || !IsPlayerConnected( playerid ) || !IsPlayerSpawned( playerid ) || ! p_hasTrainJob{ playerid } )
	{
		StopPlayerTrainWork( playerid );
		return SendServerMessage( playerid, "Your train mission has been stopped." );
	}
	else
	{
		ShowPlayerHelpDialog( playerid, 1000, "You have %d seconds to get back inside the train you were using.", ticks - 1 );
		p_TrainCancelTimer[ playerid ] = SetTimerEx( "cancelPlayerTrainWork", 980, false, "dd", playerid, ticks - 1 );
	}
	return 1;
}

/* ** Commands ** */
CMD:train( playerid, params[ ] )
{
	new
		iVehicle = GetPlayerVehicleID( playerid );

	if ( p_Class[ playerid ] != CLASS_CIVILIAN ) return SendError( playerid, "You must be an ordinary civilian to use this command." );
	else if ( GetPlayerState( playerid ) != PLAYER_STATE_DRIVER ) return SendError( playerid, "You must be a driver of a vehicle to work." );
	else if ( !iVehicle ) return SendError( playerid, "You are not in any vehicle." );
	else if ( strmatch( params, "stop" ))
	{
		StopPlayerTrainWork( playerid );
		return SendServerMessage( playerid, "Your train mission has been stopped." );
	}
	else if ( !strmatch( params, "stop" ) )
	{
		if ( IsVehicleTrain( iVehicle ) )
		{
			if ( ! p_hasTrainJob{ playerid } )
			{
				if ( p_WorkCooldown[ playerid ] > g_iTime )
					return SendError( playerid, "You must wait %d seconds before working again.", p_WorkCooldown[ playerid ] - g_iTime );

				static aPlayer[ 1 ]; aPlayer[ 0 ] = playerid;
				DestroyDynamicMapIcon( p_TrainMapIcon[ playerid ] );
				DestroyDynamicRaceCP( p_TrainCheckPoint[ playerid ] );

				p_hasTrainJob 			{ playerid } = true;
				p_WorkCooldown			[ playerid ] = g_iTime + 60;

				new
					valid_train_routes[ sizeof( g_StationData ) ] = { -1, ... }; // -1 means valid

				p_TrainRoute			[ playerid ] { 0 } = GetClosestTrainStation( playerid ); // get the closest to the player first

				valid_train_routes 		[ p_TrainRoute[ playerid ] { 0 } ] = p_TrainRoute[ playerid ] { 0 };

				// ensure second route is not the same as first route
				p_TrainRoute			[ playerid ] { 1 } = randomExcept( valid_train_routes, sizeof( valid_train_routes ), .available_element_value = -1 );

				p_TrainTimeElapsed		[ playerid ] = g_iTime;
				p_TrainDistance			[ playerid ] = GetDistanceBetweenPoints( g_StationData[ p_TrainRoute[ playerid ] { 0 } ] [ E_X ], g_StationData[ p_TrainRoute[ playerid ] { 0 } ] [ E_Y ], g_StationData[ p_TrainRoute[ playerid ] { 0 } ] [ E_Z ], g_StationData[ p_TrainRoute[ playerid ] { 1 } ] [ E_X ], g_StationData[ p_TrainRoute[ playerid ] { 1 } ] [ E_Y ], g_StationData[ p_TrainRoute[ playerid ] { 1 } ] [ E_Z ] );
				p_TrainMapIcon			[ playerid ] = CreateDynamicMapIconEx( g_StationData[ p_TrainRoute[ playerid ] { 0 } ] [ E_X ], g_StationData[ p_TrainRoute[ playerid ] { 0 } ] [ E_Y ], g_StationData[ p_TrainRoute[ playerid ] { 0 } ] [ E_Z ], 51, 0, MAPICON_GLOBAL, 6000.0, { -1 }, { -1 }, aPlayer );
				p_TrainCheckPoint		[ playerid ] = CreateDynamicRaceCP( 0, g_StationData[ p_TrainRoute[ playerid ] { 0 } ] [ E_X ], g_StationData[ p_TrainRoute[ playerid ] { 0 } ] [ E_Y ], g_StationData[ p_TrainRoute[ playerid ] { 0 } ] [ E_Z ], 0.0, 0.0, 0.0, 10.0, -1, -1, playerid );

				Streamer_Update( playerid );
				KillTimer( p_TrainPositionTimer[ playerid ] );
				p_TrainPositionTimer[ playerid ] = SetTimerEx( "OnTrainPositionUpdate", 750, false, "dd", playerid, p_TrainRoute[ playerid ] { 0 } );
	  			PlayerTextDrawShow( playerid, p_TruckingTD[ playerid ] );
			}
			else SendError( playerid, "You already have a train job started! Cancel it with "COL_GREY"/train stop"COL_WHITE"." );
		}
		else SendError( playerid, "There are currently no jobs for this particular vehicle." );

		return 1;
	}
	return 1;
}

stock GetClosestTrainStation( playerid, &Float: distance = FLOAT_INFINITY )
{
    new
    	iCurrent = -1, Float: fTmp;

	for ( new i = 0; i < sizeof( g_StationData ); i ++ )
	{
        if ( 0.0 < ( fTmp = GetPlayerDistanceFromPoint( playerid, g_StationData[ i ] [ E_X ], g_StationData[ i ] [ E_Y ], g_StationData[ i ] [ E_Z ] ) ) < distance )
        {
            distance = fTmp;
            iCurrent = i;
        }
    }
    return iCurrent;
}
